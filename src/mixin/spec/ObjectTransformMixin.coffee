require('should')
sinon = require('sinon')
ObjectTransformMixin = require('../ObjectTransformMixin')

describe 'ObjectTransformMixin()', ->
  target = {}
  mixin = ObjectTransformMixin()
  mixin target

  describe '#propertiesToLowerCase()', ->
    it 'should lowercase property names', ->
      target.propertiesToLowerCase
          TEST: 'value'
        .should.eql
          test: 'value'

  describe '#requireProperty()', ->
    it 'should throw error when property is missing', ->
      ( ->
        target.requireProperty {}, 'test'
      ).should.throw 'Missing property: test'

    it 'should return property value if property exists', ->
      target.requireProperty { test: 'value' }, 'test'
        .should.equal 'value'

    it 'should return property values if multiple property checked', ->
      obj =
        test: 'value'
        foo: 'bar'
        misc: false
      target.requireProperty obj, [ 'test', 'misc' ]
        .should.eql
          test: 'value'
          misc: false

  describe '#boolValueOf()', ->
    it 'should return false for "off", "false", "no", false, null or undefined', ->
      target.boolValueOf('off').should.eql false
      target.boolValueOf('false').should.eql false
      target.boolValueOf('no').should.eql false
      target.boolValueOf(false).should.eql false
      target.boolValueOf(null).should.eql false
      target.boolValueOf(undefined).should.eql false

      target.boolValueOf('anyOtherValue').should.eql true
