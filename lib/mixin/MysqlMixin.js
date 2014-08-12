(function() {
  var Promise, mysqlMixin,
    __slice = [].slice;

  Promise = require('bluebird');

  mysqlMixin = function(connection) {
    return function(target) {
      target._mysql = {
        connection: connection,
        query: Promise.promisify(connection.query)
      };
      target.query = function() {
        var args, query;
        query = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (args != null) {
          return this._mysql.query(query, args);
        } else {
          return this._mysql.query(query);
        }
      };
      return target.selectOne = function() {
        var args, query;
        query = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        return target.query(query, args).then(function(results) {
          if (results.length === 1) {
            return Promise.resolve(results[0]);
          } else if (results.length === 0) {
            return Promise.reject('Query returned no result');
          } else {
            return Promise.reject('Query returned more than one result');
          }
        });
      };
    };
  };

  module.exports = mysqlMixin;

}).call(this);
