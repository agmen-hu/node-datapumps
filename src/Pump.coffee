Promise = require('bluebird')
Tank = require('./Tank')

class Pump
  constructor: (options) ->
    @tanks
      output: new Tank

  from: (tank = null) ->
    return @_from if tank == null
    @_from = tank
    @

  tanks: (tanks = null) ->
    return @_tanks if tanks == null
    @_tanks = tanks
    @

  tank: (name = 'output') ->
    throw new Error("No such tank: #{name}") if !@_tanks[name]
    @_tanks[name]

  start: ->
    @suckData()
      .then (data) => @_process(data)
      .done => @start()

  suckData: ->
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
