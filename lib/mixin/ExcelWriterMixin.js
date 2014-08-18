(function() {
  var ExcelWriterMixin, excel4node;

  excel4node = require('excel4node');

  ExcelWriterMixin = function(onMixin) {
    return function(target) {
      target._excel = {};
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
        return this._excel.currentRow = 1;
      };
      target.currentWorksheet = function() {
        return this._excel.worksheet;
      };
      target.writeHeaders = function(headers) {
        var header, index, _i, _len;
        if (this._excel.worksheet == null) {
          throw new Error('Use createWorksheet before writing headers');
        }
        if (this._excel.currentRow !== 1) {
          throw new Error('Use writeHeaders before writing any rows to the worksheet');
        }
        for (index = _i = 0, _len = headers.length; _i < _len; index = ++_i) {
          header = headers[index];
          this._writeHeader(index, header);
        }
        this._excel.currentRow = 2;
        return this;
      };
      target._writeHeader = function(index, header) {
        return this._excel.worksheet.Cell(1, index + 1).String(header).Style(this._excel.boldStyle);
      };
      target.writeRow = function(columns) {
        var index, value, _i, _len;
        if (this._excel.worksheet == null) {
          throw new Error('Use createWorksheet before writing rows');
        }
        for (index = _i = 0, _len = columns.length; _i < _len; index = ++_i) {
          value = columns[index];
          this._excel.worksheet.Cell(this._excel.currentRow, index + 1).String(value);
        }
        return this._excel.currentRow++;
      };
      return onMixin.apply(target, []);
    };
  };

  module.exports = ExcelWriterMixin;

}).call(this);
