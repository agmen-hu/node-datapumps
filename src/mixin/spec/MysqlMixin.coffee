require('should')
sinon = require('sinon')
MysqlMixin = require('../MysqlMixin')

describe 'MysqlMixin(connection)', ->
  it 'should store connection in target object', ->
    target = {}
    connection =
      query: ->

    mixin = MysqlMixin connection
    mixin target

    target._mysql.connection.should.equal = connection
