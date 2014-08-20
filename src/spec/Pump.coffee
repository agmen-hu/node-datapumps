require('should')
sinon = require('sinon')
Promise = require('bluebird')
Buffer = require('../Buffer')
Pump = require('../Pump')

describe 'Pump', ->
  describe '#start()', ->
    it 'should pump content from source to output buffer', (done) ->
      buffer = new Buffer
        content: [ 'foo', 'bar', 'test', 'content' ]

      buffer.seal()

      pump = new Pump
      pump.from buffer

      sinon.spy(pump.buffer(), 'write')

      pump.on 'end', ->
        pump.buffer().write.getCall(0).args[0].should.equal 'foo'
        pump.buffer().write.getCall(1).args[0].should.equal 'bar'
        pump.buffer().write.getCall(2).args[0].should.equal 'test'
        pump.buffer().write.getCall(3).args[0].should.equal 'content'
        done()

      pump.start()
      pump.buffer().readAsync()
        .then => pump.buffer().readAsync()
        .then => pump.buffer().readAsync()
        .then => pump.buffer().readAsync()

    it 'should not be possible to change source buffer after start', ->
      source = new Buffer
      source.readAsync = -> Promise.resolve()

      pump = new Pump
      ( ->
        pump
          .from source
          .start()
          .from source
      ).should.throw 'Cannot change source buffer after pumping has been started'

    it 'should not be possible to change output buffer after start', ->
      source = new Buffer
      source.readAsync = -> Promise.resolve()

      pump = new Pump
      ( ->
        pump
          .from source
          .start()
          .buffers { output: source }
      ).should.throw 'Cannot change output buffers after pumping has been started'


    it 'should write target buffer when source is readable', (done) ->
      buffer1 = new Buffer
        content: [ 'test' ]

      pump = new Pump

      pump.buffer().writeAsync = sinon.spy (data) ->
        data.should.equal "test"
        do done

      pump
        .from buffer1
        .start()

    it 'should create error buffer on start if not set', ->
      pump = new Pump
      pump.from new Buffer
      pump.start()
      pump.errorBuffer().should.not.be.null

    it 'should write errors to the error buffer', (done) ->
      pump = new Pump
      pump.from new Buffer
      errorBuffer = new Buffer
      pump.errorBuffer errorBuffer
      pump
        .process ->
          Promise.reject('test')

      pump.from()
        .write 'testData'
        .seal()

      pump
        .on 'end', ->
          pump.errorBuffer().getContent().length.should.equal(1)
          pump.errorBuffer().getContent()[0].should.eql({ message: 'test', pump: null })
          done()
        .start()

  it 'should seal output buffers when source buffer ends', ->
    source = new Buffer
    source.callbacks = {}
    source.on = sinon.spy (event, callback) -> source.callbacks[event] = callback

    pump = new Pump
    pump.from source

    sinon.spy pump.buffer(), 'seal'
    do source.callbacks.end
    do pump.start
    pump.buffer().seal.calledOnce.should.be.true

  it 'should emit end event when all output buffers ended', ->
    source = new Buffer
    source.callbacks = {}
    source.on = sinon.spy (event, callback) -> source.callbacks[event] = callback

    pump = new Pump
    pump.from source

    sinon.spy pump.buffer(), 'seal'
    endSpy = sinon.spy()
    pump.on 'end', endSpy
    do source.callbacks.end
    do pump.start

    endSpy.calledOnce.should.be.true
    pump.isEnded().should.be.true

  it 'should be able to transform the data', (done) ->
    buffer = new Buffer
      content: [ 'foo', 'bar' ]

    pump = new Pump
    pump
      .from buffer
      .process (data) ->
        @buffer().writeAsync data + '!'

    sinon.spy(pump.buffer(), 'write')
    pump.on 'end', ->
      pump.buffer().write.getCall(0).args[0].should.equal 'foo!'
      pump.buffer().write.getCall(1).args[0].should.equal 'bar!'
      done()

    buffer.seal()
    pump.start()
    pump.buffer().readAsync()
      .then -> pump.buffer().readAsync()

  describe '#mixin()', ->
    testMixin = (target) ->
      target.foo = 'bar'

    it 'should add mixins from array to the pump', ->
      pump = new Pump

      testMixin2 = (target) ->
        target.foo2 = 'bar2'

      pump.mixin [ testMixin, testMixin2 ]

      pump.foo.should.equal 'bar'
      pump.foo2.should.equal 'bar2'

    it 'should be able to add a single mixin', ->
      pump = new Pump
      pump.mixin testMixin
      pump.foo.should.equal 'bar'

  describe '#from()', ->
    it 'should throw error when argument is not a buffer or stream', ->
      pump = new Pump
      ( ->
        pump.from('test')
      ).should.throw 'Argument must be datapumps.Buffer or stream'

  describe '#pause()', ->
    it 'should pause the pump', (done) ->
      pump = new Pump
      pump.from new Buffer

      pump.from().write 'test'
      pump.from().write 'test'
      pump.buffer().on 'write', ->
        pump.pause()
      pump.start()
      setTimeout ->
        pump.from().getContent().length.should.equal 1
        pump._state.should.equal = Pump.PAUSED
        done()
      , 10

  describe '#resume()', ->
    it 'should resume the pump when its paused', ->
      pump = new Pump
      pump.from new Buffer

      pump.start()
      pump.pause()
      sinon.spy pump, '_pump'

      pump.resume()
      pump._pump.calledOnce.should.be.true

  describe '#copy(data, buffers = null)', ->
    it 'should write data to the default buffer if buffers parameter is not given', (done) ->
      pump = new Pump()
      pump.copy 'test'
        .then ->
          pump.buffer().getContent().should.eql [ 'test' ]
          done()

    it 'should write data to the given buffer', (done) ->
      pump = new Pump()
      pump.copy 'test', 'output'
        .then ->
          pump.buffer().getContent().should.eql [ 'test' ]
          done()

    it 'should write data to the given buffers if multiple buffers are given', (done) ->
      pump = new Pump()
      pump.buffers
        out1: new Buffer
        out2: new Buffer
      pump.copy 'test', [ 'out1', 'out2' ]
        .then ->
          pump.buffer('out1').getContent().should.eql [ 'test' ]
          pump.buffer('out2').getContent().should.eql [ 'test' ]
          done()
