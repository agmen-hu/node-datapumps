EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Pump = require('./Pump')
Buffer = require('./Buffer')

class Group extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @PAUSED: 2
  @ENDED: 3

  constructor: ->
    @_pumps = {}
    @_exposedBuffers = {}
    @_state = Group.STOPPED
    @_errorBuffer = new Buffer
    @_id = null

  addPump: (name, pump = null) ->
    throw new Error 'Pump already exists' if @_pumps[name]?
    @_pumps[name] = pump ? new Pump
    @_pumps[name].on 'end', => @pumpEnded(name)
    pumpId = if @_id? then "#{@_id}/#{name}" else name
    @_pumps[name].id pumpId
    @_pumps[name]

  pumpEnded: (name) ->
    end = true
    for name, pump of @_pumps
      end = false if !pump.isEnded()
    return if !end

    @_state = Group.ENDED
    @emit 'end'

  pump: (name) ->
    throw new Error "Pump #{name} does not exist" if !@_pumps[name]?
    @_pumps[name]

  start: ->
    throw new Error 'Group already started' if @_state != Group.STOPPED
    @_state = Group.STARTED
    @_registerErrorBufferEvents()
    pump.errorBuffer @_errorBuffer for name, pump of @_pumps
    do @run
    @

  _registerErrorBufferEvents: ->
    @_errorBuffer.on 'full', =>
      do @pause
      @emit 'error'

  run: ->
    do @runPumps

  runPumps: (pumps = null) ->
    pumps = do @_getAllStoppedPumps if !pumps?
    pumps = [ pumps ] if typeof pumps == 'string'
    finishPromises = []
    for pumpName in pumps
      finishPromises.push @pump(pumpName).start().whenFinished()
    Promise.all finishPromises

  _getAllStoppedPumps: ->
    result = []
    for name, pump of @_pumps
      result.push name if pump.isStopped()
    result

  isStopped: ->
    @_state == Group.STOPPED

  isStarted: ->
    @_state == Group.STARTED

  isPaused: ->
    @_state == Group.PAUSED

  isEnded: ->
    @_state == Group.ENDED

  whenFinished: ->
    return new Promise (resolve, reject) =>
      @on 'end', ->
        resolve()
      @on 'error', ->
        reject 'Pumping failed. See .errorBuffer() contents for error messages'

  createBuffer: (options = {}) ->
    new Buffer options

  expose: (exposedName, bufferPath) ->
    throw new Error "Already exposed a buffer with name #{exposedName}" if @_exposedBuffers[exposedName]?
    @_exposedBuffers[exposedName] = @_getBufferByPath bufferPath

  _getBufferByPath: (bufferPath) ->
    items = bufferPath.split('/')
    throw new Error 'bufferPath format must be <pumpName>/<bufferName>' if items.length > 2
    [ pumpName, bufferName ] = items
    @pump(pumpName).buffer(bufferName ? 'output')

  buffer: (name = 'output') ->
    try
      result = @_exposedBuffers[name] ? @_getBufferByPath name
    catch

    throw new Error "No such buffer: #{name}" if !result
    result

  inputPump: (pumpName = null) ->
    return @_inputPump if !pumpName?
    @_inputPump = @pump(pumpName)
    @

  addInputPump: (name, pump = null) ->
    result = @addPump name, pump
    @inputPump name
    result

  from: (buffer = null) ->
    throw new Error 'Input pump is not set, use .inputPump to set it' if !@_inputPump?
    @_inputPump.from buffer
    @

  mixin: (mixins) ->
    throw new Error 'Input pump is not set, use .inputPump to set it' if !@_inputPump?
    @_inputPump.mixin mixins
    @

  process: ->
    throw new Error 'Cannot call .process() on a group: data in a group is transformed by its pumps.'

  errorBuffer: (buffer = null) ->
    return @_errorBuffer if buffer == null
    @_errorBuffer = buffer
    @

  pause: ->
    return if @_state == Group.PAUSED
    throw new Error 'Cannot .pause() a group that is not pumping' if @_state != Group.STARTED
    @_state = Group.PAUSED
    do pump.pause for name, pump of @_pumps when pump.isStarted()
    @

  resume: ->
    throw new Error 'Cannot .resume() a group that is not paused' if @_state != Group.PAUSED
    @_state = Group.STARTED
    do pump.resume for name, pump of @_pumps
    @

  id: (id = null) ->
    return @_id if id == null
    @_id = id
    pump.id "#{@_id}/#{name}" for name, pump of @_pumps
    @

module.exports = Group
