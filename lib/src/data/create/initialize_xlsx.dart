import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../schema/schemas.dart';

class XlsxInitializer {
  XlsxInitializer._();

  static Future<void> ensureXlsxFilesExist({
    bool includeSampleRows = false,
    Set<String>? filenames,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetFilenames = filenames ?? kTableSchemas.keys.toSet();

    for (final filename in targetFilenames) {
      final schema = kTableSchemas[filename];
      if (schema == null) {
        continue;
      }
      final file = File('${dir.path}/$filename');
      if (await file.exists()) continue;

      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.rename(defaultSheet, schema.sheetName);
      }

      _writeTable(
        excel,
        schema,
        includeSampleRows: includeSampleRows,
      );

      final bytes = excel.save();
      if (bytes != null) await file.writeAsBytes(bytes);
    }
  }

  static Future<void> ensureXlsxFileExists(
    String filename, {
    bool includeSampleRows = false,
  }) {
    return ensureXlsxFilesExist(
      includeSampleRows: includeSampleRows,
      filenames: {filename},
    );
  }

  static void _writeTable(
    Excel excel,
    TableSchema schema, {
    required bool includeSampleRows,
  }) {
    final sheet = excel[schema.sheetName];

    final headerRow =
        schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList();

    sheet.appendRow(headerRow);
    if (!includeSampleRows) {
      return;
    }

    // Supports multiple rows when sample is a list of lists.
    if (schema.sample.isNotEmpty && schema.sample.first is List) {
      for (var row in schema.sample) {
        final cellRow =
            (row as List).map<CellValue?>((e) => _toCellValue(e)).toList();
        sheet.appendRow(cellRow);
      }
    } else {
      final sampleRow =
          schema.sample.map<CellValue?>((e) => _toCellValue(e)).toList();
      sheet.appendRow(sampleRow);
    }
  }

  static CellValue _toCellValue(dynamic e) {
    if (e == null) return TextCellValue('');
    if (e is int) return IntCellValue(e);
    if (e is double) return DoubleCellValue(e);
    return TextCellValue(e.toString());
  }
}
