Promise = require('bluebird')

mysqlMixin = (connection) ->
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
        .then (results) ->
          if results.length == 1
            Promise.resolve(results[0])
          else if results.length == 0
            Promise.reject('Query returned no result')
          else
            Promise.reject('Query returned more than one result')

module.exports = mysqlMixin
