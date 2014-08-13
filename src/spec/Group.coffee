require('should')
sinon = require('sinon')
Group = require('../Group')
Buffer = require('../Buffer')
Pump = require('../Pump')

describe 'Group', ->
  describe '#addPump(name)', ->
    it 'should add a pump to the group', ->
      group = new Group
      group.addPump 'test'
      group.pump('test').should.not.be.empty

    it 'should throw error when pump already exists', ->
      group = new Group
      group.addPump 'test'
      ( ->
        group.addPump 'test'
      ).should.throw 'Pump already exists'

    it 'should register "end" listener', ->
      group = new Group
      pump = new Pump
      sinon.spy pump, 'on'
      group.addPump 'test', pump

      pump.on.calledOnce.should.be.true
      pump.on.getCall(0).args[0].should.equal 'end'

  describe '#start()', ->
    it 'should start all pumps', ->
      group = new Group
      group.addPump 'foo'
        .from new Buffer
      group.addPump 'bar'
        .from group.pump('foo').buffer()

      sinon.spy group.pump('foo'), 'start'
      sinon.spy group.pump('bar'), 'start'

      group.start()

      group.pump('foo').start.calledOnce.should.be.true
      group.pump('bar').start.calledOnce.should.be.true

  it 'should emit end event when all pumps ended', (done) ->
    group = new Group
    source = new Buffer
    group.addPump 'foo'
      .from source
    group.addPump 'bar'
      .from group.pump('foo').buffer()

    group.on 'end', ->
      done()

    group.start()
    source.seal()

  describe '#whenFinished()', ->
    it 'should return a promise that fulfills when all pumps ended', (done) ->
      group = new Group
      source = new Buffer
      group.addPump 'foo'
        .from source
      group.addPump 'bar'
        .from group.pump('foo').buffer()

      group.whenFinished()
        .then -> done()

      group.start()
      source.seal()

  describe '#expose(exposedName, bufferPath)', ->
    it 'should expose a buffer of a pump as its own buffer', ->
      group = new Group
      group.addPump 'test'

      group.expose('foo', 'test/output')
      group.buffer('foo').should.equal group.pump('test').buffer('output')

    it 'should expose the default buffer of pump if not given in path', ->
      group = new Group
      group.addPump 'test'

      group.expose('foo', 'test')
      group.buffer('foo').should.equal group.pump('test').buffer('output')
