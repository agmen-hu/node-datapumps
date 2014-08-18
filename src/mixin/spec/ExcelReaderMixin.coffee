require 'should'
sinon = require 'sinon'
ExcelReaderMixin = require '../ExcelReaderMixin'
xlsx = require 'xlsx'

describe 'ExcelReaderMixin(options)', ->
  it 'should require worksheet property', ->
    ( ->
      mixin = ExcelReaderMixin {}
      target = {}
      mixin target
    ).should.throw 'worksheet property is required for ExcelReaderMixin'

  it 'should convert worksheet into json and put it in the input buffer of the pump', ->
    workbook = xlsx.readFile __dirname + '/data/nameAndAddress.xlsx'
    target =
      from: sinon.spy()

    mixin = ExcelReaderMixin
      worksheet: workbook.Sheets.TestSheet

    mixin(target)
    target.from.calledOnce.should.be.true
    target.from.getCall(0).args[0].getContent().should.eql [
      { Name: 'foo', Address: 'bar' }
    ]

  it 'should use columnMapping to convert fill the input buffer', ->
    workbook = xlsx.readFile __dirname + '/data/nameAndAddress.xlsx'
    target =
      from: sinon.spy()

    mixin = ExcelReaderMixin
      worksheet: workbook.Sheets.TestSheet
      columnMapping:
        Name: 'name'
        Address: 'address'

    mixin(target)
    target.from.calledOnce.should.be.true
    target.from.getCall(0).args[0].getContent().should.eql [
      { name: 'foo', address: 'bar' }
    ]
