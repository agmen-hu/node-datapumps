(function() {
  var Buffer, MergeHelperPump, MergeMixin, Pump,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Pump = require('../Pump');

  Buffer = require('../Buffer');

  MergeHelperPump = (function(_super) {
    __extends(MergeHelperPump, _super);

    function MergeHelperPump() {
      return MergeHelperPump.__super__.constructor.apply(this, arguments);
    }

    MergeHelperPump.prototype.sealOutputBuffers = function() {};

    return MergeHelperPump;

  })(Pump);

  module.exports = MergeMixin = function(pump) {
    pump.from(new Buffer());
    pump._fromBuffers = [];
    pump._from.on('write', function(data) {
      return console.log('WRITE', data);
    });
    return pump.from = function(buffer) {
      var helperPump, sourceBuffer;
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
        sourceBuffer = buffer;
      } else if (buffer instanceof Pump) {
        sourceBuffer = buffer.buffer();
      } else if (buffer instanceof require('stream')) {
        sourceBuffer = new Buffer({
          size: 1000
        });
        buffer.on('data', (function(_this) {
          return function(data) {
            return sourceBuffer.write(data);
          };
        })(this));
        buffer.on('end', (function(_this) {
          return function() {
            return sourceBuffer.seal();
          };
        })(this));
        buffer.on('error', (function(_this) {
          return function(err) {
            return _this.writeError(err);
          };
        })(this));
        sourceBuffer.on('full', function() {
          return buffer.pause();
        });
        sourceBuffer.on('release', function() {
          return buffer.resume();
        });
      } else {
        throw new Error('Argument must be datapumps.Buffer or stream');
      }
      this._fromBuffers.push(sourceBuffer);
      sourceBuffer.on('end', (function(_this) {
        return function() {
          var allEnded, _i, _len, _ref;
          allEnded = true;
          _ref = _this._fromBuffers;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            buffer = _ref[_i];
            if (!buffer.isEnded()) {
              allEnded = false;
            }
          }
          if (!allEnded) {
            return;
          }
          if (!_this._from.isSealed()) {
            return _this._from.seal();
          }
        };
      })(this));
      (helperPump = new MergeHelperPump()).from(sourceBuffer).buffer('output', this._from).process(function(data) {
        console.log(data);
        return this.copy(data);
      }).start();
      return this;
    };
  };

}).call(this);
