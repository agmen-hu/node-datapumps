var Group = require('./lib/Group');

module.exports = {
  Buffer: require('./lib/Buffer'),
  Pump: require('./lib/Pump'),
  PumpingFailedError: require('./lib/PumpingFailedError'),
  Group: Group,
  group: function() { return new Group(); },
  mixin: require('./lib/mixin')
}
