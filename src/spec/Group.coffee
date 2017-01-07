require('should')
sinon = require('sinon')
Group = require('../Group')
Buffer = require('../Buffer')
Pump = require('../Pump')
Promise = require('bluebird')

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

    it 'should set the id of the added pump when group has id', ->
      group = new Group
      pump = new Pump
      group
        .id 'group'
        .addPump 'test', pump

      pump.id().should.equal 'group/test'

    it 'should set the id of the added pump when group does not have id', ->
      group = new Group
      pump = new Pump
      group.addPump 'test', pump

      pump.id().should.equal 'test'

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

    it 'should set error buffer for all pumps', ->
      group = new Group
      group.addPump 'foo'
        .from new Buffer
      group.addPump 'bar'
        .from group.pump('foo').buffer()

      group.start()
      group.errorBuffer().should.equal group.pump('foo').errorBuffer()
      group.errorBuffer().should.equal group.pump('bar').errorBuffer()

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

  describe '#inputPump(pumpName)', ->
    it 'should throw error when nonexistent name is set', ->
      group = new Group
      ( ->
        group.inputPump 'test'
      ).should.throw 'Pump test does not exist'

  describe '#from(buffer)', ->
    it 'should call .from on pump configured in .inputPump', ->
      group = new Group
      group.addInputPump 'test'
      buffer = new Buffer
      sinon.spy group.pump('test'), 'from'
      group.from buffer
      group.pump('test').from.calledOnce.should.be.true
      group.pump('test').from.getCall(0).args[0].should.equal buffer

    it 'should throw error when input pump is not configured', ->
      group = new Group
      ( ->
        group.from 'foo'
      ).should.throw 'Input pump is not set, use .inputPump to set it'

  it 'should emit error event when errorBuffer is full', (done) ->
    group = new Group

    buffer = new Buffer
      size: 1
    group
      .errorBuffer buffer
      .start()

    group.on 'error', ->
      done()
    buffer.write 'test'

  describe '#pause()', ->
    it 'should pause all pumps that has started state', ->
      group = new Group
      group.addPump 'test'
        .from new Buffer
      group.addPump 'test2'
        .from group.buffer 'test'
      group.addPump 'test3'
        .from group.buffer 'test2'
      group.run = ->
        @runPumps [ 'test', 'test2' ]

      group.start()
      group.pause()

      group.pump('test').isPaused().should.be.true;
      group.pump('test2').isPaused().should.be.true;
      group.pump('test3').isStopped().should.be.true;

  describe '#buffer(name)', ->
    it 'should accept buffer path for name (i.e. pumpName/bufferName)', ->
      group = new Group
      group.addPump 'test'
      group.buffer 'test/output'
        .should.equal group.pump('test').buffer('output')
      group.buffer 'test'
        .should.equal group.pump('test').buffer()

  describe '#runPumps(pumpNames)', ->
    it 'should return a promise that resolves when all pumps has been finished', (done) ->
      group = new Group
      group.addPump 'test1'
        .from new Buffer
      group.addPump 'test2'
        .from group.buffer 'test1'
      group.addPump 'test3'
        .from group.buffer 'test2'

      group.runPumps [ 'test1', 'test2']
        .then ->
          done()

      group.pump('test1').from().seal()
      group.pump('test2').from().seal()

  describe '#id()', ->
    it 'should update the ids of all pumps in the group', ->
      group = new Group
      group.addPump 'test'
      group.id 'group'

      group.pump('test').id().should.equal 'group/test'

  it 'should abort pumps when error buffer is full', (done) ->
    class G1 extends Group
      constructor: (buffer) ->
        super()
        @errorBuffer buffer
        @addPump 'p1'
          .from [ 1, 2, 3 ]
        @addPump 'p2'
          .from @pump 'p1'
          .process (item) ->
            console.log item
            throw new Error item
            Promise.resolve console.log item

    class G2 extends Group
      constructor: (buffer) ->
        super()
        @errorBuffer buffer
        @addPump 'g1', new G1 buffer
        @addPump 'x'
          .from [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
          .process ->
            Promise.delay 300

    g2 = new G2 new Buffer size: 1
    g2.start().whenFinished()
      .catch (err) ->
        done() if err.message is 'Pumping failed. See .errorBuffer() contents for error messages'
