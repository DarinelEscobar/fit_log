part of 'workout_plan_repository_impl.dart';

Future<File> _getOrCreateFile(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');

  if (!await file.exists()) {
    final schema = kTableSchemas[filename]!;
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, schema.sheetName);
    }
    excel[schema.sheetName]!.appendRow(
      schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList(),
    );
    final bytes = excel.save();
    if (bytes != null) await file.writeAsBytes(bytes);
  }
  return file;
}

int _getLastId(Sheet sheet) {
  for (var i = sheet.rows.length - 1; i >= 1; i--) {
    final val = sheet.rows[i][0]?.value;
    if (val != null) return int.tryParse(val.toString()) ?? 0;
  }
  return 0;
}

T? _cast<T>(Data? cell) {
  final v = cell?.value;
  if (v == null) return null;
  if (v is T) return v as T;
  if (T == int) return int.tryParse(v.toString()) as T?;
  if (T == double) return double.tryParse(v.toString()) as T?;
  if (T == String) return v.toString() as T;
  return null;
}
