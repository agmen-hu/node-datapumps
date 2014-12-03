{ readFile, utils: { sheet_to_json: convertSheetToJson } } = require 'xlsx'
Buffer = require '../Buffer'

# OOXML Excel (.xlsx) reader mixin for node-datapumps.
#
# Please note that the excel workbook must have a header row.
#
# Usage:
#  * Load an .xlsx and select a worksheet:
#
#    ```coffee
#    { ExcelReaderMixin } = require('datapumps/mixins')
#    pump
#      .mixin ExcelReaderMixin
#        path: 'path/to/myWorkbook.xlsx'
#        worksheet: 'Worksheet1'
#    ```
#
#  * The `.process()` method will receive a plain object per row (property names from the header row):
#    ```coffee
#    pump
#      .process (row) ->
#        console.log row.first_name # assuming your worksheet has a first_name column
#    ```
#
#  * Alternatively, you can set worksheet from an already loaded workbook:
#    ```coffee
#    { ExcelReaderMixin } = require('datapumps/mixins')
#    xlsx = require 'xlsx'
#    xlsx.readFile 'path/to/myWorkbook.xlsx'
#    pump1
#      .mixin ExcelReaderMixin
#        worksheet: workbook.Sheets.Worksheet1
#    pump2
#      .mixin ExcelReaderMixin
#        worksheet: workbook.Sheets.Worksheet2
#    ```
#
#  * You can also map column names to resulting property names:
#    ```coffee
#    { ExcelReaderMixin } = require('datapumps/mixins')
#    pump
#      .mixin ExcelReaderMixin
#        path: 'path/to/myWorkbook.xlsx'
#        worksheet: 'Worksheet1'
#        columnMapping:
#          'Very long column name with spaces': 'myColumn'
#    ```
#
#  * ExcelReaderMixin plays well with [ObjectTransformMixin](http://agmen-hu.github.io/node-datapumps/docs/mixin/ObjectTransformMixin.html) for validating worksheet content:
#    ```coffee
#    { ObjectTransformMixin, ExcelReaderMixin } = require('datapumps/mixins')
#    pump
#      .mixin ExcelReaderMixin
#        path: 'path/to/myWorkbook.xlsx'
#        worksheet: 'Worksheet1'
#      .mixin ObjectTransformMixin()
#      .process (row) ->
#        row = @propertiesToLowerCase row
#        @requireProperty row, [ 'first name', 'last name', 'email address' ]
#    ```
#
ExcelReaderMixin = ({ worksheet, columnMapping, path }) ->
  (target) ->
    if path?
      workbook = readFile path
      worksheet = workbook.Sheets[worksheet]
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
