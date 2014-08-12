# Performance test for pumping 10million data items from one buffer to another.
#
# To run this test, type in terminal:
# ```shell
# mocha --compilers coffee:coffee-script/register perftest/pump10m.coffee
# ```
#
Pump = require('../src/Pump.coffee')
Buffer = require('../src/Buffer.coffee')

describe 'Pump (performance test)', ->
  it 'should be able to pump 10 million items from one buffer to another', (done) ->
    @timeout 200000

    created = 0
    pumped = 0
    limit = 10000000

    source = new Buffer
      size: 10000

    pump = new Pump
    pump
      .from source
      .process (data) ->
        pumped++
        if !(pumped % 1000000)
          console.log 'Pumped ' + (pumped / 1000000) + ' million items'
        @buffer().writeAsync data

    pump.on 'end', ->
      if pumped == limit && created == limit
        do done
      else
        throw new Error('Pump failed')

    write = ->
      source.write
        message: 'test data'
        foo: 'bar'
      ++created

    while !source.isFull()
      do write

    source.on 'release', ->
      do write if created < limit

    source.on 'empty', ->
      do source.seal

    pump.buffer().on 'write', ->
      pump.buffer().read()

    do pump.start
