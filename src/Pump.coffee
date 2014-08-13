EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Buffer = require('./Buffer')

class Pump extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @SOURCE_ENDED: 2
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
    else
      @_from = new Buffer
        size: 1000
      buffer.on 'data', (data) => @_from.write data
      buffer.on 'end', => @_from.seal()
      @_from.on 'full', -> buffer.pause()
      @_from.on 'release', -> buffer.resume()

    @_from.on 'end', => do @sourceEnded

    @

  sourceEnded: ->
    @currentRead.cancel() if @currentRead
    @_state = Pump.SOURCE_ENDED

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
    @_state = Pump.STARTED if @_state == Pump.STOPPED
    do @_pump
    @

  _pump: ->
    return do @subscribeForOutputBufferEnds if @_state == Pump.SOURCE_ENDED

    (@currentRead = @_from.readAsync())
      .cancellable()
      .then (data) =>
        @currentRead = null
        @_process data
      .catch(Promise.CancellationError, ->)
      .done => do @_pump

  subscribeForOutputBufferEnds: ->
    for name, buffer of @_buffers
      buffer.on 'end', @outputBufferEnded.bind @
      do buffer.seal

  outputBufferEnded: ->
    for name, buffer of @_buffers
      return if !buffer.isEnded()
    @_state = Pump.ENDED
    @emit 'end'

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

module.exports = Pump
