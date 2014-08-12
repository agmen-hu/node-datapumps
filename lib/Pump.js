(function() {
  var Buffer, EventEmitter, Promise, Pump,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Promise = require('bluebird');

  Buffer = require('./Buffer');

  Pump = (function(_super) {
    __extends(Pump, _super);

    Pump.STOPPED = 0;

    Pump.STARTED = 1;

    Pump.SOURCE_ENDED = 2;

    Pump.ENDED = 3;

    function Pump(options) {
      this._state = Pump.STOPPED;
      this._from = null;
      this.buffers({
        output: new Buffer
      });
    }

    Pump.prototype.from = function(buffer) {
      if (buffer == null) {
        buffer = null;
      }
      if (buffer === null) {
        return this._from;
      }
      if (this._state === Pump.STARTED) {
        throw new Error('Cannot change source buffer after pumping has been started');
      }
      if (buffer instanceof Buffer) {
        this._from = buffer;
      } else {
        this._from = new Buffer({
          size: 1000
        });
        buffer.on('data', (function(_this) {
          return function(data) {
            return _this._from.write(data);
          };
        })(this));
        buffer.on('end', (function(_this) {
          return function() {
            return _this._from.seal();
          };
        })(this));
        this._from.on('full', function() {
          return buffer.pause();
        });
        this._from.on('release', function() {
          return buffer.resume();
        });
      }
      this._from.on('end', (function(_this) {
        return function() {
          return _this.sourceEnded();
        };
      })(this));
      return this;
    };

    Pump.prototype.sourceEnded = function() {
      if (this.currentRead) {
        this.currentRead.cancel();
      }
      return this._state = Pump.SOURCE_ENDED;
    };

    Pump.prototype.buffers = function(buffers) {
      if (buffers == null) {
        buffers = null;
      }
      if (buffers === null) {
        return this._buffers;
      }
      if (this._state === Pump.STARTED) {
        throw new Error('Cannot change output buffers after pumping has been started');
      }
      this._buffers = buffers;
      return this;
    };

    Pump.prototype.buffer = function(name) {
      if (name == null) {
        name = 'output';
      }
      if (!this._buffers[name]) {
        throw new Error("No such buffer: " + name);
      }
      return this._buffers[name];
    };

    Pump.prototype.start = function() {
      if (!this._from) {
        throw new Error('Source is not configured');
      }
      if (this._state === Pump.STOPPED) {
        this._state = Pump.STARTED;
      }
      this._pump();
      return this;
    };

    Pump.prototype._pump = function() {
      if (this._state === Pump.SOURCE_ENDED) {
        return this.subscribeForOutputBufferEnds();
      }
      return (this.currentRead = this._from.readAsync()).cancellable().then((function(_this) {
        return function(data) {
          _this.currentRead = null;
          return _this._process(data);
        };
      })(this))["catch"](Promise.CancellationError, function() {}).done((function(_this) {
        return function() {
          return _this._pump();
        };
      })(this));
    };

    Pump.prototype.subscribeForOutputBufferEnds = function() {
      var buffer, name, _ref, _results;
      _ref = this._buffers;
      _results = [];
      for (name in _ref) {
        buffer = _ref[name];
        buffer.on('end', this.outputBufferEnded.bind(this));
        _results.push(buffer.seal());
      }
      return _results;
    };

    Pump.prototype.outputBufferEnded = function() {
      var buffer, name, _ref;
      _ref = this._buffers;
      for (name in _ref) {
        buffer = _ref[name];
        if (!buffer.isEnded()) {
          return;
        }
      }
      return this.emit('end');
    };

    Pump.prototype._process = function(data) {
      return this.buffer().writeAsync(data);
    };

    Pump.prototype.process = function(fn) {
      if (typeof fn !== 'function') {
        throw new Error('Process must be a function');
      }
      this._process = fn.bind(this);
      return this;
    };

    Pump.prototype.mixin = function(mixins) {
      var mixin, _i, _len;
      mixins = Array.isArray(mixins) ? mixins : [mixins];
      for (_i = 0, _len = mixins.length; _i < _len; _i++) {
        mixin = mixins[_i];
        mixin(this);
      }
      return this;
    };

    return Pump;

  })(EventEmitter);

  module.exports = Pump;

}).call(this);
