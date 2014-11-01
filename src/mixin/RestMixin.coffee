# Mixin to interact with REST services.
#
# This mixin wraps and promisifies the restler library methods, like .get(), .post() or
# .del(). For more details about restler see https://github.com/danwrong/restler.
#
# Use case 1: filling pump from result of rest GET
# ```coffee
# { RestMixin } = require('datapumps/mixins')
# pump
#   .mixin RestMixin
#   .from pump.createBuffer()
#   .get 'http://someservice.io/api/v1/users'
#     .then (users) =>
#       pump.from().write user for user in users
#       # call .get to read more, seal the input buffer otherwise.
#       pump.from().seal()
# pump
#   .process (user) ->
#     # ...
# ```
#
# Use case 2: enriching content from result of rest GET
# ```coffee
# { RestMixin } = require('datapumps/mixins')
# pump
#   .mixin RestMixin
#   .process (data) =>
#     @get 'http://someservice.io/api/v1/user/' + data.username
#       .then (user) =>
#         data.email = user.email
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

_wrapMethod = (target, methodName) ->
  target[methodName] = ->
    methodArgs = arguments
    new Promise (resolve, reject) ->
      restler[methodName].apply(restler, methodArgs)
        .on 'complete', (result) ->
          if result instanceof Error
            reject result
          else
            resolve result
