
module.exports = (pump) ->
  return if '_bufferDebugMixin' of pump

  _start = pump.start
  _bufferStats = {}

  pump._bufferDebugMixin =
    version: 1

  pump.start = ->
    _start.call pump
    return @ if @_debug != true

    collectBuffers()
    listenToBuffersEvents()
    monitorBuffers()
    @

  collectBuffers = ->
    _bufferStats = { input: { buffer: pump.from() } }
    _bufferStats[name] = { buffer: buffer } for name, buffer of pump.buffers()
    clearBufferStats()

  clearBufferStats = ->
    for name, buffer of _bufferStats
      buffer.releases = 0
      buffer.writes = 0

  listenToBuffersEvents = ->
    for name, buffer of _bufferStats
      do (buffer) ->
        buffer.buffer.on 'write', -> buffer.writes++
        buffer.buffer.on 'release', -> buffer.releases++

  monitorBuffers = ->
    delay 1000, ->
      dumpStats()
      clearBufferStats()
      monitorBuffers() if !pump.isEnded()

  delay = (ms, func) -> setTimeout func, ms

  dumpStats = ->
    return if !hadTraffic()

    process.stdout.write "[#{pump.id() ? '(root)'}] "
    for name, buffer of _bufferStats
      process.stdout.write "#{name}: #{buffer.buffer.getContent().length} items, #{buffer.writes} in, #{buffer.releases} out | "
    process.stdout.write "\n"

  hadTraffic =  ->
    for name, buffer of _bufferStats
      return true if buffer.releases > 0 or buffer.writes > 0
    false
