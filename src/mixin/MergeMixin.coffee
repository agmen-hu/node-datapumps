# Mixin to enable pump to read from multiple input buffers.
Pump = require '../Pump'
Buffer = require '../Buffer'

class MergeHelperPump extends Pump
  sealOutputBuffers: -> @emit 'sealOutput'

# Normally, `.from()` sets the input buffer or stream of the pump. When `MergeMixin` is added,
# `.from()` can be called multiple times and pump will read from all given buffers.
#
# Usage:
# ```coffee
# { MergeMixin } = require('datapumps/mixins')
# pump
#   .mixin MergeMixin
#   .from buffer1
#   .from buffer2
# ```
#
module.exports = MergeMixin = (pump) ->
  pump.from new Buffer()
  pump._fromBuffers = []

  pump.from = (buffer = null) ->
    return @_from if buffer == null

    if @_state == Pump.STARTED
      throw new Error 'Cannot change source buffer after pumping has been started'
    if buffer instanceof Buffer
      sourceBuffer = buffer
    else if buffer instanceof Pump
      sourceBuffer = buffer.buffer()
    else if buffer instanceof require('stream')
      sourceBuffer = new Buffer
        size: 1000
      buffer.on 'data', (data) => sourceBuffer.write data
      buffer.on 'end', => sourceBuffer.seal()
      buffer.on 'error', (err) => @writeError err
      sourceBuffer.on 'full', -> buffer.pause()
      sourceBuffer.on 'release', -> buffer.resume()
    else
      throw new Error 'Argument must be datapumps.Buffer or stream'

    @_fromBuffers.push sourceBuffer

    (helperPump = new MergeHelperPump())
      .from sourceBuffer
      .buffer 'output', @_from
      .process (data) ->
        @copy data

    helperPump
      .on 'sealOutput', ->
        allEnded = true
        for buffer in pump._fromBuffers
          allEnded = false if !buffer.isEnded()
        return if !allEnded

        pump._from.seal() if !pump._from.isSealed()
      .start()

    @
