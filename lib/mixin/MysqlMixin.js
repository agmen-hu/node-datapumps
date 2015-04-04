(function() {
  var Promise, mysqlMixin,
    __slice = [].slice;

  Promise = require('bluebird');

  mysqlMixin = function(connection) {
    if ((connection == null) || typeof (connection != null ? connection.query : void 0) !== 'function') {
      throw new Error('Mysql mixin requires connection to be given');
    }
    return function(target) {
      target._mysql = {
        connection: connection,
        query: Promise.promisify(connection.query, connection)
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
      target.selectOne = function() {
        var args, query;
        query = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        return target.query(query, args).then(function(_arg) {
          var fields, results;
          results = _arg[0], fields = _arg[1];
          if (results.length === 1) {
            return results[0];
          } else if (results.length === 0) {
            throw new Error('Query returned no result');
          } else {
            throw new Error('Query returned more than one result');
          }
        });
      };
      return target.escape = function(value) {
        return this._mysql.connection.escape(value);
      };
    };
  };

  module.exports = mysqlMixin;

}).call(this);
