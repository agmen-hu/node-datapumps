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
    target.file = function() {
      return restler.file.apply(restler, arguments);
    };
    return target.fromRest = function(config) {
      var queryAndWriteInputBuffer;
      if (!(config != null ? config.query : void 0)) {
        throw new Error('query key is required');
      }
      if (config.resultMapping == null) {
        config.resultMapping = function(result) {
          return result;
        };
      }
      if (config.nextPage == null) {
        config.nextPage = function() {
          return void 0;
        };
      }
      this.from(this.createBuffer());
      queryAndWriteInputBuffer = (function(_this) {
        return function(nextPage) {
          return config.query.apply(_this, [nextPage]).then(function(response) {
            return _this.from().writeArrayAsync(config.resultMapping(response)).done(function() {
              nextPage = config.nextPage(response);
              if ((nextPage === void 0) || (nextPage === null)) {
                return _this.from().seal();
              } else {
                return queryAndWriteInputBuffer(nextPage);
              }
            });
          });
        };
      })(this);
      queryAndWriteInputBuffer(void 0);
      return this;
    };
  };

  _wrapMethod = function(target, methodName) {
    return target[methodName] = function() {
      var methodArgs;
      methodArgs = arguments;
      return new Promise(function(resolve, reject) {
        return restler[methodName].apply(restler, methodArgs).on('complete', function(result, response) {
          if (result instanceof Error) {
            return reject(result);
          } else {
            response.result = result;
            return resolve(response);
          }
        });
      });
    };
  };

}).call(this);
