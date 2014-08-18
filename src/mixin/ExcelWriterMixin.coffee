# OOXML Excel (.xlsx) writer mixin for node-datapumps.
#
# Usage:
#  * Require excel writer mixin:
#    ```coffee
#    { ExcelWriterMixin } = require('datapumps/mixins')
#    ```
#
#  * The parameter of the mixin is a function than will be executed when the mixin is added to a pump. Use that function to create your workbook and headers:
#
#    ```coffee
#    pump
#      .mixin ExcelWriterMixin ->
#        pump.createWorkbook 'test.xlsx'
#        pump.createWorksheet 'MySheet'
#        pump.writeHeaders [ 'Name', 'Code' ]
#    ```
#
#  * Use `.writeRow` in the `.process` method of the pump to write a row in excel:
#
#    ```coffee
#    pump
#      .process (product) ->
#        pump.writeRow [ product.name, product.code ]
#    ```
#
# Complete example:
# ```coffee
# customersExcelSheet = new Pump
# customersExcelSheet
#   .from <yoursource>
#   .mixin ExcelWriterMixin ->
#     @createWorkbook 'test.xlsx'
#     @createWorksheet 'Customers'
#     @writeHeaders [
#       'First name'
#       'Last name'
#       'Zip'
#       'City'
#     ]
#   .process (customer) ->
#     @writeRow [
#       customer.first_name
#       customer.last_name
#       customer.zip
#       customer.city
#     ]
# ```
#
# Based on excel4node (https://github.com/natergj/excel4node).
#
excel4node = require('excel4node')

ExcelWriterMixin = (onMixin) ->
  (target) ->
    # This mixin extends the `target` object. It add an `_excel` property and the methods below:
    target._excel = {}

    # Creates the workbook which is written to disk when the pump ends.
    target.createWorkbook = (path) ->
      throw new Error 'Workbook already created' if @_excel.workbook?
      @workbook new excel4node.WorkBook()
      @_excel.path = path

      @on 'end', =>
        @_excel.workbook.write @_excel.path

      @_excel.workbook

    # Set or get workbook
    target.workbook = (workbook = null) ->
      return @_excel.workbook if workbook == null
      @_excel.workbook = workbook
      @_excel.boldStyle = @_excel.workbook.Style()
      @_excel.boldStyle.Font.Bold()
      @

    # Create a new worksheet with given name. Any subsequent cell accessor methods (e.g.
    # `.writerHeader`, `.writeRow`) will write to the new worksheet.
    target.createWorksheet = (name) ->
      throw new Error 'Use createWorkbook before creating worksheet' if !@_excel.workbook?
      @_excel.worksheet = @_excel.workbook.WorkSheet(name)
      @_excel.currentRow = 1

    # Returns current worksheet.
    target.currentWorksheet = ->
      @_excel.worksheet

    # Writes header row. See usage example at the top.
    target.writeHeaders = (headers) ->
      throw new Error 'Use createWorksheet before writing headers' if !@_excel.worksheet?
      throw new Error 'Use writeHeaders before writing any rows to the worksheet' if @_excel.currentRow != 1
      @_writeHeader index, header for header, index in headers
      @_excel.currentRow = 2
      @

    target._writeHeader = (index, header) ->
      @_excel.worksheet.Cell(1, index + 1)
        .String(header)
        .Style(@_excel.boldStyle)

    # Writes a new row in the worksheet. See usage example at the top.
    target.writeRow = (columns) ->
      throw new Error 'Use createWorksheet before writing rows' if !@_excel.worksheet?
      @_excel.worksheet.Cell(@_excel.currentRow, index + 1).String(value) for value, index in columns
      @_excel.currentRow++

    onMixin.apply(target, [])

module.exports = ExcelWriterMixin
