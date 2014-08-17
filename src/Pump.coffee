EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Buffer = require('./Buffer')

class Pump extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @PAUSED: 2
  @ENDED: 3

  constructor: (options) ->
    @_state = Pump.STOPPED
    @_from = null
    @buffers
      output: new Buffer

  from: (buffer = null) ->
    return @_from if buffer == null
    if @_state == Pump.STARTED
      throw new Error 'Cannot change source buffer after pumping has been started'
    if buffer instanceof Buffer
      @_from = buffer
    else if buffer instanceof require('stream').Readable
      @_from = new Buffer
        size: 1000
      buffer.on 'data', (data) => @_from.write data
      buffer.on 'end', => @_from.seal()
      @_from.on 'full', -> buffer.pause()
      @_from.on 'release', -> buffer.resume()
    else
      throw new Error 'Argument must be datapumps.Buffer or stream.Readable'

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
        @_process data
      .catch(Promise.CancellationError, ->)
      .catch (err) =>
        @_errorBuffer.write err
      .done => do @_pump

  sealOutputBuffers: ->
    for name, buffer of @_buffers
      do buffer.seal if !buffer.isSealed()

  _process: (data) ->
    @buffer().writeAsync data

  process: (fn) ->
    throw new Error('Process must be a function') if typeof fn != 'function'
    @_process = fn.bind @
    @

  mixin: (mixins) ->
    mixins = if Array.isArray mixins then mixins else [ mixins ]
    mixin @ for mixin in mixins
    @

  isEnded: ->
    @_state == Pump.ENDED

  createBuffer: (options = {}) ->
    new Buffer options

  errorBuffer: (buffer = null) ->
    return @_errorBuffer if buffer == null
    @_errorBuffer = buffer
    @

  pause: ->
    throw new Error 'Cannot .pause() a pump that is not running' if @_state != Pump.STARTED
    @_state = Pump.PAUSED
    @

  resume: ->
    throw new Error 'Cannot .resume() a pump that is not paused' if @_state != Pump.PAUSED
    @_state = Pump.STARTED
    do @_pump
    @

module.exports = Pump
