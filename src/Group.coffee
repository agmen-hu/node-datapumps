EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Pump = require('./Pump')
Buffer = require('./Buffer')

class Group extends EventEmitter
  @STOPPED: 0
  @STARTED: 1
  @ENDED: 2

  constructor: ->
    @_pumps = {}
    @_state = Group.STOPPED

  addPump: (name, pump = null) ->
    throw new Error 'Pump already exists' if @_pumps[name]?
    @_pumps[name] = pump ? new Pump
    @_pumps[name].on 'end', => @pumpEnded(name)
    @_pumps[name]

  pumpEnded: (name) ->
    end = true
    for name, pump of @_pumps
      end = false if !pump.isEnded()
    return if !end

    @_state = Pump.ENDED
    @emit 'end'

  pump: (name) ->
    throw new Error "Pump #{name} does not exist" if !@_pumps[name]?
    @_pumps[name]

  start: ->
    throw new Error 'Group already started' if @_state != Group.STOPPED
    @_state = Group.STARTED
    do pump.start for name, pump of @_pumps
    @

  isEnded: ->
    @_state == Pump.ENDED

  whenFinished: ->
    return new Promise (resolve) =>
      @on 'end', ->
        resolve()

  createBuffer: (options = {}) ->
    new Buffer options

module.exports = Group
