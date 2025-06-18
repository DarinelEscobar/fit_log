import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../schema/schemas.dart';

class XlsxInitializer {
  XlsxInitializer._();

  static Future<void> ensureXlsxFilesExist() async {
    final dir = await getApplicationDocumentsDirectory();

    for (final entry in kTableSchemas.entries) {
      final file = File('${dir.path}/${entry.key}');
      if (await file.exists()) {
        await _upgradeTableIfNeeded(file, entry.value);
        continue;
      }

      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.rename(defaultSheet, entry.value.sheetName);
      }

      _writeTable(excel, entry.value);

      final bytes = excel.save();
      if (bytes != null) await file.writeAsBytes(bytes);
    }
  }

  static Future<void> _upgradeTableIfNeeded(
      File file, TableSchema schema) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel[schema.sheetName];
    if (sheet == null || sheet.rows.isEmpty) return;

    final currentHeaders = sheet.rows.first
        .map((e) => e?.value.toString() ?? '')
        .toList();
    if (currentHeaders.length >= schema.headers.length) return;

    for (var i = currentHeaders.length; i < schema.headers.length; i++) {
      sheet.rows.first.add(TextCellValue(schema.headers[i]));
      final defaultValue = _defaultFor(schema, i);
      for (var r = 1; r < sheet.rows.length; r++) {
        sheet.rows[r].add(_toCellValue(defaultValue));
      }
    }

    final updated = excel.save();
    if (updated != null) await file.writeAsBytes(updated);
  }

  static dynamic _defaultFor(TableSchema schema, int index) {
    if (schema.sample.isNotEmpty && schema.sample.first is List) {
      final row = schema.sample.first as List;
      if (index < row.length) return row[index];
    } else if (index < schema.sample.length) {
      return schema.sample[index];
    }
    return '';
  }

  static void _writeTable(Excel excel, TableSchema schema) {
    final sheet = excel[schema.sheetName];
    if (sheet == null) return;

    final headerRow = schema.headers
        .map<CellValue?>((e) => TextCellValue(e))
        .toList();

    sheet.appendRow(headerRow);

    // Soporta múltiples filas si sample es una lista de listas
    if (schema.sample.isNotEmpty && schema.sample.first is List) {
      for (var row in schema.sample) {
        final cellRow = (row as List).map<CellValue?>((e) => _toCellValue(e)).toList();
        sheet.appendRow(cellRow);
      }
    } else {
      final sampleRow = schema.sample.map<CellValue?>((e) => _toCellValue(e)).toList();
      sheet.appendRow(sampleRow);
    }
  }

  static CellValue _toCellValue(dynamic e) {
    if (e is int) return IntCellValue(e);
    if (e is double) return DoubleCellValue(e);
    return TextCellValue(e.toString());
  }
}
