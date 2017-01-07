(function() {
  var PumpingFailedError,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = PumpingFailedError = (function(_super) {
    __extends(PumpingFailedError, _super);

    PumpingFailedError.prototype.name = 'PumpingFailedError';

    function PumpingFailedError(message) {
      this.message = message != null ? message : 'Pumping failed. See .errorBuffer() contents for error messages';
      PumpingFailedError.__super__.constructor.call(this, this.message);
    }

    return PumpingFailedError;

  })(Error);

}).call(this);
