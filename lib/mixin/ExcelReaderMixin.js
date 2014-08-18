(function() {
  var Buffer, ExcelReaderMixin, convertSheetToJson;

  convertSheetToJson = require('xlsx').utils.sheet_to_json;

  Buffer = require('../Buffer');

  ExcelReaderMixin = function(_arg) {
    var columnMapping, worksheet;
    worksheet = _arg.worksheet, columnMapping = _arg.columnMapping;
    return function(target) {
      var buffer, content, data, mapColumnNames, _i, _len, _ref;
      if (worksheet == null) {
        throw new Error('worksheet property is required for ExcelReaderMixin');
      }
      target._excel = {
        worksheet: worksheet,
        columnMapping: columnMapping
      };
      mapColumnNames = function(data) {
        var from, result, to;
        result = {};
        for (from in columnMapping) {
          to = columnMapping[from];
          result[to] = data[from];
        }
        return result;
      };
      content = [];
      if (columnMapping) {
        _ref = convertSheetToJson(worksheet);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          data = _ref[_i];
          content.push(mapColumnNames(data));
        }
      } else {
        content = convertSheetToJson(worksheet);
      }
      buffer = new Buffer({
        content: content
      });
      target.from(buffer);
      return buffer.seal();
    };
  };

  module.exports = ExcelReaderMixin;

}).call(this);
