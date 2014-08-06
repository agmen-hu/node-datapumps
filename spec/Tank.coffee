require('should')
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
