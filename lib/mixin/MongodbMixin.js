(function() {
  var PassThrough, Promise, mongo, _deferCollectionMethod, _deferFind, _wrapFind, _wrapMethod, _wrappedMethods,
    __slice = [].slice;

  Promise = require('bluebird');

  mongo = Promise.promisifyAll(require('mongodb'));

  PassThrough = require('stream').PassThrough;

  module.exports = function(db) {
    return function(target) {
      var name, _i, _len;
      target._mongo = {
        db: db
      };
      if (typeof db === 'string') {
        (target._mongo.whenConnected = mongo.MongoClient.connectAsync(db)).then(function(db) {
          var _ref, _ref1;
          target._mongo.db = db;
          if (((_ref = target._mongo) != null ? (_ref1 = _ref.collection) != null ? _ref1._datapumpsMixinName : void 0 : void 0) != null) {
            return target._mongo.collection = db.collection(target._mongo.collection._datapumpsMixinName);
          }
        });
      }
      for (_i = 0, _len = _wrappedMethods.length; _i < _len; _i++) {
        name = _wrappedMethods[_i];
        _wrapMethod(target, name);
      }
      _wrapFind(target);
      target.db = function() {
        return this._mongo.db;
      };
      target.useCollection = function(name) {
        var _j, _len1, _ref;
        if ((target._mongo.whenConnected != null) && ((_ref = target._mongo) != null ? _ref.whenConnected.isPending() : void 0)) {
          this._mongo.collection = {
            _datapumpsMixinName: name
          };
          for (_j = 0, _len1 = _wrappedMethods.length; _j < _len1; _j++) {
            name = _wrappedMethods[_j];
            _deferCollectionMethod(this._mongo.collection, name + 'Async', this);
          }
          _deferFind(this._mongo.collection, this);
        } else {
          this._mongo.collection = this._mongo.db.collection(name);
        }
        return this;
      };
      return target.collection = function(name) {
        var _ref;
        if ((_ref = target._mongo) != null ? _ref.whenConnected.isPending() : void 0) {
          throw new Error('Not yet connected to mongo');
        }
        return this._mongo.db.collection(name);
      };
    };
  };

  _wrappedMethods = ['insert', 'remove', 'rename', 'save', 'update', 'count', 'drop', 'findOne', 'createIndex', 'ensureIndex', 'dropIndex', 'reIndex', 'group', 'options', 'indexes', 'stats', 'findAndModify', 'findAndRemove'];

  _wrapMethod = function(target, name) {
    return target[name] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this._mongo.collection == null) {
        throw new Error('Collection is not set. Use .useCollection before using this wrapper');
      }
      if (!this._mongo.collection[name + 'Async']) {
        throw new Error("Method ." + name + "Async() does not exist in collection.");
      }
      return this._mongo.collection[name + 'Async'].apply(this._mongo.collection, args);
    };
  };

  _wrapFind = function(target) {
    return target.find = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this._mongo.collection == null) {
        throw new Error('Collection is not set. Use .useCollection before using this wrapper');
      }
      if (!this._mongo.collection.find) {
        throw new Error("Method .find() does not exist in collection.");
      }
      return this._mongo.collection.find.apply(this._mongo.collection, args).stream();
    };
  };

  _deferCollectionMethod = function(collection, name, target) {
    return collection[name] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return target._mongo.whenConnected.then(function() {
        if (!target._mongo.collection[name]) {
          throw new Error("Method ." + name + " does not exist in collection.");
        }
        return target._mongo.collection[name].apply(target._mongo.collection, args);
      });
    };
  };

  _deferFind = function(collection, target) {
    return collection.find = function() {
      var args, result;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      result = new PassThrough({
        objectMode: true,
        highWaterMark: 10
      });
      target._mongo.whenConnected.then(function() {
        return target._mongo.collection.find.apply(target._mongo.collection, args).stream().pipe(result);
      });
      return {
        stream: function() {
          return result;
        }
      };
    };
  };

}).call(this);
