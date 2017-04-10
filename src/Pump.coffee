EventEmitter = require('events').EventEmitter
Promise = require 'bluebird'
Buffer = require './Buffer'
PumpingFailedError = require './PumpingFailedError'
BufferDebugMixin = require './mixin/BufferDebugMixin'

module.exports = class Pump extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @PAUSED: 2
  @ENDED: 3
  @ABORTED: 4

  constructor: ->
    @_state = Pump.STOPPED
    @_from = null
    @_id = null
    @_errorBuffer = new Buffer
    @_debug = false
    @buffers
      output: new Buffer

  id: (id = null) ->
    return @_id if id == null
    @_id = id
    @

  from: (buffer = null) ->
    return @_from if buffer == null
    if @_state == Pump.STARTED
      throw new Error 'Cannot change source buffer after pumping has been started'
    if buffer instanceof Buffer
      @_from = buffer
    else if buffer instanceof Pump
      @_from = buffer.buffer()
    else if buffer instanceof require('stream')
      @_from = new Buffer
        size: 1000
      buffer.on 'data', (data) => @_from.write data
      buffer.on 'end', => @_from.seal()
      buffer.on 'error', (err) => @writeError err
      @_from.on 'full', -> buffer.pause()
      @_from.on 'release', -> buffer.resume()
    else if buffer instanceof Array
      @_from = new Buffer
        content: buffer.slice 0
        sealed: true
    else
      throw new Error 'Argument must be datapumps.Buffer or stream'

    @_from.on 'end', => do @sourceEnded
    @

  writeError: (err) ->
    return if @_errorBuffer.isFull()
    @_errorBuffer.write
      error: err
      pump: @_id
    @

  sourceEnded: ->
    @currentRead.cancel() if @currentRead

  buffers: (buffers = null) ->
    return @_buffers if buffers == null
    throw new Error 'Cannot change output buffers after pumping has been started' if @_state == Pump.STARTED
    @_buffers = buffers
    @

  buffer: (name = 'output', buffer = null) ->
    if buffer == null
      throw new Error("No such buffer: #{name}") if !@_buffers[name]
      @_buffers[name]
    else
      throw new Error 'Cannot change output buffers after pumping has been started' if @_state == Pump.STARTED
      throw new Error 'buffer must be a datapumps.Buffer' if !(buffer instanceof Buffer)
      @_buffers[name] = buffer
      @

  to: (pump, bufferName) ->
    pump.from @buffer bufferName
    @

  start: ->
    throw new Error 'Source is not configured' if !@_from
    throw new Error 'Pump is already started' if @_state != Pump.STOPPED
    console.log "#{(new Date()).toISOString() } [#{@_id ? '(root)'}] Pump started" if @_debug
    @_state = Pump.STARTED
    @_registerErrorBufferEvents()
    for name, buffer of @_buffers
      buffer.on 'end', @_outputBufferEnded.bind @
    do @_pump
    @

  _registerErrorBufferEvents: ->
    @_errorBuffer.on 'full', =>
      if @_state == Pump.STARTED
        @abort()
          .then => @emit 'error'

  abort: ->
    return if @_state == Pump.ABORTED
    throw new Error 'Cannot .abort() a pump that is not running' if @_state != Pump.STARTED
    @_state = Pump.ABORTED
    if @_processing?.isPending()
      @_processing.cancel()
        .catch (err) ->
    else
      Promise.resolve()

  _outputBufferEnded: ->
    allEnded = true
    for name, buffer of @_buffers
      allEnded = false if !buffer.isEnded()
    return if !allEnded

    @_state = Pump.ENDED
    console.log "#{(new Date()).toISOString() } [#{@_id ? '(root)'}] Pump ended" if @_debug
    @emit 'end'

  _pump: ->
    return @sealOutputBuffers() if @_from.isEnded()
    return if @_state == Pump.PAUSED or @_state == Pump.ABORTED

    (@currentRead = @_from.readAsync())
      .cancellable()
      .then (data) =>
        @currentRead = null
        @_processing = @_process data, @
        if not (@_processing?.then instanceof Function)
          @_processing = undefined
          throw new Error ".process() did not return a Promise"

        @_processing = Promise.resolve @_processing
        return @_processing.cancellable()
      .catch(Promise.CancellationError, ->)
      .catch (err) => @writeError err
      .done => do @_pump

  sealOutputBuffers: ->
    for name, buffer of @_buffers
      do buffer.seal if !buffer.isSealed()

  _process: (data) ->
    @copy data

  copy: (data, buffers = null) ->
    buffers = [ 'output' ] if !buffers?
    buffers = [ buffers ] if typeof buffers == 'string'
    throw new Error 'buffers must be an array of buffer names or a single buffers name' if !Array.isArray buffers

    if buffers.length == 1
      @buffer(buffers[0]).writeAsync data
    else
      Promise.all(@buffer(buffer).writeAsync data for buffer in buffers)

  process: (fn) ->
    throw new Error('.process() argument must be a Promise returning function ') if typeof fn != 'function'
    @_process = fn
    @

  mixin: (mixins) ->
    mixins = if Array.isArray mixins then mixins else [ mixins ]
    mixin @ for mixin in mixins
    @

  isStopped: ->
    @_state == Pump.STOPPED

  isStarted: ->
    @_state == Pump.STARTED

  isPaused: ->
    @_state == Pump.PAUSED

  isEnded: ->
    @_state == Pump.ENDED

  createBuffer: (options = {}) ->
    new Buffer options

  errorBuffer: (buffer = null) ->
    return @_errorBuffer if buffer == null
    @_errorBuffer = buffer
    @

  # returns a promise that resolves when the pump is paused
  pause: ->
    return if @_state == Pump.PAUSED
    throw new Error 'Cannot .pause() a pump that is not running' if @_state != Pump.STARTED
    if @_processing?.isPending()
      @_processing.then => @_state = Pump.PAUSED
    else
      @_state = Pump.PAUSED
      Promise.resolve()

  resume: ->
    throw new Error 'Cannot .resume() a pump that is not paused' if @_state != Pump.PAUSED
    @_state = Pump.STARTED
    do @_pump
    @

  whenFinished: ->
    return Promise.resolve() if @isEnded()

    new Promise (resolve, reject) =>
      @on 'end', -> resolve()
      @on 'error', -> reject new PumpingFailedError()

  logErrorsToConsole: ->
    @errorBuffer().on 'write', (errorRecord) =>
      name = errorRecord.pump ? '(root)'
      if @_debug
        console.log "Error in pump #{name}:"
        console.log errorRecord.error.stack ? errorRecord.error
      else
        console.log "Error in pump #{name}: #{errorRecord.error}"
    @

  logErrorsToLogger: (logger) ->
    @errorBuffer().on 'write', (errorRecord) =>
      name = errorRecord.pump ? '(root)'
      if @_debug
        logger.error "Error in pump #{name}:"
        logger.error errorRecord.error.stack ? errorRecord.error
      else
        logger.error "Error in pump #{name}: #{errorRecord.error}"
    @

  debug: ->
    @debugMode true
    @

  debugMode: (@_debug) ->
    throw new Error 'Cannot change debug mode after pump start' if @_state != Pump.STOPPED
    @mixin BufferDebugMixin if @_debug
    @

  run: ->
    @start().whenFinished()
