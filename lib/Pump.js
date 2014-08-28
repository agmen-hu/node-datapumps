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

    Pump.PAUSED = 2;

    Pump.ENDED = 3;

    function Pump() {
      this._state = Pump.STOPPED;
      this._from = null;
      this._id = null;
      this.buffers({
        output: new Buffer
      });
    }

    Pump.prototype.id = function(id) {
      if (id == null) {
        id = null;
      }
      if (id === null) {
        return this._id;
      }
      this._id = id;
      return this;
    };

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
      } else if (buffer instanceof Pump) {
        this._from = buffer.buffer();
      } else if (buffer instanceof require('stream')) {
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
      } else {
        throw new Error('Argument must be datapumps.Buffer or stream');
      }
      this._sourceEnded = false;
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
      return this._sourceEnded = true;
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

    Pump.prototype.to = function(pump, bufferName) {
      pump.from(this.buffer(bufferName));
      return this;
    };

    Pump.prototype.start = function() {
      var buffer, name, _ref;
      if (!this._from) {
        throw new Error('Source is not configured');
      }
      if (this._state !== Pump.STOPPED) {
        throw new Error('Pump is already started');
      }
      this._state = Pump.STARTED;
      if (this._errorBuffer == null) {
        this._errorBuffer = new Buffer;
      }
      _ref = this._buffers;
      for (name in _ref) {
        buffer = _ref[name];
        buffer.on('end', this._outputBufferEnded.bind(this));
      }
      this._pump();
      return this;
    };

    Pump.prototype._outputBufferEnded = function() {
      var allEnded, buffer, name, _ref;
      allEnded = true;
      _ref = this._buffers;
      for (name in _ref) {
        buffer = _ref[name];
        if (!buffer.isEnded()) {
          allEnded = false;
        }
      }
      if (!allEnded) {
        return;
      }
      this._state = Pump.ENDED;
      return this.emit('end');
    };

    Pump.prototype._pump = function() {
      if (this._sourceEnded === true) {
        return this.sealOutputBuffers();
      }
      if (this._state === Pump.PAUSED) {
        return;
      }
      return (this.currentRead = this._from.readAsync()).cancellable().then((function(_this) {
        return function(data) {
          _this.currentRead = null;
          return _this._process(data, _this);
        };
      })(this))["catch"](Promise.CancellationError, function() {})["catch"]((function(_this) {
        return function(err) {
          return _this._errorBuffer.write({
            message: err,
            pump: _this._id
          });
        };
      })(this)).done((function(_this) {
        return function() {
          return _this._pump();
        };
      })(this));
    };

    Pump.prototype.sealOutputBuffers = function() {
      var buffer, name, _ref, _results;
      _ref = this._buffers;
      _results = [];
      for (name in _ref) {
        buffer = _ref[name];
        if (!buffer.isSealed()) {
          _results.push(buffer.seal());
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Pump.prototype._process = function(data) {
      return this.copy(data);
    };

    Pump.prototype.copy = function(data, buffers) {
      var buffer;
      if (buffers == null) {
        buffers = null;
      }
      if (buffers == null) {
        buffers = ['output'];
      }
      if (typeof buffers === 'string') {
        buffers = [buffers];
      }
      if (!Array.isArray(buffers)) {
        throw new Error('buffers must be an array of buffer names or a single buffers name');
      }
      if (buffers.length === 1) {
        return this.buffer(buffers[0]).writeAsync(data);
      } else {
        return Promise.all((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = buffers.length; _i < _len; _i++) {
            buffer = buffers[_i];
            _results.push(this.buffer(buffer).writeAsync(data));
          }
          return _results;
        }).call(this));
      }
    };

    Pump.prototype.process = function(fn) {
      if (typeof fn !== 'function') {
        throw new Error('Process must be a function');
      }
      this._process = fn;
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

    Pump.prototype.isStopped = function() {
      return this._state === Pump.STOPPED;
    };

    Pump.prototype.isStarted = function() {
      return this._state === Pump.STARTED;
    };

    Pump.prototype.isPaused = function() {
      return this._state === Pump.PAUSED;
    };

    Pump.prototype.isEnded = function() {
      return this._state === Pump.ENDED;
    };

    Pump.prototype.createBuffer = function(options) {
      if (options == null) {
        options = {};
      }
      return new Buffer(options);
    };

    Pump.prototype.errorBuffer = function(buffer) {
      if (buffer == null) {
        buffer = null;
      }
      if (buffer === null) {
        return this._errorBuffer;
      }
      this._errorBuffer = buffer;
      return this;
    };

    Pump.prototype.pause = function() {
      if (this._state === Pump.PAUSED) {
        return;
      }
      if (this._state !== Pump.STARTED) {
        throw new Error('Cannot .pause() a pump that is not running');
      }
      this._state = Pump.PAUSED;
      return this;
    };

    Pump.prototype.resume = function() {
      if (this._state !== Pump.PAUSED) {
        throw new Error('Cannot .resume() a pump that is not paused');
      }
      this._state = Pump.STARTED;
      this._pump();
      return this;
    };

    Pump.prototype.whenFinished = function() {
      return new Promise((function(_this) {
        return function(resolve) {
          return _this.on('end', function() {
            return resolve();
          });
        };
      })(this));
    };

    return Pump;

  })(EventEmitter);

  module.exports = Pump;

}).call(this);
