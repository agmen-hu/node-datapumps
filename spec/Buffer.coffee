require('should')
Promise = require('bluebird')
sinon = require('sinon')
Buffer = require('../src/Buffer')

describe 'Buffer', ->
  it 'should be empty when created', ->
    buffer = new Buffer
    buffer.isEmpty().should.be.true

  describe '#write(data)', ->
    it 'should add the data to the buffer', ->
      buffer = new Buffer
      buffer.write('test')
      buffer.getContent().should.eql [ 'test' ]

    it 'should throw error when the buffer is full', ->
      buffer = new Buffer
        size: 1
      buffer.write('test')
      ( ->
        buffer.write('again')
      ).should.throw 'Buffer is full'

    it 'should emit full event when the buffer becomes full', (done) ->
      buffer = new Buffer
        size: 2

      buffer.write('test')
      buffer.on 'full', ->
        done()

      buffer.write('test')

  describe '#writeAsync(data)', ->
    it 'should write buffer when not full', (done) ->
      buffer = new Buffer

      buffer.writeAsync 'test'
        .then ->
          buffer.getContent().should.eql [ 'test' ]
          do done

    it 'should wait for a read event to write the buffer', (done) ->
      buffer = new Buffer
        size: 1

      buffer.write('test')
      buffer.writeAsync 'test2'
        .then ->
          buffer.getContent().should.eql [ 'test2' ]
          do done

      do buffer.read

    it 'should return a promise', ->
      buffer = new Buffer

      promise = buffer.writeAsync 'test'
      promise.should.be.an.instanceOf(Promise)

  describe '#read()', ->
    it 'should return first data item when not empty', ->
      buffer = new Buffer

      buffer.write 'test1'
      buffer.write 'test2'
      buffer.read().should.equal 'test1'

    it 'should throw error when buffer is empty', ->
      buffer = new Buffer

      ( ->
        buffer.read()
      ).should.throw 'Buffer is empty'

  describe '#readAsync()', ->
    it 'should return a promise fulfilled when the buffer is readable', (done) ->
      buffer = new Buffer

      buffer.write 'test'
      buffer.readAsync()
        .then (result) ->
          result.should.equal 'test'
          do done

  describe 'having a drain option', ->
    it 'should not have size option specified', ->
      ( ->
        new Buffer
          drain: (data, cb) ->
          size: 5
      ).should.throw 'Cannot specify size option for a buffer with drain option'

    it 'should not be able to read data manually', ->
      buffer = new Buffer
        drain: (data, cb) ->
          do cb

      ( ->
        do buffer.read
      ).should.throw 'Content is automatically released through the callback given in drain option'

    it 'should read any writeed item using the promisifiable drain function', (done) ->
      buffer = new Buffer
        drain: (data, cb) ->
          do cb

      buffer.on 'empty', ->
        do done

      buffer.write 'test'

  describe 'that is sealed', ->
    it 'should throw error when trying to write it', ->
      buffer = new Buffer
      buffer.write 'test'

      do buffer.seal
      ( ->
        buffer.write 'test2'
      ).should.throw 'Cannot write sealed buffer'

    it 'should emit end event if becomes empty when sealed', (done) ->
      buffer = new Buffer
      buffer.write 'test'

      buffer.on 'end', ->
        do done

      do buffer.seal
      do buffer.read

    it 'should emit end event if sealed when empty', (done) ->
      buffer = new Buffer

      buffer.on 'end', ->
        do done

      do buffer.seal
