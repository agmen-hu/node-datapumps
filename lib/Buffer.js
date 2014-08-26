(function() {
  var Buffer, EventEmitter, Promise,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  Promise = require('bluebird');

  Buffer = (function(_super) {
    __extends(Buffer, _super);

    Buffer._defaultBufferSize = 10;

    Buffer.defaultBufferSize = function(size) {
      if (size == null) {
        return Buffer._defaultBufferSize;
      }
      return Buffer._defaultBufferSize = size;
    };

    function Buffer(options) {
      var _ref, _ref1, _ref2;
      if (options == null) {
        options = {};
      }
      this.content = (_ref = options.content) != null ? _ref : [];
      this.size = (_ref1 = options.size) != null ? _ref1 : Buffer._defaultBufferSize;
      this._sealed = (_ref2 = options.sealed) != null ? _ref2 : false;
    }

    Buffer.prototype.isEmpty = function() {
      return this.content.length === 0;
    };

    Buffer.prototype.isFull = function() {
      return this.content.length >= this.size;
    };

    Buffer.prototype.getContent = function() {
      return this.content;
    };

    Buffer.prototype.write = function(data) {
      if (this._sealed === true) {
        throw new Error('Cannot write sealed buffer');
      }
      if (this.isFull()) {
        throw new Error('Buffer is full');
      }
      this.content.push(data);
      this.emit('write', data);
      if (this.isFull()) {
        this.emit('full');
      }
      return this;
    };

    Buffer.prototype.writeAsync = function(data) {
      if (!this.isFull()) {
        return Promise.resolve(this.write(data));
      } else {
        return new Promise((function(_this) {
          return function(resolve, reject) {
            return _this.once('release', function() {
              return resolve(_this.writeAsync(data));
            });
          };
        })(this));
      }
    };

    Buffer.prototype.read = function() {
      var result;
      if (this.isEmpty()) {
        throw new Error('Buffer is empty');
      }
      result = this.content.shift();
      this.emit('release', result);
      if (this.isEmpty()) {
        this.emit('empty');
        if (this._sealed === true) {
          this.emit('end');
        }
      }
      return result;
    };

    Buffer.prototype.readAsync = function() {
      if (!this.isEmpty()) {
        return Promise.resolve(this.read());
      } else {
        return new Promise((function(_this) {
          return function(resolve, reject) {
            return _this.once('write', function() {
              return resolve(_this.readAsync());
            });
          };
        })(this));
      }
    };

    Buffer.prototype.seal = function() {
      if (this._sealed === true) {
        throw new Error('Buffer already sealed');
      }
      this._sealed = true;
      this.emit('sealed');
      if (this.isEmpty()) {
        this.emit('end');
      }
      return this;
    };

    Buffer.prototype.isSealed = function() {
      return this._sealed === true;
    };

    Buffer.prototype.isEnded = function() {
      return this.isSealed() && this.isEmpty();
    };

    return Buffer;

  })(EventEmitter);

  module.exports = Buffer;

}).call(this);
