(function() {
  var CsvWriterMixin, Promise, csv, fs;

  csv = require('fast-csv');

  fs = require('fs');

  Promise = require('bluebird');

  CsvWriterMixin = function(options) {
    if (!(options != null ? options.path : void 0)) {
      throw new Error('path option is required.');
    }
    return function(target) {
      target.writeRow = function(row) {
        return target._csv.writer.writeAsync(row);
      };
      target._csv = options;
      target._csv.writer = Promise.promisifyAll(csv.createWriteStream());
      target._csv.writer.pipe(fs.createWriteStream(target._csv.path, {
        encoding: 'utf8'
      }));
      if (target._csv.headers != null) {
        target.writeRow(target._csv.headers);
      }
      return target.on('end', function() {
        return target._csv.writer.write(null);
      });
    };
  };

  module.exports = CsvWriterMixin;

}).call(this);
