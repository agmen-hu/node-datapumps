require('should')
sinon = require('sinon')
BatchMixin = require('../BatchMixin')
Pump = require('../../Pump')

describe 'BatchMixin', ->
  it 'should call processBatch to process items', (done) ->
    processCallback = sinon.spy()

    (pump = new Pump)
      .mixin BatchMixin
      .from pump.createBuffer
        size: 10
        content: [ 'foo', 'bar', 'yeehaa' ]
        sealed: true
      .batchSize 2
      .processBatch processCallback
      .start()
      .whenFinished()
        .then =>
          processCallback.calledTwice.should.be.true
          processCallback.getCall(0).args[0].should.eql [ 'foo', 'bar' ]
          processCallback.getCall(1).args[0].should.eql [ 'yeehaa' ]
          done()

  it 'should process input buffers with item count less than batch size', (done) ->
    processCallback = sinon.spy()

    (pump = new Pump)
      .mixin BatchMixin
      .from pump.createBuffer
        size: 10
        content: [ 'foo', 'bar', 'yeehaa' ]
        sealed: true
      .processBatch processCallback
      .start()
      .whenFinished()
        .then =>
          processCallback.calledOnce.should.be.true
          processCallback.getCall(0).args[0].should.eql [ 'foo', 'bar', 'yeehaa' ]
          done()

  it 'should not call .processBatch for empty inputs', (done) ->
    processCallback = sinon.spy()

    (pump = new Pump)
      .mixin BatchMixin
      .from pump.createBuffer
        sealed: true
      .processBatch processCallback
      .start()
      .whenFinished()
        .then =>
          processCallback.called.should.be.false
          done()
