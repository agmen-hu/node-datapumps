(function() {
  var Promise, RestMixin, restler, _wrapMethod;

  Promise = require('bluebird');

  restler = require('restler');

  module.exports = RestMixin = function(target) {
    _wrapMethod(target, 'get');
    _wrapMethod(target, 'post');
    _wrapMethod(target, 'put');
    _wrapMethod(target, 'del');
    _wrapMethod(target, 'head');
    _wrapMethod(target, 'patch');
    _wrapMethod(target, 'json');
    _wrapMethod(target, 'postJson');
    _wrapMethod(target, 'putJson');
    return target.file = function() {
      return restler.file.apply(restler, arguments);
    };
  };

  _wrapMethod = function(target, methodName) {
    return target[methodName] = function() {
      var methodArgs;
      methodArgs = arguments;
      return new Promise(function(resolve, reject) {
        return restler[methodName].apply(restler, methodArgs).on('complete', function(result) {
          if (result instanceof Error) {
            return reject(result);
          } else {
            return resolve(result);
          }
        });
      });
    };
  };

}).call(this);
