# Mixin to interact with REST services.
#
# This mixin wraps and promisifies the restler library methods, like .get(), .post() or
# .del(). For more details about restler see https://github.com/danwrong/restler.
#
# It also adds `.fromRest` method to pump, which fills input buffer from results of a REST service
# query.
#
# Use case 1: filling pump from result of rest GET
# ```coffee
# { RestMixin } = require('datapumps/mixins')
# pump
#   .mixin RestMixin
#   .fromRest
#     query: -> @get 'http://someservice.io/api/v1/users'
#     resultMapping: (response) -> response.result.users
#   .process (user) ->
#     # ...
# ```
#
# `.fromRest()` has an object argument. The `query` key is required, it must be a callback function
# which returns a promise that fulfills when the query is completed and returns with the query
# results. The query results must be an array. Most of the times, `.get()` or `.post()` method will
# be sufficient combined with mapping of query results (`resultMapping` key).
#
# Use `resultMapping` key when you need to map a results of the REST service to an array. The value
# of the key should be a function that receives REST query result in the first argument and returns
# array to be filled in the input buffer.
#
# REST service may be paginated, you can query those like this:
# ```js
# pump
#   .mixin RestMixin
#   .fromRest
#     query: (nextPage) -> @get nextPage ? 'http://someservice.io/api/v1/users'
#     resultMapping: (response) -> response.result.users
#     nextPage: (response) -> response.result.paging.nextPage
# ```
# Only two things to note when using paginated REST service:
#  * `nextPage` key is a callback which may return anything other than undefined or null to continue
#    to next page.
#  * `query` will receive the return value of `nextPage` callback. It will receive undefined on the
#    first call.
#
# Use case 2: enriching content from result of rest GET
# ```coffee
# { RestMixin } = require('datapumps/mixins')
# pump
#   .mixin RestMixin
#   .process (data) =>
#     @get 'http://someservice.io/api/v1/user/' + data.username
#       .then (response) =>
#         data.email = response.result.email
#         @copy data
# ```
#
# Use case 3: output to a REST service
# ```coffee
# { RestMixin } = require('datapumps/mixins')
# pump
#   .mixin RestMixin
#   .process (data) ->
#     @post 'https://twaud.io/api/v1/upload.json',
#       multipart: true
#       username: 'danwrong'
#       password: 'wouldntyouliketoknow'
#       data:
#         'sound[message]': 'hello from restler!'
#         'sound[file]': @file('doug-e-fresh_the-show.mp3', null, 321567, null, 'audio/mpeg')
# ```
#
Promise = require 'bluebird'
restler = require 'restler'

module.exports = RestMixin = (target) ->
  _wrapMethod target, 'get'
  _wrapMethod target, 'post'
  _wrapMethod target, 'put'
  _wrapMethod target, 'del'
  _wrapMethod target, 'head'
  _wrapMethod target, 'patch'
  _wrapMethod target, 'json'
  _wrapMethod target, 'postJson'
  _wrapMethod target, 'putJson'
  target.file = ->
    restler.file.apply restler, arguments

  target.fromRest = (config) ->
    throw new Error 'query key is required' if !config?.query
    config.resultMapping ?= (result) -> result
    config.nextPage ?= -> undefined
    @from @createBuffer()
    queryAndWriteInputBuffer = (nextPage) =>
      config.query.apply @, [ nextPage ]
        .then (response) =>
          @from().writeArrayAsync(config.resultMapping(response))
            .done =>
              nextPage = config.nextPage(response)
              if (nextPage is undefined) or (nextPage is null)
                @from().seal()
              else
                queryAndWriteInputBuffer(nextPage)
    queryAndWriteInputBuffer(undefined)
    @

_wrapMethod = (target, methodName) ->
  target[methodName] = ->
    methodArgs = arguments
    new Promise (resolve, reject) ->
      restler[methodName].apply(restler, methodArgs)
        .on 'complete', (result, response) ->
          if result instanceof Error
            reject result
          else
            response.result = result
            resolve response
