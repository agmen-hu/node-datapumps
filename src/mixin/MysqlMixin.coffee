# Mixin to query and write data to mysql.
#
# Please note that you don't need this mixin when you only want to read data from mysql. Use the
# `.stream()` method of connection query.
#
# Usage:
#  * Load the mixin:
#    ```coffee
#    { MysqlMixin } = require('datapumps/mixins')
#    ```
#
#  * Add the mixin and set the mysql connection:
#    ```coffee
#    pump
#      .mixin MysqlMixin myMysqlConnection
#    ```
#
#  * Use `.query()` method of the pump in `.process()`
#    ```coffee
#    pump
#      .process (data) ->
#        @query 'INSERT INTO customer (name, address) VALUES (?)', [ data.name, data.address ]
#    ```
#    The method returns a promise (it is the promisified version of `connection.query()`), so
#    you can use it `.process()` callbacks (note that `.process()` callback must return a promise).
#
#  * Use `.escape(value)` to escape value when query is built by concatenating strings
#    ```coffee
#    pump
#      .process (data) ->
#        @query 'INSERT INTO customer (name) VALUES (#{@escape(data.name)})'
#    ```
#
# Complete example: Copy data from one table to another
# ```coffee
# { Pump, mixin: { MysqlMixin } } = require('datapumps')
# mysqlConnection = require('mysql').createConnection <your-connection-string>
#
# mysqlCopy = new Pump
#   .from mysqlConnection.query('SELECT id,last_name,first_name FROM customer').stream()
#   .mixin MysqlMixin mysqlConnection
#   .process (customer) ->
#     @query 'SELECT id FROM new_customer_table WHERE id = ? ', p.id
#       .then ([ result, fields ]) =>
#         if result.length == 0
#           @query 'INSERT INTO new_customer_table
#             (id,last_name,first_name) VALUES (?)',
#             [ customer.id, customer.last_name, customer.first_name ]
#         else
#           @query 'UPDATE new_customer_table
#             SET last_name=?, first_name = ?
#             WHERE id=?',
#             customer.last_name, customer.first_name, customer.id
# ```
#
Promise = require('bluebird')

mysqlMixin = (connection) ->
  if !connection? or typeof(connection?.query) != 'function'
    throw new Error 'Mysql mixin requires connection to be given'
  (target) ->
    target._mysql =
      connection: connection
      query: Promise.promisify connection.query, connection

    target.query = (query, args...) ->
      if args?
        @_mysql.query(query, args)
      else
        @_mysql.query(query)

    target.selectOne = (query, args...) ->
      target.query(query, args)
        .then ([results, fields]) ->
          if results.length == 1
            results[0]
          else if results.length == 0
            throw new Error('Query returned no result')
          else
            throw new Error('Query returned more than one result')

    target.escape = (value) ->
      @_mysql.connection.escape value

module.exports = mysqlMixin
