require('should')
sinon = require('sinon')
restler = require 'restler'
restler.get = sinon.stub().returns
  on: ->

RestMixin = require('../RestMixin')
Promise = require 'bluebird'

describe 'RestMixin', ->
  it 'should wrap .get method of restler', ->
    target = {}

    RestMixin target

    target.get 'foo'
    restler.get.calledOnce.should.be.true
    restler.get.getCall(0).args[0].should.equal 'foo'

  it 'should return a promise in the wrapped .get() method', ->
    target = {}

    RestMixin target

    target.get('foo').should.be.instanceof Promise


  describe 'when using .fromRest() method', ->
    buffer =
      writeArrayAsync: sinon.stub().returns(Promise.resolve())
      seal: sinon.spy()
    target =
      from: -> buffer
      createBuffer: sinon.spy()

    it 'should be possible to fill input buffer', (done) ->
      buffer.writeArrayAsync.reset()
      buffer.seal.reset()

      RestMixin target

      target.fromRest
        query: -> Promise.resolve [ 'foo', 'bar' ]

      process.nextTick ->
          buffer.writeArrayAsync.calledOnce.should.be.true
          buffer.seal.calledOnce.should.be.true
          done()

    it 'should be possible to map results with resultMapping key', (done) ->
      buffer.writeArrayAsync.reset()

      RestMixin target

      target.fromRest
        query: -> Promise.resolve { items: [  'foo', 'bar' ] }
        resultMapping: (result) -> result.items

      process.nextTick ->
          buffer.writeArrayAsync.calledOnce.should.be.true
          buffer.writeArrayAsync.getCall(0).args[0].should.eql [ 'foo', 'bar' ]
          done()

    it 'should be possible to use paginated REST service', (done) ->
      buffer.writeArrayAsync.reset()
      buffer.seal.reset()

      RestMixin target

      target.fromRest
        query: (nextPage) -> Promise.resolve nextPage ? [  'foo', 'bar' ]
        nextPage: (result) ->
          if result[0] != 'next'
            return [ 'next' ]

      process.nextTick ->
          buffer.writeArrayAsync.calledTwice.should.be.true
          buffer.writeArrayAsync.getCall(0).args[0].should.eql [ 'foo', 'bar' ]
          buffer.writeArrayAsync.getCall(1).args[0].should.eql [ 'next' ]
          buffer.seal.calledOnce.should.be.true
          done()
