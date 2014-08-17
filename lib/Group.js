(function() {
  var Buffer, EventEmitter, Group, Promise, Pump,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Promise = require('bluebird');

  Pump = require('./Pump');

  Buffer = require('./Buffer');

  Group = (function(_super) {
    __extends(Group, _super);

    Group.STOPPED = 0;

    Group.STARTED = 1;

    Group.PAUSED = 2;

    Group.ENDED = 3;

    function Group() {
      this._pumps = {};
      this._exposedBuffers = {};
      this._state = Group.STOPPED;
    }

    Group.prototype.addPump = function(name, pump) {
      if (pump == null) {
        pump = null;
      }
      if (this._pumps[name] != null) {
        throw new Error('Pump already exists');
      }
      this._pumps[name] = pump != null ? pump : new Pump;
      this._pumps[name].on('end', (function(_this) {
        return function() {
          return _this.pumpEnded(name);
        };
      })(this));
      return this._pumps[name];
    };

    Group.prototype.pumpEnded = function(name) {
      var end, pump, _ref;
      end = true;
      _ref = this._pumps;
      for (name in _ref) {
        pump = _ref[name];
        if (!pump.isEnded()) {
          end = false;
        }
      }
      if (!end) {
        return;
      }
      this._state = Group.ENDED;
      return this.emit('end');
    };

    Group.prototype.pump = function(name) {
      if (this._pumps[name] == null) {
        throw new Error("Pump " + name + " does not exist");
      }
      return this._pumps[name];
    };

    Group.prototype.start = function() {
      var name, pump, _ref, _ref1;
      if (this._state !== Group.STOPPED) {
        throw new Error('Group already started');
      }
      this._state = Group.STARTED;
      if (this._errorBuffer == null) {
        this._errorBuffer = this.errorBuffer(new Buffer);
      }
      _ref = this._pumps;
      for (name in _ref) {
        pump = _ref[name];
        pump.errorBuffer(this._errorBuffer);
      }
      _ref1 = this._pumps;
      for (name in _ref1) {
        pump = _ref1[name];
        pump.start();
      }
      return this;
    };

    Group.prototype.isEnded = function() {
      return this._state === Group.ENDED;
    };

    Group.prototype.whenFinished = function() {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          _this.on('end', function() {
            return resolve();
          });
          return _this.on('error', function() {
            return reject('Pumping failed. See .errorBuffer() contents for error messages');
          });
        };
      })(this));
    };

    Group.prototype.createBuffer = function(options) {
      if (options == null) {
        options = {};
      }
      return new Buffer(options);
    };

    Group.prototype.expose = function(exposedName, bufferPath) {
      if (this._exposedBuffers[exposedName] != null) {
        throw new Error("Already exposed a buffer with name " + exposedName);
      }
      return this._exposedBuffers[exposedName] = this._getBufferByPath(bufferPath);
    };

    Group.prototype._getBufferByPath = function(bufferPath) {
      var bufferName, items, pumpName;
      items = bufferPath.split('/');
      if (items.length > 2) {
        throw new Error('bufferPath format must be <pumpName>/<bufferName>');
      }
      pumpName = items[0], bufferName = items[1];
      return this.pump(pumpName).buffer(bufferName != null ? bufferName : 'output');
    };

    Group.prototype.buffer = function(name) {
      if (name == null) {
        name = 'output';
      }
      if (!this._exposedBuffers[name]) {
        throw new Error("No such buffer: " + name);
      }
      return this._exposedBuffers[name];
    };

    Group.prototype.setInputPump = function(pumpName) {
      return this._inputPump = this.pump(pumpName);
    };

    Group.prototype.from = function(buffer) {
      if (buffer == null) {
        buffer = null;
      }
      if (this._inputPump == null) {
        throw new Error('Input pump is not set, use .setInputPump to set it');
      }
      this._inputPump.from(buffer);
      return this;
    };

    Group.prototype.process = function() {
      throw new Error('Cannot call .process() on a group: data in a group is transformed by its pumps.');
    };

    Group.prototype.errorBuffer = function(buffer) {
      if (buffer == null) {
        buffer = null;
      }
      if (buffer === null) {
        return this._errorBuffer;
      }
      this._errorBuffer = buffer;
      this._errorBuffer.on('full', (function(_this) {
        return function() {
          _this.pause();
          return _this.emit('error');
        };
      })(this));
      return this;
    };

    Group.prototype.pause = function() {
      var name, pump, _ref;
      if (this._state === Group.PAUSED) {
        return;
      }
      if (this._state !== Group.STARTED) {
        throw new Error('Cannot .pause() a group that is not pumping');
      }
      this._state = Group.PAUSED;
      _ref = this._pumps;
      for (name in _ref) {
        pump = _ref[name];
        pump.pause();
      }
      return this;
    };

    Group.prototype.resume = function() {
      var name, pump, _ref;
      if (this._state !== Group.PAUSED) {
        throw new Error('Cannot .resume() a group that is not paused');
      }
      this._state = Group.STARTED;
      _ref = this._pumps;
      for (name in _ref) {
        pump = _ref[name];
        pump.resume();
      }
      return this;
    };

    return Group;

  })(EventEmitter);

  module.exports = Group;

}).call(this);
