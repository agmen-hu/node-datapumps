require('should')
sinon = require('sinon')
ExcelWriterMixin = require('../ExcelWriterMixin')

describe 'ExcelWriterMixin(onMixin)', ->
  it 'should call function in onMixin argument on mixin in target context', (done) ->
    target =
      on: ->

    mixin = ExcelWriterMixin ->
      target.should.equal @
      do done

    mixin target

  it 'should write excel file on end of pumping if workbook was opened', ->
    target =
      eventHandler: {}
      on: (event, cb) -> target.eventHandler[event] = cb

    mixin = ExcelWriterMixin ->
      target.createWorkbook 'test.xlsx'

    mixin target

    target._excel.workbook.write = sinon.spy()
    target.eventHandler.end()

    target._excel.workbook.write.calledOnce.should.be.true

  it 'should not be possible to write headers before creating a worksheet', ->
    target =
      on: ->

    mixin = ExcelWriterMixin ->
    mixin target

    ( ->
      target.writeHeaders [ 'test ']
    ).should.throw 'Use createWorksheet before writing headers'

  it 'should not be possible to write headers if rows were already written to the worksheet', ->
    target =
      on: ->

    mixin = ExcelWriterMixin ->
      target.createWorkbook 'test.xlsx'
      target.createWorksheet 'Customers'
    mixin target

    ( ->
      target.writeRow [ 'test ']
      target.writeHeaders [ 'test ']
    ).should.throw 'Use writeHeaders before writing any rows to the worksheet'

  it 'should not be possible to write rows before creating a worksheet', ->
    target =
      on: ->

    mixin = ExcelWriterMixin ->
    mixin target

    ( ->
      target.writeRow [ 'test ']
    ).should.throw 'Use createWorksheet before writing rows'
