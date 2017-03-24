require('should')
sinon = require('sinon')
PostgresqlMixin = require('../PostgresqlMixin')

describe 'PostgresqlMixin(client)', ->
  it 'should throw error when client is not given', ->
    ( ->
      PostgresqlMixin()
    ).should.throw('Postgresql mixin requires client to be given')
