require('should')
sinon = require('sinon')
Pump = require('../src/Pump.coffee')

describe 'Pump', ->
  describe '#start()', ->
    it 'should pump content from source to output buffer', (done) ->
      buffer1 =
        content: [ 'foo', 'bar', 'test', 'content' ]
        on: ->
        isEmpty: ->
          buffer1.content.length == 0

        release: ->
          result = buffer1.content.shift()

        once: ->
          # we will arrive here after buffer1 is emptied
          pump.buffer('output').fill.getCall(0).args[0].should.equal 'foo'
          pump.buffer('output').fill.getCall(1).args[0].should.equal 'bar'
          pump.buffer('output').fill.getCall(2).args[0].should.equal 'test'
          pump.buffer('output').fill.getCall(3).args[0].should.equal 'content'
          done()

      pump = new Pump
      pump.from buffer1

      sinon.spy(pump.buffer(), 'fill')

      pump.start()

    it 'should not be possible to change source buffer after start', ->
      source =
        on: ->
        isEmpty: -> true
        once: ->

      pump = new Pump
      ( ->
        pump
          .from source
          .start()
          .from source
      ).should.throw 'Cannot change source buffer after pumping has been started'

    it 'should not be possible to change output buffer after start', ->
      source =
        on: ->
        isEmpty: -> true
        once: ->

      pump = new Pump
      ( ->
        pump
          .from source
          .start()
          .buffers { output: source }
      ).should.throw 'Cannot change output buffers after pumping has been started'


    describe 'when source buffer is empty', ->
      buffer1 =
        on: ->
        isEmpty: -> true
        release: -> 'test'

        once: sinon.spy (event, callback) -> buffer1.fillEventCallback = callback

      it 'should wait for fill event on source buffer', ->
        pump = new Pump
        pump
          .from buffer1
          .start()

        buffer1.once.calledOnce.should.be.true

      it 'should fill target buffer when fill event is triggered', (done) ->
        pump = new Pump

        pump.buffer().fillAsync = sinon.spy (data) ->
          data.should.equal "test"
          done()

        pump
          .from buffer1
          .start()

        buffer1.fillEventCallback()

  it 'should seal output buffers when source buffer ends', ->
    source =
      on: ->
      isEmpty: -> true
      callbacks: {}
      on: sinon.spy (event, callback) -> source.callbacks[event] = callback

    pump = new Pump
    pump.from source

    sinon.spy pump.buffer(), 'seal'
    do source.callbacks.end
    do pump.start
    pump.buffer().seal.calledOnce.should.be.true

  it 'should emit end event when all output buffers ended', ->
    source =
      on: ->
      isEmpty: -> true
      callbacks: {}
      on: sinon.spy (event, callback) -> source.callbacks[event] = callback

    pump = new Pump
    pump.from source

    sinon.spy pump.buffer(), 'seal'
    endSpy = sinon.spy()
    pump.on 'end', endSpy
    do source.callbacks.end
    do pump.start

    endSpy.calledOnce.should.be.true

  it 'should be able to transform the data', (done) ->
    buffer1 =
      content: [ 'foo', 'bar' ]
      on: ->
      isEmpty: ->
        buffer1.content.length == 0

      release: ->
        result = buffer1.content.shift()

      once: (event, cb) ->
        event.should.equal 'fill'
        pump.buffer().fill.getCall(0).args[0].should.equal 'foo!'
        pump.buffer().fill.getCall(1).args[0].should.equal 'bar!'
        done()

    pump = new Pump
    pump
      .from buffer1
      .process (data) ->
        @buffer().fillAsync data + '!'

    sinon.spy(pump.buffer(), 'fill')

    pump.start()
