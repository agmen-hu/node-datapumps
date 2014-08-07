Promise = require('bluebird')

class Pump
  constructor: (options) ->
    @from = options.from
    @to = options.to

  start: ->
    @suckData()
      .then (data) => @pumpData(data)
      .done => @start()

  suckData: ->
    if !@from.isEmpty()
      Promise.resolve(@from.release())
    else
      new Promise (resolve, reject) =>
        @from.once 'fill', =>
          resolve(@from.release())

  pumpData: (data) ->
    if !@to.isFull()
      Promise.resolve(@to.fill(data))
    else
      new Promise (resolve, reject) =>
        @to.once 'release', =>
          @to.fill(data)
          resolve()

module.exports = Pump
