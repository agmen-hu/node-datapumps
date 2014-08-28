EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Buffer = require('./Buffer')

class Pump extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @PAUSED: 2
  @ENDED: 3

  constructor: () ->
    @_state = Pump.STOPPED
    @_from = null
    @_id = null
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
      @_from.on 'full', -> buffer.pause()
      @_from.on 'release', -> buffer.resume()
    else
      throw new Error 'Argument must be datapumps.Buffer or stream'

    @_sourceEnded = false
    @_from.on 'end', => do @sourceEnded

    @

  sourceEnded: ->
    @currentRead.cancel() if @currentRead
    @_sourceEnded = true

  buffers: (buffers = null) ->
    return @_buffers if buffers == null
    if @_state == Pump.STARTED
      throw new Error 'Cannot change output buffers after pumping has been started'
    @_buffers = buffers
    @

  buffer: (name = 'output') ->
    throw new Error("No such buffer: #{name}") if !@_buffers[name]
    @_buffers[name]

  to: (pump, bufferName) ->
    pump.from @buffer bufferName
    @

  start: ->
    throw new Error 'Source is not configured' if !@_from
    throw new Error 'Pump is already started' if @_state != Pump.STOPPED
    @_state = Pump.STARTED
    @_errorBuffer = new Buffer if !@_errorBuffer?
    for name, buffer of @_buffers
      buffer.on 'end', @_outputBufferEnded.bind @
    do @_pump
    @

  _outputBufferEnded: ->
    allEnded = true
    for name, buffer of @_buffers
      allEnded = false if !buffer.isEnded()
    return if !allEnded

    @_state = Pump.ENDED
    @emit 'end'

  _pump: ->
    return do @sealOutputBuffers if @_sourceEnded == true
    return if @_state == Pump.PAUSED

    (@currentRead = @_from.readAsync())
      .cancellable()
      .then (data) =>
        @currentRead = null
        @_process data, @
      .catch(Promise.CancellationError, ->)
      .catch (err) =>
        @_errorBuffer.write
          message: err
          pump: @_id
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
    throw new Error('Process must be a function') if typeof fn != 'function'
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

  pause: ->
    return if @_state == Pump.PAUSED
    throw new Error 'Cannot .pause() a pump that is not running' if @_state != Pump.STARTED
    @_state = Pump.PAUSED
    @

  resume: ->
    throw new Error 'Cannot .resume() a pump that is not paused' if @_state != Pump.PAUSED
    @_state = Pump.STARTED
    do @_pump
    @

  whenFinished: ->
    return new Promise (resolve) =>
      @on 'end', ->
        resolve()

module.exports = Pump
