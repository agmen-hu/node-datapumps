(function() {
  var Buffer, ExcelReaderMixin, convertSheetToJson, readFile, _ref, _ref1;

  _ref = require('xlsx'), readFile = _ref.readFile, (_ref1 = _ref.utils, convertSheetToJson = _ref1.sheet_to_json);

  Buffer = require('../Buffer');

  ExcelReaderMixin = function(_arg) {
    var columnMapping, path, worksheet;
    worksheet = _arg.worksheet, columnMapping = _arg.columnMapping, path = _arg.path;
    return function(target) {
      var buffer, content, data, mapColumnNames, workbook, _i, _len, _ref2;
      if (path != null) {
        workbook = readFile(path);
        worksheet = workbook.Sheets[worksheet];
      }
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
        _ref2 = convertSheetToJson(worksheet);
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          data = _ref2[_i];
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
