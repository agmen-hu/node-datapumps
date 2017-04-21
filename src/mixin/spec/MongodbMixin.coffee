require 'should'
sinon = require 'sinon'
MongodbMixin = require '../MongodbMixin'
Promise = require 'bluebird'
mongo = Promise.promisifyAll require 'mongodb'

describe 'MongodbMixin(db)', ->
  it 'should store db connection in target object', ->
    target = {}
    mixin = MongodbMixin({ foo: 'bar' })
    mixin target

    target._mongo.db.foo.should.equal 'bar'

  it 'should connect to mongo if db is a string', ->
    replacedConnectAsync = mongo.connectAsync
    mongo.connectAsync = sinon.stub().returns
      then: ->

    target = {}
    mixin = MongodbMixin 'mongodb://127.0.0.1:27017/test'
    mixin target

    mongo.connectAsync.calledOnce.should.be.true
    mongo.connectAsync = replacedConnectAsync

  it 'should wrap collection methods into pump', ->
    mockDb =
      collection: -> mockCollection
    mockCollection =
      find: sinon.stub().returns({ stream: -> })

    target = {}
    mixin = MongodbMixin(mockDb)
    mixin target

    target.useCollection 'foo'
    target.find 'test'

    mockCollection.find.calledOnce.should.be.true
    mockCollection.find.getCall(0).args[0].should.equal 'test'

  it 'should defer .find() calls until connection established', ->
    connectResolveCallbacks = []
    replacedConnectAsync = mongo.connectAsync
    mongo.connectAsync = sinon.stub().returns
      then: (cb) -> connectResolveCallbacks.push cb
      isPending: -> true
    mockDb =
      collection: ->
        mockCollection
    mockCollection =
      find: ->
        { stream: streamSpy }
    streamSpy = sinon.stub()
      .returns { pipe: -> }

    target =
      whenFinished: sinon.stub().returns then: ->
    mixin = MongodbMixin 'mongodb://127.0.0.1:27017/test'
    mixin target

    target.useCollection 'foo'
    target.find 'test'

    streamSpy.calledOnce.should.be.false
    connectResolveCallbacks.should.have.lengthOf 2
    connectResolveCallbacks[0](mockDb)
    connectResolveCallbacks[1](mockDb)
    streamSpy.calledOnce.should.be.true

    mongo.connectAsync = replacedConnectAsync

  it 'should defer .insert() calls until connection established', ->
    connectResolveCallbacks = []
    replacedConnectAsync = mongo.connectAsync
    mongo.connectAsync = sinon.stub().returns
      then: (cb) -> connectResolveCallbacks.push cb
      isPending: -> true
    mockDb =
      collection: ->
        mockCollection
    mockCollection =
      insertAsync: sinon.stub().returns { then: -> }

    target =
      whenFinished: sinon.stub().returns then: ->
    mixin = MongodbMixin 'mongodb://127.0.0.1:27017/test'
    mixin target

    target.useCollection 'foo'
    target.insert 'test'

    mockCollection.insertAsync.calledOnce.should.be.false
    connectResolveCallbacks.should.have.lengthOf 2
    connectResolveCallbacks[0](mockDb)
    connectResolveCallbacks[1](mockDb)
    mockCollection.insertAsync.calledOnce.should.be.true

    mongo.connectAsync = replacedConnectAsync
