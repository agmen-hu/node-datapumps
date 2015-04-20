Promise = require('bluebird')
Pump = require('./Pump')
Buffer = require('./Buffer')

module.exports = class Group extends Pump

  constructor: ->
    super()
    @_pumps = {}
    @_exposedBuffers = {}

  addPump: (name, pump = null) ->
    throw new Error 'Pump already exists' if @_pumps[name]?
    @_pumps[name] = pump ? new Pump
    pumpId = if @_id? then "#{@_id}/#{name}" else name
    @_pumps[name].id pumpId
    @_pumps[name].errorBuffer @_errorBuffer
    @_pumps[name]

  pump: (name) ->
    throw new Error "Pump #{name} does not exist" if !@_pumps[name]?
    @_pumps[name]

  pumps: ->
    @_pumps

  start: ->
    throw new Error 'Group already started' if @_state != Group.STOPPED
    @_state = Group.STARTED
    @_registerErrorBufferEvents()
    for name, pump of @_pumps
      pump.errorBuffer @_errorBuffer
      pump.debugMode @_debug
    @run()
      .then => @_endGroup()
    @

  _endGroup: ->
    @_state = Group.ENDED
    @emit 'end'

  _registerErrorBufferEvents: ->
    @_errorBuffer.on 'full', =>
      if @_state == Group.STARTED
        @pause()
          .then => @emit 'error'

  run: ->
    (result = @runPumps())
      .catch -> # The runpumps promise is only rejected when the error buffer is full and
                # the sub-group is stopped. All errors are in the errorbuffer now, so we can
                # safely discard this error
    result

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

  expose: (exposedName, bufferPath) ->
    throw new Error "Already exposed a buffer with name #{exposedName}" if @_exposedBuffers[exposedName]?
    @_exposedBuffers[exposedName] = @_getBufferByPath bufferPath

  _getBufferByPath: (bufferPath) ->
    [ pumpName, bufferNames... ] = bufferPath.split('/')
    bufferName = if bufferNames.length then bufferNames.join('/')  else 'output'
    @pump(pumpName).buffer bufferName

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

  pause: ->
    return if @_state == Group.PAUSED
    throw new Error 'Cannot .pause() a group that is not pumping' if @_state != Group.STARTED
    pausePromises = [ ]
    pausePromises.push pump.pause() for name, pump of @_pumps when pump.isStarted()
    Promise.all pausePromises
      .then => @_state = Group.PAUSED

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

  debugMode: (@_debug) ->
    throw new Error 'Cannot change debug mode after pump start' if @_state != Pump.STOPPED
    @
