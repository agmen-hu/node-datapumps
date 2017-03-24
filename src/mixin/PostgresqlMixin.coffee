# Mixin to query and write data to postgresql.
#
# Please note that you don't need this mixin when you only want to read data from postgresql. Wrap the
# query in the QueryStream of `pg-query-stream`.
#
# Usage:
#  * Load the mixin:
#    ```coffee
#    { PostgresqlMixin } = require('datapumps/mixins')
#    ```
#
#  * Add the mixin and set the postgresql client:
#    ```coffee
#    pump
#      .mixin PostgresqlMixin postgresqlClient
#    ```
#
#  * Use `.query()` method of the pump in `.process()`
#    ```coffee
#    pump
#      .process (data) ->
#        @query 'INSERT INTO customer (name, address) VALUES ($1, $2)', [ data.name, data.address ]
#    ```
#    The method returns a promise, so
#    you can use it `.process()` callbacks (note that `.process()` callback must return a promise).
#
# Complete example: Copy data from one table to another
# ```coffee
# { Pump, mixin: { PostgresqlMixin } } = require('datapumps')
# QueryStream = require('pg-query-stream')
# Client = require('pg').Client
# postgresqlClient = new Client <your-connection-string>
#
# postgresqlCopy = new Pump
#   .from postgresqlClient.query(new QueryStream 'SELECT id,last_name,first_name FROM customer')
#   .mixin PostgresqlMixin postgresqlClient
#   .process (customer) ->
#     @query 'SELECT id FROM new_customer_table WHERE id = $1 ', p.id
#       .then ([ result, fields ]) =>
#         if result.length == 0
#           @query 'INSERT INTO new_customer_table
#             (id,last_name,first_name) VALUES ($1,$2,$3)',
#             [ customer.id, customer.last_name, customer.first_name ]
#         else
#           @query 'UPDATE new_customer_table
#             SET last_name=$1, first_name = $2
#             WHERE id=$3',
#             customer.last_name, customer.first_name, customer.id
# ```
#

postgresqlMixin = (client) ->
  if !client? or typeof(client?.query) != 'function'
    throw new Error 'Postgresql mixin requires client to be given'
  (target) ->
    target.query = (query, args...) ->
      if args?
        client.query(query, args)
      else
        client.query(query)

    target.selectOne = (query, args...) ->
      target.query(query, args)
        .then ([results, fields]) ->
          if results.length == 1
            results[0]
          else if results.length == 0
            throw new Error('Query returned no result')
          else
            throw new Error('Query returned more than one result')

module.exports = postgresqlMixin
