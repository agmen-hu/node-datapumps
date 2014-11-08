# Mixin that makes pump process its input in batches
#
# This mixin adds `.processBatch` method, which enables configuration of batch processing
# callback. The callback receives the array of items in the batch and must return a promise
# when the batch is fully processed.
#
# Usage example: insert into mysql in batches
# ```coffee
# { BatchMixin, MysqlMixin } = require('datapumps/mixins')
# pump
#   .mixin BatchMixin
#   .mixin MysqlMixin mysqlConnection
#   .processBatch (users) ->
#      query = 'INSERT INTO user (name, email) VALUES '
#      query += users.map (user) =>
#          "(#{@escape(user.name)}, #{@escape(user.email)})"
#        .join(',')
#
#      @query query
# ```
#
# The default batch size is 100 items. It is possible to set or get the batch size using
# `.batchSize()` method:
# ```coffee
# pump.batchSize() # returns 100
# pump.batchSize(10000) # chainable setter to batch size
# pump.batchSize() # return 10000
# ```
#
Promise = require 'bluebird'

module.exports = BatchProcessMixin = (target) ->
  target._batchSize = 100
  target._batch = []

  target.batchSize = (size) ->
    return @_batchSize if !size?
    @_batchSize = size
    @

  target.processBatch = (fn) ->
    throw new Error('processBatch argument must be a function') if typeof fn != 'function'
    @_processBatch = fn
    @

  target._process = (data) ->
    @_batch.push data

    if @_batch.length >= @_batchSize
      result = @_processBatch(@_batch)
      @_batch = []
      result

  pumpMethod = target._pump
  target._pump = ->
    if @_from.isEnded()
      if @_batch.length > 0
        Promise.resolve(@_processBatch(@_batch))
          .then => @sealOutputBuffers()
      else
        @sealOutputBuffers()
      @_batch = []
      return

    pumpMethod.apply target, []
