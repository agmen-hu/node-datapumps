(function() {
  var objectTransformMixin;

  objectTransformMixin = function() {
    return function(target) {
      target.propertiesToLowerCase = function(data) {
        var prop, result, value;
        result = {};
        for (prop in data) {
          value = data[prop];
          result[prop.toLowerCase()] = value;
        }
        return result;
      };
      target.requireProperty = function(obj, properties) {
        var property, result, _i, _j, _len, _len1;
        properties = Array.isArray(properties) ? properties : [properties];
        for (_i = 0, _len = properties.length; _i < _len; _i++) {
          property = properties[_i];
          if (obj[property] == null) {
            throw new Error('Missing property: ' + property);
          }
        }
        if (properties.length === 1) {
          return obj[properties[0]];
        } else {
          result = {};
          for (_j = 0, _len1 = properties.length; _j < _len1; _j++) {
            property = properties[_j];
            result[property] = obj[property];
          }
          return result;
        }
      };
      return target.boolValueOf = function(obj) {
        return !(obj === null || obj === void 0 || obj === false || obj === 'off' || obj === 'false' || obj === 0 || obj === 'no');
      };
    };
  };

  module.exports = objectTransformMixin;

}).call(this);
