(function() {
  var postgresqlMixin,
    __slice = [].slice;

  postgresqlMixin = function(client) {
    if ((client == null) || typeof (client != null ? client.query : void 0) !== 'function') {
      throw new Error('Postgresql mixin requires client to be given');
    }
    return function(target) {
      target.query = function() {
        var args, query;
        query = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (args != null) {
          return client.query(query, args);
        } else {
          return client.query(query);
        }
      };
      return target.selectOne = function() {
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
    };
  };

  module.exports = postgresqlMixin;

}).call(this);
