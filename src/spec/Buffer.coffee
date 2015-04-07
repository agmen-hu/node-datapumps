require('should')
Promise = require('bluebird')
sinon = require('sinon')
Buffer = require('../Buffer')

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

  describe '#appendArray(dataArray)', ->
    it 'should add data to the buffer', ->
      buffer = new Buffer
        size: 10

      buffer.write 'test'
      buffer.appendArray [ 'foo', 'bar' ]

      buffer.size.should.equal 10
      buffer.getContent().should.eql [ 'test', 'foo', 'bar' ]

    it 'should increase buffer size when necessary', ->
      buffer = new Buffer
        size: 2

      buffer.write 'test'
      buffer.appendArray [ 'foo', 'bar' ]

      buffer.size.should.equal 3
      buffer.getContent().should.eql [ 'test', 'foo', 'bar' ]

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

  describe '#writeArrayAsync(dataArray)', ->
    it 'should write every item from dataArray to the buffer', (done) ->
      buffer = new Buffer

      promise = buffer.writeArrayAsync ['foo', 'bar']
      promise.then ->
        done() if buffer.getContent().should.eql ['foo', 'bar']

    it 'should return a promise that fulfills when the last item of the array is written', (done) ->
      buffer = new Buffer
        size: 1

      fooIsWritten = fooIsReleased = barIsWritten = false
      buffer.on 'write', (data) ->
        if data == 'foo'
          fooIsWritten = true
          buffer.read()
        barIsWritten = true if data == 'bar'

      buffer.on 'release', (data) ->
        fooIsReleased = true if data == 'foo'

      promise = buffer.writeArrayAsync ['foo', 'bar']
      promise.then ->
        done() if fooIsWritten and fooIsReleased and barIsWritten

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

  describe 'Buffer.defaultBufferSize', ->
    it 'should set default buffer size for newly created buffers', ->
      Buffer.defaultBufferSize 500
      buffer = new Buffer
      buffer.size.should.equal 500

    it 'should return default buffer size when called without arguments', ->
      Buffer.defaultBufferSize 1000
      Buffer.defaultBufferSize().should.equal 1000
