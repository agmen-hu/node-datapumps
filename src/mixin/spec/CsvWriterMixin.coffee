require('should')
sinon = require('sinon')
CsvWriterMixin = require('../CsvWriterMixin')

describe 'CsvWriterMixin(options)', ->
  it 'should require path to specified in options', ->
    ( ->
      CsvWriterMixin({})
    ).should.throw 'path option is required.'
