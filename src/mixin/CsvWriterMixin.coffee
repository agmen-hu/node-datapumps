# CSV writer mixin for node-datapumps
#
# Usage:
#  * Require csv writer mixin:
#    ```coffee
#    { CsvWriterMixin } = require('datapumps/mixins')
#    ```
#
#  * Provide parameters for the mixin:
#
#    ```coffee
#    pump
#      .mixin CsvWriterMixin
#        path: 'test.csv'
#        headers: [ 'Name', 'Code' ]
#    ```
#
#  * Use `.writeRow` in the `.process` method of the pump to write a row in csv:
#
#    ```coffee
#    pump
#      .process (product) ->
#        pump.writeRow [ product.name, product.code ]
#    ```
#
# Complete example:
# ```coffee
# (customersCsv = new Pump)
#   .from <yoursource>
#   .mixin CsvWriterMixin
#     path: 'test.csv'
#     headers: [
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
csv = require 'fast-csv'
fs = require 'fs'
Promise = require 'bluebird'

CsvWriterMixin = (options) ->
  throw new Error 'path option is required.' if !options?.path

  (target) ->

    target.writeRow = (row) ->
      Promise.resolve target._csv.writer.write(row)

    target._csv = options
    target._csv.writer = csv.createWriteStream()
    target._csv.writer.pipe fs.createWriteStream target._csv.path, {encoding: 'utf8'}
    if target._csv.headers?
      target.writeRow target._csv.headers

    # Finishes writing the csv when the pump finishes.
    target.on 'end', ->
      target._csv.writer.write(null)

module.exports = CsvWriterMixin
