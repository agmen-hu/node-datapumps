Promise = require('bluebird')
Tank = require('./Tank')

class Pump
  @STOPPED: 0
  @STARTED: 1
  @ENDED: 2

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
    @

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
    @_state = Pump.STARTED
    do @_pump
    @

  _pump: ->
    @suckData()
      .then (data) => @_process data
      .done => do @_pump

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
    throw new Error('Process method must be a function') if typeof fn != 'function'
    @_process = fn.bind @
    @

module.exports = Pump
