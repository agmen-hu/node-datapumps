require('should')
sinon = require('sinon')

MergeMixin = require('../MergeMixin')
Pump = require('../../Pump')
Buffer = require('../../Buffer')
Promise = require 'bluebird'

describe 'MergeMixin', ->
  it 'should merge data from multiple inputs', (done) ->
    buffer1 = new Buffer
      sealed: true
      content: [ 'b1' ]
    buffer2 = new Buffer
      sealed: true
      content: [ 'b2' ]

    result = []
    (pump = new Pump())
      .mixin MergeMixin
      .from buffer1
      .from buffer2
      .process (data) -> result.push data
      .start()
      .whenFinished()
        .then ->
          result.indexOf('b1').should.not.equal -1
          result.indexOf('b2').should.not.equal -1
          done()
