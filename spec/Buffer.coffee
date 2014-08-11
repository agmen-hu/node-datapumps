require('should')
Promise = require('bluebird')
sinon = require('sinon')
Buffer = require('../src/Buffer')

describe 'Buffer', ->
  it 'should be empty when created', ->
    buffer = new Buffer
    buffer.isEmpty().should.be.true

  describe '#fill(data)', ->
    it 'should add the data to the buffer', ->
      buffer = new Buffer
      buffer.fill('test')
      buffer.getContent().should.eql [ 'test' ]

    it 'should throw error when the buffer is full', ->
      buffer = new Buffer
        size: 1
      buffer.fill('test')
      ( ->
        buffer.fill('again')
      ).should.throw 'Buffer is full'

    it 'should emit full event when the buffer becomes full', (done) ->
      buffer = new Buffer
        size: 2

      buffer.fill('test')
      buffer.on 'full', ->
        done()

      buffer.fill('test')

  describe '#fillAsync(data)', ->
    it 'should fill buffer when not full', (done) ->
      buffer = new Buffer

      buffer.fillAsync 'test'
        .then ->
          buffer.getContent().should.eql [ 'test' ]
          do done

    it 'should wait for a release event to fill the buffer', (done) ->
      buffer = new Buffer
        size: 1

      buffer.fill('test')
      buffer.fillAsync 'test2'
        .then ->
          buffer.getContent().should.eql [ 'test2' ]
          do done

      do buffer.release

    it 'should return a promise', ->
      buffer = new Buffer

      promise = buffer.fillAsync 'test'
      promise.should.be.an.instanceOf(Promise)

  describe '#release()', ->
    it 'should return first data item when not empty', ->
      buffer = new Buffer

      buffer.fill 'test1'
      buffer.fill 'test2'
      buffer.release().should.equal 'test1'

    it 'should throw error when buffer is empty', ->
      buffer = new Buffer

      ( ->
        buffer.release()
      ).should.throw 'Buffer is empty'

  describe 'having a drain option', ->
    it 'should not have size option specified', ->
      ( ->
        new Buffer
          drain: (data, cb) ->
          size: 5
      ).should.throw 'Cannot specify size option for a buffer with drain option'

    it 'should not be able to release data manually', ->
      buffer = new Buffer
        drain: (data, cb) ->
          do cb

      ( ->
        do buffer.release
      ).should.throw 'Content is automatically released through the callback given in drain option'

    it 'should release any filled item using the promisifiable drain function', (done) ->
      buffer = new Buffer
        drain: (data, cb) ->
          do cb

      buffer.on 'empty', ->
        do done

      buffer.fill 'test'

  describe 'that is sealed', ->
    it 'should throw error when trying to fill it', ->
      buffer = new Buffer
      buffer.fill 'test'

      do buffer.seal
      ( ->
        buffer.fill 'test2'
      ).should.throw 'Cannot fill sealed buffer'

    it 'should emit end event if becomes empty when sealed', (done) ->
      buffer = new Buffer
      buffer.fill 'test'

      buffer.on 'end', ->
        do done

      do buffer.seal
      do buffer.release

    it 'should emit end event if sealed when empty', (done) ->
      buffer = new Buffer

      buffer.on 'end', ->
        do done

      do buffer.seal
