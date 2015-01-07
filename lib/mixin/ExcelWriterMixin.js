(function() {
  var ExcelWriterMixin, excel4node;

  excel4node = require('excel4node');

  ExcelWriterMixin = function(onMixin) {
    return function(target) {
      target._excel = {
        columnTypes: [],
        path: null
      };
      target.createWorkbook = function(path) {
        if (this._excel.workbook != null) {
          throw new Error('Workbook already created');
        }
        this.workbook(new excel4node.WorkBook());
        this._excel.path = path;
        this.on('end', (function(_this) {
          return function() {
            return _this._excel.workbook.write(_this._excel.path);
          };
        })(this));
        return this._excel.workbook;
      };
      target.workbook = function(workbook) {
        if (workbook == null) {
          workbook = null;
        }
        if (workbook === null) {
          return this._excel.workbook;
        }
        this._excel.workbook = workbook;
        this._excel.boldStyle = this._excel.workbook.Style();
        this._excel.boldStyle.Font.Bold();
        return this;
      };
      target.createWorksheet = function(name) {
        if (this._excel.workbook == null) {
          throw new Error('Use createWorkbook before creating worksheet');
        }
        this._excel.worksheet = this._excel.workbook.WorkSheet(name);
        this._excel.currentRow = 1;
        return this;
      };
      target.currentWorksheet = function() {
        return this._excel.worksheet;
      };
      target.writeHeaders = function(headers, types) {
        var header, index, _i, _len, _ref;
        if (types == null) {
          types = [];
        }
        if (this._excel.worksheet == null) {
          throw new Error('Use createWorksheet before writing headers');
        }
        if (this._excel.currentRow !== 1) {
          throw new Error('Use writeHeaders before writing any rows to the worksheet');
        }
        for (index = _i = 0, _len = headers.length; _i < _len; index = ++_i) {
          header = headers[index];
          this._writeHeader(index, header);
          this.columnType(index, (_ref = types[index]) != null ? _ref : 'String');
        }
        this._excel.currentRow = 2;
        return this;
      };
      target._writeHeader = function(index, header) {
        this._excel.worksheet.Cell(1, index + 1).String(header).Style(this._excel.boldStyle);
        return this;
      };
      target.columnType = function(index, type) {
        if (type == null) {
          type = null;
        }
        if (type === null) {
          return this._excel.columnTypes[index];
        }
        if (['String', 'Number', 'Formula'].indexOf(type) === -1) {
          throw new Error("Invalid column type '" + type + "'. Only String, Number or Formula is allowed");
        }
        this._excel.columnTypes[index] = type;
        return this;
      };
      target.writeRow = function(columns) {
        var cell, index, value, _i, _len, _ref;
        if (this._excel.worksheet == null) {
          throw new Error('Use createWorksheet before writing rows');
        }
        for (index = _i = 0, _len = columns.length; _i < _len; index = ++_i) {
          value = columns[index];
          if (value === null || value === void 0) {
            throw new Error("Null or undefined value written to cell " + this._excel.currentRow + ":" + (index + 1));
          }
          cell = this._excel.worksheet.Cell(this._excel.currentRow, index + 1);
          cell[(_ref = this._excel.columnTypes[index]) != null ? _ref : 'String'](value);
        }
        this._excel.currentRow++;
        return this;
      };
      return onMixin.apply(target, [target]);
    };
  };

  module.exports = ExcelWriterMixin;

}).call(this);
