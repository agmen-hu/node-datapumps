# Mongo mixin for datapumps
#
# Usage:
#  * Load the mixin:
#    ```coffee
#    { mixin: { MongodbMixin } } = require 'datapumps'
#    ```
#
#  * Provide a db url or a db object to the mixin:
#
#    ```coffee
#    pump
#      .mixin MongodbMixin 'mongodb://127.0.0.1:27017/test' # or mongodb.Db object
#    ```
#
#  * Use `.useCollection()` to wrap mongodb.Collection methods into pump and write to mongo:
#
#    ```coffee
#    pump
#      .useCollection 'products'
#      .process (product) ->
#        pump.insert { name: product.name, code: product.code }
#    ```
#    Methods of the collection (like insert, update, remove, find) will be mixed into the pump
#
#    Note that the wrapped methods are promisified, so you cannot provide a callback.
#
#  * Or read from mongo:
#
#    ```coffee
#    pump
#      .useCollection 'posts'
#      .from pump.find(...)
#    ```
#
#
Promise = require 'bluebird'
mongo = Promise.promisifyAll require 'mongodb'
{ PassThrough } = require 'stream'

module.exports = (db) ->
  (target) ->
    target._mongo =
      db: db

    if typeof db == 'string'
      (target._mongo.whenConnected = mongo.MongoClient.connectAsync db)
        .then (db) ->
          target._mongo.db = db
          target.whenFinished().then -> target._mongo.db.close()
          if target._mongo?.collection?._datapumpsMixinName?
            target._mongo.collection = db.collection target._mongo.collection._datapumpsMixinName

    _wrapMethod target, name for name in _wrappedMethods
    _wrapFind target

    target.db = ->
      @_mongo.db

    # Use the given collection in the pump. The promisified methods of the collection will be proxied
    # from the pump, i.e. when you call .find() on the pump, it will call .find() on the collection.
    target.useCollection = (name) ->
      if target._mongo.whenConnected? and target._mongo?.whenConnected.isPending()
        @_mongo.collection =
          _datapumpsMixinName: name
        _deferCollectionMethod @_mongo.collection, name + 'Async', @ for name in _wrappedMethods
        _deferFind @_mongo.collection, @
      else
        @_mongo.collection = @_mongo.db.collection name
      @

    # Returns a collection from the mongo database. Does not work until the connection established.
    target.collection = (name) ->
      throw new Error('Not yet connected to mongo') if target._mongo?.whenConnected.isPending()
      @_mongo.db.collection name

_wrappedMethods = [ 'insert', 'remove', 'rename', 'save', 'update', 'count', 'drop', 'findOne',
  'createIndex', 'ensureIndex', 'dropIndex', 'reIndex', 'group', 'options', 'indexes', 'stats',
  'findAndModify', 'findAndRemove' ]

_wrapMethod = (target, name) ->
  target[name] = (args...) ->
    throw new Error 'Collection is not set. Use .useCollection before using this wrapper' if !@_mongo.collection?
    throw new Error "Method .#{name}Async() does not exist in collection." if !@_mongo.collection[name + 'Async']
    @_mongo.collection[name + 'Async'].apply(@_mongo.collection, args)

_wrapFind = (target) ->
  target.find = (args...) ->
    throw new Error 'Collection is not set. Use .useCollection before using this wrapper' if !@_mongo.collection?
    throw new Error "Method .find() does not exist in collection." if !@_mongo.collection.find
    @_mongo.collection.find.apply(@_mongo.collection, args).stream()

_deferCollectionMethod = (collection, name, target) ->
  collection[name] = (args...)->
    target._mongo.whenConnected.then ->
      throw new Error "Method .#{name} does not exist in collection." if !target._mongo.collection[name]
      target._mongo.collection[name].apply(target._mongo.collection, args)

_deferFind = (collection, target) ->
  collection.find = (args...) ->
    result = new PassThrough
      objectMode: true
      highWaterMark: 10

    target._mongo.whenConnected.then ->
      target._mongo.collection.find.apply(target._mongo.collection, args).stream().pipe result

    { stream: -> result }
