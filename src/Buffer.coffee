EventEmitter = require('events').EventEmitter
Promise = require('bluebird')

class Buffer extends EventEmitter
  constructor: (options = {}) ->
    @content = options.content ? []
    @size = options.size ? 10
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
          @write(data)
          resolve()

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
        @once 'write', => resolve(@read())

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
