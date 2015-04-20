(function() {
  module.exports = function(pump) {
    var clearBufferStats, collectBuffers, delay, dumpStats, dumpStatsIfNotEnded, hadTraffic, listenToBuffersEvents, monitorBuffers, _bufferStats, _start;
    if ('_bufferDebugMixin' in pump) {
      return;
    }
    _start = pump.start;
    _bufferStats = {};
    pump._bufferDebugMixin = {
      version: 1
    };
    pump.start = function() {
      _start.call(pump);
      if (this._debug !== true) {
        return this;
      }
      collectBuffers();
      listenToBuffersEvents();
      monitorBuffers();
      pump.whenFinished().then(function() {
        return dumpStats();
      });
      return this;
    };
    collectBuffers = function() {
      var buffer, name, _ref;
      _bufferStats = {
        input: {
          buffer: pump.from()
        }
      };
      _ref = pump.buffers();
      for (name in _ref) {
        buffer = _ref[name];
        _bufferStats[name] = {
          buffer: buffer
        };
      }
      return clearBufferStats();
    };
    clearBufferStats = function() {
      var buffer, name, _results;
      _results = [];
      for (name in _bufferStats) {
        buffer = _bufferStats[name];
        buffer.releases = 0;
        _results.push(buffer.writes = 0);
      }
      return _results;
    };
    listenToBuffersEvents = function() {
      var buffer, name, _results;
      _results = [];
      for (name in _bufferStats) {
        buffer = _bufferStats[name];
        _results.push((function(buffer) {
          buffer.buffer.on('write', function() {
            return buffer.writes++;
          });
          return buffer.buffer.on('release', function() {
            return buffer.releases++;
          });
        })(buffer));
      }
      return _results;
    };
    monitorBuffers = function() {
      return delay(1000, function() {
        dumpStatsIfNotEnded();
        clearBufferStats();
        if (!pump.isEnded()) {
          return monitorBuffers();
        }
      });
    };
    delay = function(ms, func) {
      return setTimeout(func, ms);
    };
    dumpStatsIfNotEnded = function() {
      if (pump.isEnded()) {
        return;
      }
      return dumpStats();
    };
    dumpStats = function() {
      var buffer, name, _ref;
      if (!hadTraffic()) {
        return;
      }
      process.stdout.write("" + ((new Date()).toISOString()) + " [" + ((_ref = pump.id()) != null ? _ref : '(root)') + "] ");
      for (name in _bufferStats) {
        buffer = _bufferStats[name];
        process.stdout.write("" + name + ": " + (buffer.buffer.getContent().length) + " items, " + buffer.writes + " in, " + buffer.releases + " out | ");
      }
      return process.stdout.write("\n");
    };
    return hadTraffic = function() {
      var buffer, name;
      for (name in _bufferStats) {
        buffer = _bufferStats[name];
        if (buffer.releases > 0 || buffer.writes > 0) {
          return true;
        }
      }
      return false;
    };
  };

}).call(this);
