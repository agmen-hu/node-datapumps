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

  it 'should return a promise', ->
    target = {}

    RestMixin target

    target.get('foo').should.be.instanceof Promise
