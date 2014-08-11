EventEmitter = require('events').EventEmitter
Promise = require('bluebird')

class Buffer extends EventEmitter
  constructor: (options) ->
    @content = options?.content || []
    @size = options?.size || 10
    @_sealed = false

    if options?.drain
      if options.size
        throw new Error 'Cannot specify size option for a buffer with drain option'

      @size = 1
      @drain = if options?.drainPromisified then options.drain else Promise.promisify(options.drain)

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
    @emit 'write'
    @emit 'full' if @isFull()

    if @drain?
        @drain(@content[0])
          .then => do @_release

    @

  writeAsync: (data) ->
    if !@isFull()
      Promise.resolve(@write(data))
    else
      new Promise (resolve, reject) =>
        @once 'release', =>
          @write(data)
          resolve()

  read: ->
    if @drain?
      throw new Error('Content is automatically released through the callback given in drain option')

    do @_release

  _release: ->
    throw new Error('Buffer is empty') if @isEmpty()
    result = @content.shift()
    @emit 'release'
    if @isEmpty()
      @emit 'empty'
      @emit 'end' if @_sealed == true
    result

  readAsync: ->
    if !@isEmpty()
      Promise.resolve(@read())
    else
      new Promise (resolve, reject) =>
        @once 'write', =>
          resolve(@read())

  seal: ->
    throw new Error('Buffer already sealed') if @_sealed == true
    @_sealed = true
    @emit 'sealed'
    @emit 'end' if @isEmpty()

  isSealed: ->
    @_sealed == true

  isEnded: ->
    @isSealed() && @isEmpty()

module.exports = Buffer
