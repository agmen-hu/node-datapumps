EventEmitter = require('events').EventEmitter
Promise = require('bluebird')

class Buffer extends EventEmitter
  @_defaultBufferSize: 10

  @defaultBufferSize: (size) ->
    return Buffer._defaultBufferSize if !size?
    Buffer._defaultBufferSize = size

  constructor: (options = {}) ->
    @content = options.content ? []
    @size = options.size ? Buffer._defaultBufferSize
    @_sealed = options.sealed ? false

  isEmpty: ->
    @content.length == 0

  isFull: ->
    @content.length >= @size

  getContent: ->
    @content

  write: (data) ->
    throw new Error('Cannot write sealed buffer') if @_sealed == true
    throw new Error('Buffer is full') if @isFull()
    @content.push data
    @emit 'write', data
    @emit 'full' if @isFull()
    @

  writeAsync: (data) ->
    if !@isFull()
      Promise.resolve @write data
    else
      new Promise (resolve, reject) =>
        @once 'release', =>
          resolve @writeAsync data

  writeArrayAsync: (dataArray) ->
    first = dataArray.shift()
    @writeAsync first
      .then => @writeArrayAsync dataArray if dataArray.length > 0

  read: ->
    throw new Error('Buffer is empty') if @isEmpty()
    result = @content.shift()
    @emit 'release', result
    if @isEmpty()
      @emit 'empty'
      @emit 'end' if @_sealed == true
    result

  readAsync: ->
    if !@isEmpty()
      Promise.resolve(@read())
    else
      new Promise (resolve, reject) =>
        @once 'write', => resolve @readAsync()

  seal: ->
    throw new Error('Buffer already sealed') if @_sealed == true
    @_sealed = true
    @emit 'sealed'
    @emit 'end' if @isEmpty()
    @

  isSealed: ->
    @_sealed == true

  isEnded: ->
    @isSealed() && @isEmpty()

module.exports = Buffer
