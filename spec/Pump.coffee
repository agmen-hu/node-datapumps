require('should')
sinon = require('sinon')
Pump = require('../src/Pump.coffee')

describe 'Pump', ->
  describe '#start()', ->
    it 'should pump content from source to output tank', (done) ->
      tank1 =
        content: [ 'foo', 'bar', 'test', 'content' ]
        on: ->
        isEmpty: ->
          tank1.content.length == 0

        release: ->
          result = tank1.content.shift()

        once: ->
          # we will arrive here after tank1 is emptied
          pump.tank('output').fill.getCall(0).args[0].should.equal 'foo'
          pump.tank('output').fill.getCall(1).args[0].should.equal 'bar'
          pump.tank('output').fill.getCall(2).args[0].should.equal 'test'
          pump.tank('output').fill.getCall(3).args[0].should.equal 'content'
          done()

      pump = new Pump
      pump.from tank1

      sinon.spy(pump.tank(), 'fill')

      pump.start()

    describe 'when source tank is empty', ->
      tank1 =
        on: ->
        isEmpty: -> true
        release: -> 'test'

        once: sinon.spy (event, callback) -> tank1.fillEventCallback = callback

      pump = new Pump

      it 'should wait for fill event on source tank', ->
        pump
          .from tank1
          .start()

        tank1.once.calledOnce.should.be.true

      it 'should fill target tank when fill event is triggered', (done) ->
        pump.tank().fillAsync = sinon.spy (data) ->
          data.should.equal "test"
          done()

        pump
          .from tank1
          .start()

        tank1.fillEventCallback()

  xit 'should seal target tank when source tank ends if not specified otherwise', ->
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

  it 'should be able to transform the data', (done) ->
    tank1 =
      content: [ 'foo', 'bar' ]
      on: ->
      isEmpty: ->
        tank1.content.length == 0

      release: ->
        result = tank1.content.shift()

      once: (event, cb) ->
        event.should.equal 'fill'
        pump.tank().fill.getCall(0).args[0].should.equal 'foo!'
        pump.tank().fill.getCall(1).args[0].should.equal 'bar!'
        done()

    pump = new Pump
    pump
      .from tank1
      .process (data) ->
        @tank().fillAsync data + '!'

    sinon.spy(pump.tank(), 'fill')

    pump.start()
