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
      source =
        on: ->
        isEmpty: -> true
        once: ->
        readAsync: -> Promise.resolve()

      pump = new Pump
      ( ->
        pump
          .from source
          .start()
          .from source
      ).should.throw 'Cannot change source buffer after pumping has been started'

    it 'should not be possible to change output buffer after start', ->
      source =
        on: ->
        isEmpty: -> true
        once: ->
        readAsync: -> Promise.resolve()

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

  it 'should seal output buffers when source buffer ends', ->
    source =
      on: ->
      isEmpty: -> true
      callbacks: {}
      on: sinon.spy (event, callback) -> source.callbacks[event] = callback

    pump = new Pump
    pump.from source

    sinon.spy pump.buffer(), 'seal'
    do source.callbacks.end
    do pump.start
    pump.buffer().seal.calledOnce.should.be.true

  it 'should emit end event when all output buffers ended', ->
    source =
      on: ->
      isEmpty: -> true
      callbacks: {}
      on: sinon.spy (event, callback) -> source.callbacks[event] = callback

    pump = new Pump
    pump.from source

    sinon.spy pump.buffer(), 'seal'
    endSpy = sinon.spy()
    pump.on 'end', endSpy
    do source.callbacks.end
    do pump.start

    endSpy.calledOnce.should.be.true

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
