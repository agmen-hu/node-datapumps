EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Tank = require('./Tank')

class Pump extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @SOURCE_ENDED: 2
  @ENDED: 3

  constructor: (options) ->
    @_state = Pump.STOPPED
    @_from = null
    @tanks
      output: new Tank

  from: (tank = null) ->
    return @_from if tank == null
    if @_state == Pump.STARTED
      throw new Error 'Cannot change source tank after pumping has been started'
    @_from = tank
    @_from.on 'end', => do @sourceEnded
    @

  sourceEnded: ->
    @_state = Pump.SOURCE_ENDED

  tanks: (tanks = null) ->
    return @_tanks if tanks == null
    if @_state == Pump.STARTED
      throw new Error 'Cannot change output tanks after pumping has been started'
    @_tanks = tanks
    @

  tank: (name = 'output') ->
    throw new Error("No such tank: #{name}") if !@_tanks[name]
    @_tanks[name]

  start: ->
    @_state = Pump.STARTED if @_state == Pump.STOPPED
    do @_pump
    @

  _pump: ->
    if @_state == Pump.SOURCE_ENDED
      do @subscribeForOutputTankEnds
      return

    @suckData()
      .then (data) => @_process data
      .done => do @_pump

  subscribeForOutputTankEnds: ->
    @_outputTankEnded = {}
    for name, tank of @_tanks
      @_outputTankEnded[name] = false
      tank.on 'end', =>
        @_outputTankEnded[name] = true
        for name, state of @_outputTankEnded
          return if state == false
        @emit 'end'

    for name, tank of @_tanks
      do tank.seal

  suckData: ->
    if !@_from
      throw new Error 'Source is not configured'

    if !@_from.isEmpty()
      Promise.resolve(@_from.release())
    else
      new Promise (resolve, reject) =>
        @_from.once 'fill', =>
          resolve(@_from.release())

  _process: (data) ->
    @tank().fillAsync data

  process: (fn) ->
    throw new Error('Process must be a function') if typeof fn != 'function'
    @_process = fn.bind @
    @

module.exports = Pump
