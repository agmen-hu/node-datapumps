Promise = require('bluebird')

class Pump
  constructor: (options) ->
    @from = options.from
    @to = options.to

    if options.sealTargetWhenSourceEnded ? true
      @from.on 'end', =>
        do @to.seal if !@to.isSealed()

    if options?.transform
      @transform = Promise.promisify(options.transform)

  start: ->
    whenDataAvailable = @suckData()
    if @transform?
      whenDataAvailable = whenDataAvailable.then (data) => @transform(data)
    whenDataAvailable
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
