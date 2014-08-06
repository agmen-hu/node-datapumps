EventEmitter = require('events').EventEmitter
Promise = require('bluebird')

class Tank extends EventEmitter
  constructor: (options) ->
    options = options || {}
    @size = options.size || 10
    @content = []

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
    @emit 'change'
    if @isFull()
      @emit 'full'
    @

  release: ->
    throw new Error('Tank is empty') if @isEmpty()
    result = @content.shift()
    @emit 'release'
    @emit 'change'
    if @isEmpty()
      @emit 'empty'
    result

module.exports = Tank
