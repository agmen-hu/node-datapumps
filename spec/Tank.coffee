require('should')
sinon = require('sinon')
Tank = require('../src/Tank.coffee')

describe 'Tank', ->
  it 'should be empty when created', ->
    tank = new Tank
    tank.isEmpty().should.be.true

  describe '#fill(data)', ->
    it 'should add the data to the tank', ->
      tank = new Tank
      tank.fill('test')
      tank.getContent().should.eql [ 'test' ]

    it 'should throw error when the tank is full', ->
      tank = new Tank
        size: 1
      tank.fill('test')
      callFillAgain = ->
        tank.fill('again')
      callFillAgain.should.throw 'Tank is full'

    it 'should emit full event when the tank becomes full', (done) ->
      tank = new Tank
        size: 2

      tank.fill('test')
      tank.on 'full', ->
        done()

      tank.fill('test')

  describe '#release()', ->
    it 'should return first data item when not empty', ->
      tank = new Tank

      tank.fill 'test1'
      tank.fill 'test2'
      tank.release().should.equal 'test1'

    it 'should throw error when tank is empty', ->
      tank = new Tank

      callRelease = ->
        tank.release()
      callRelease.should.throw 'Tank is empty'

  describe 'having a drain option', ->
    it 'should not have size option specified', ->
      invalidInstantiation = ->
        new Tank
          drain: (data, cb) ->
          size: 5

      invalidInstantiation.should.throw 'Cannot specify size option for a tank with drain option'

    it 'should not be able to release data manually', ->
      tank = new Tank
        drain: (data, cb) ->
          do cb

      invalidCall = ->
        do tank.release

      invalidCall.should.throw 'Content is automatically released through the callback given in drain option'

    it 'should release any filled item using the promisifiable drain function', (done) ->
      tank = new Tank
        drain: (data, cb) ->
          do cb

      tank.on 'empty', ->
        do done

      tank.fill 'test'

  describe 'having pumpFrom', ->
    it 'should create a pump that pumps from specified tank', (done) ->
      source = new Tank
        content: [ 'test' ]

      tank = new Tank
        pumpFrom: source

      tank.once 'fill', ->
        tank.content.should.eql [ 'test' ]
        do done

  describe 'having fillFromStream', ->
    { PassThrough } = require 'stream'

    it 'should fill the tank from the stream', ->
      stream = new PassThrough
        objectMode: true

      tank = new Tank
        fillFromStream: stream

      stream.write({ foo: 'bar' })
      tank.getContent().should.eql [{foo: 'bar'}]

    it 'should pause the stream when the tank is full', ->
      stream = new PassThrough
        objectMode: true

      tank = new Tank
        fillFromStream: stream
        size: 1

      sinon.spy stream, 'pause'

      stream.write('test')

      stream.pause.calledOnce.should.be.true

    it 'should resume the stream when a data is released from the tank', ->
      stream = new PassThrough
        objectMode: true

      tank = new Tank
        fillFromStream: stream
        size: 1

      sinon.spy stream, 'resume'

      stream.write('test')
      do tank.release

      stream.resume.calledOnce.should.be.true
