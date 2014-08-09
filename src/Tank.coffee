EventEmitter = require('events').EventEmitter
Promise = require('bluebird')
Pump = require('./Pump.coffee')

class Tank extends EventEmitter
  constructor: (options) ->
    @content = options?.content || []
    @size = options?.size || 10
    @_sealed = false

    if options?.drain
      if options.size
        throw new Error 'Cannot specify size option for a tank with drain option'

      @size = 1
      @drain = if options?.drainPromisified then options.drain else Promise.promisify(options.drain)

  isEmpty: ->
    @content.length == 0

  isFull: ->
    @content.length >= @size

  getContent: ->
    @content

  fill: (data) ->
    throw new Error('Cannot fill sealed tanks') if @_sealed == true
    throw new Error('Tank is full') if @isFull()
    @content.push data
    @emit 'fill'
    @emit 'full' if @isFull()

    if @drain?
        @drain(@content[0])
          .then => do @_release

    @

  fillAsync: (data) ->
    if !@isFull()
      Promise.resolve(@fill(data))
    else
      new Promise (resolve, reject) =>
        @once 'release', =>
          @fill(data)
          resolve()

  release: ->
    if @drain?
      throw new Error('Content is automatically released through the callback given in drain option')

    do @_release

  _release: ->
    throw new Error('Tank is empty') if @isEmpty()
    result = @content.shift()
    @emit 'release'
    if @isEmpty()
      @emit 'empty'
      @emit 'end' if @_sealed == true
    result

  seal: ->
    throw new Error('Tank already sealed') if @_sealed == true
    @_sealed = true
    @emit 'sealed'
    @emit 'end' if @isEmpty()

  isSealed: ->
    @_sealed == true

  isEnded: ->
    @isSealed() && @isEmpty()

module.exports = Tank
