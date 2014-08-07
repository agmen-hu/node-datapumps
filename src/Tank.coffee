EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Pump = require('./Pump.coffee')

class Tank extends EventEmitter
  constructor: (options) ->
    @content = options?.content || []
    @size = options?.size || 10

    if options?.drain
      if options.size
        throw new Error 'Cannot specify size option for a tank with drain option'

      @size = 1
      @drain = if options?.drainPromisified then options.drain else Promise.promisify(options.drain)

    if options?.pumpFrom
      @pump = new Pump
        from: options.pumpFrom
        to: @

      do @pump.start

    if options?.fillFromStream
      options.fillFromStream.on 'data', (data) => @fill data
      @on 'full', -> do options.fillFromStream.pause
      @on 'release', -> do options.fillFromStream.resume

  isEmpty: ->
    @content.length == 0

  isFull: ->
    @content.length >= @size

  getContent: ->
    @content

  fill: (data) ->
    throw new Error('Tank is full') if @isFull()
    @content.push data
    @emit 'fill'
    @emit 'full' if @isFull()

    if @drain?
        @drain(@content[0])
          .then => do @_release

    @

  release: ->
    if @drain?
      throw new Error('Content is automatically released through the callback given in drain option')

    do @_release

  _release: ->
    throw new Error('Tank is empty') if @isEmpty()
    result = @content.shift()
    @emit 'release'
    @emit 'empty' if @isEmpty()
    result

module.exports = Tank
