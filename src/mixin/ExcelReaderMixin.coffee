{ utils: { sheet_to_json: convertSheetToJson } } = require 'xlsx'
Buffer = require '../Buffer'

ExcelReaderMixin = ({ worksheet, columnMapping }) ->
  (target) ->
    throw new Error 'worksheet property is required for ExcelReaderMixin' if !worksheet?
    target._excel =
      worksheet: worksheet
      columnMapping: columnMapping

    mapColumnNames = (data) ->
      result = {}
      for from,to of columnMapping
        result[to] = data[from]
      result

    content = []
    if columnMapping
      content.push mapColumnNames data for data in convertSheetToJson worksheet
    else
      content = convertSheetToJson worksheet

    buffer = new Buffer
      content: content

    target.from buffer
    buffer.seal()

module.exports = ExcelReaderMixin
