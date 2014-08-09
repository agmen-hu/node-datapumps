require('should')
Promise = require('bluebird')
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
      ( ->
        tank.fill('again')
      ).should.throw 'Tank is full'

    it 'should emit full event when the tank becomes full', (done) ->
      tank = new Tank
        size: 2

      tank.fill('test')
      tank.on 'full', ->
        done()

      tank.fill('test')

  describe '#fillAsync(data)', ->
    it 'should fill tank when not full', (done) ->
      tank = new Tank

      tank.fillAsync 'test'
        .then ->
          tank.getContent().should.eql [ 'test' ]
          do done

    it 'should wait for a release event to fill the tank', (done) ->
      tank = new Tank
        size: 1

      tank.fill('test')
      tank.fillAsync 'test2'
        .then ->
          tank.getContent().should.eql [ 'test2' ]
          do done

      do tank.release

    it 'should return a promise', ->
      tank = new Tank

      promise = tank.fillAsync 'test'
      promise.should.be.an.instanceOf(Promise)

  describe '#release()', ->
    it 'should return first data item when not empty', ->
      tank = new Tank

      tank.fill 'test1'
      tank.fill 'test2'
      tank.release().should.equal 'test1'

    it 'should throw error when tank is empty', ->
      tank = new Tank

      ( ->
        tank.release()
      ).should.throw 'Tank is empty'

  describe 'having a drain option', ->
    it 'should not have size option specified', ->
      ( ->
        new Tank
          drain: (data, cb) ->
          size: 5
      ).should.throw 'Cannot specify size option for a tank with drain option'

    it 'should not be able to release data manually', ->
      tank = new Tank
        drain: (data, cb) ->
          do cb

      ( ->
        do tank.release
      ).should.throw 'Content is automatically released through the callback given in drain option'

    it 'should release any filled item using the promisifiable drain function', (done) ->
      tank = new Tank
        drain: (data, cb) ->
          do cb

      tank.on 'empty', ->
        do done

      tank.fill 'test'

  describe 'that is sealed', ->
    it 'should throw error when trying to fill it', ->
      tank = new Tank
      tank.fill 'test'

      do tank.seal
      ( ->
        tank.fill 'test2'
      ).should.throw 'Cannot fill sealed tanks'

    it 'should emit end event if becomes empty when sealed', (done) ->
      tank = new Tank
      tank.fill 'test'

      tank.on 'end', ->
        do done

      do tank.seal
      do tank.release

    it 'should emit end event if sealed when empty', (done) ->
      tank = new Tank

      tank.on 'end', ->
        do done

      do tank.seal
