require('should')
sinon = require('sinon')
Pump = require('../src/Pump.coffee')

describe 'Pump', ->
  describe '#start()', ->
    it 'should pump content from source to target tank', (done) ->
      tank1 =
        content: [ 'foo', 'bar', 'test', 'content' ]
        on: ->
        isEmpty: ->
          tank1.content.length == 0

        release: ->
          result = tank1.content.shift()

        once: ->
          # we will arrive here after tank1 is emptied
          tank2.fill.getCall(0).args[0].should.equal 'foo'
          tank2.fill.getCall(1).args[0].should.equal 'bar'
          tank2.fill.getCall(2).args[0].should.equal 'test'
          tank2.fill.getCall(3).args[0].should.equal 'content'
          done()

      tank2 =
        isFull: -> false
        fill: sinon.spy()

      pump = new Pump
        from: tank1
        to: tank2

      pump.start()

    describe 'when source tank is empty', ->
      tank1 =
        on: ->
        isEmpty: -> true
        release: -> 'test'

        once: sinon.spy (event, callback) -> tank1.fillEventCallback = callback

      tank2 =
        isFull: -> false
        fill: ->

      it 'should wait for fill event on source tank', ->
        pump = new Pump
          from: tank1
          to: tank2

        pump.start()

        tank1.once.calledOnce.should.be.true

      it 'should fill target tank when fill event is triggered', (done) ->
        tank2.fill = sinon.spy (data) ->
          data.should.equal "test"
          done()

        pump = new Pump
          from: tank1
          to: tank2

        pump.start()
        tank1.fillEventCallback()

    describe 'when target tank is full', ->
      tank1 =
        on: ->
        content: [ 'test' ]
        isEmpty: ->
          tank1.content.length == 0
        release: ->
          result = tank1.content.shift()
        once: ->

      tank2 =
        isFull: -> true
        fill: sinon.spy()

      it 'should wait for release event on target tank', (done) ->
        tank2.once = sinon.spy ->
          done()

        pump = new Pump
          from: tank1
          to: tank2

        pump.start()

      it 'should fill target tank when release event is triggered', (done) ->
        tank1.content = [ 'test' ]
        tank2.once = sinon.spy (event, callback) ->
          callback()

        tank2.fill = sinon.spy (data) ->
          data.should.equal "test"
          done()

        pump = new Pump
          from: tank1
          to: tank2

        pump.start()

  it 'should seal target tank when source tank ends if not specified otherwise', ->
    tank1 =
      isEmpty: -> true
      release: -> 'test'

      on: sinon.spy (event, callback) -> tank1.eventCallback = callback

    tank2 =
      isSealed: -> false
      seal: sinon.spy()

    pump = new Pump
      from: tank1
      to: tank2

    do tank1.eventCallback
    tank2.seal.calledOnce.should.be.true
