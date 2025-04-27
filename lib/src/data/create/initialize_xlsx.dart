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
      if (await file.exists()) continue;

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

  static void _writeTable(Excel excel, TableSchema schema) {
    final sheet = excel[schema.sheetName];
    if (sheet == null) return;
    sheet.appendRow(schema.headers);
    sheet.appendRow(schema.sample);
  }
}
