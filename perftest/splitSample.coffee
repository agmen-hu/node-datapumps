#
# This is perftest requires a local mysql database named testdb, with a customers table having
# at least columns: first_name, last_name, postal_code, city.
#
# The test will write a contents of customer table (at most 10000 rows) in a csv and an xlsx file.
#
{
  group,
  mixin: { MysqlMixin, ExcelWriterMixin, CsvWriterMixin }
} = require('../index')

mysqlConnection = require('mysql').createConnection
  host: 'localhost'
  user: 'root'
  database: 'testdb'

exporter = group();

exporter.addPump('customers')
  .from mysqlConnection.query('SELECT * FROM customer LIMIT 10000').stream {highWaterMark: 5}
  .buffers
    excel: exporter.createBuffer()
    csv: exporter.createBuffer()
  .process (data) ->
    @buffer('excel').writeAsync data
    @buffer('csv').writeAsync data

exporter.addPump('excelWriter')
  .from exporter.pump('customers').buffer('excel')
  .mixin ExcelWriterMixin ->
    @createWorkbook 'test.xlsx'
    @createWorksheet 'Customers'
    @writeHeaders [
      'First name'
      'Last name'
      'Zip'
      'City'
    ]
  .process (customer) ->
    @writeRow [
      customer.first_name || ''
      customer.last_name || ''
      customer.postal_code || ''
      customer.city || ''
    ]

exporter.addPump('csvWriter')
  .from exporter.pump('customers').buffer('csv')
  .mixin CsvWriterMixin
    path: 'test.csv'
    headers: [
      'First name'
      'Last name'
      'Zip'
      'City'
    ]
  .process (customer) ->
    @writeRow [
      customer.first_name
      customer.last_name
      customer.postal_code
      customer.city
    ]

exporter
  .start()
  .whenFinished().then ->
    mysqlConnection.destroy()
    console.log 'Exporter done'
