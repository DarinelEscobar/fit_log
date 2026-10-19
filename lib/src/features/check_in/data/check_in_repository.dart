import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/schema/schemas.dart';

/// Append-only observations. A correction references, rather than erases, a row.
class CheckInRepository {
  static const filename = 'physique_check_in.xlsx';
  static const numericLimits = {
    'weight_kg': 500.0,
    'abdomen_upper_cm': 300.0,
    'abdomen_upper_repeat_cm': 300.0,
    'abdomen_lower_cm': 300.0,
    'abdomen_lower_repeat_cm': 300.0,
    'water_ml': 10000.0,
    'calories_kcal': 15000.0,
    'protein_g': 1000.0,
    'steps': 100000.0,
    'sleep_hours': 24.0,
    'pain_during': 10.0,
    'pain_next_morning': 10.0,
    'discomfort_next_morning': 10.0,
  };

  final Directory? directory;
  CheckInRepository({this.directory});
  Future<void> _pending = Future.value();

  Future<File> _file() async {
    final dir = directory ?? await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/$filename');
  }

  Future<List<Map<String, String>>> readAll() async {
    await _pending;
    final file = await _file();
    if (!await file.exists()) return [];
    final book = Excel.decodeBytes(await file.readAsBytes());
    final rows = book[kTableSchemas[filename]!.sheetName].rows;
    if (rows.isEmpty) return [];
    final headers = rows.first.map((c) => c?.value.toString() ?? '').toList();
    return rows
        .skip(1)
        .where((r) => r.isNotEmpty)
        .map((r) => {
              for (var i = 0; i < headers.length; i++)
                headers[i]: i < r.length ? (r[i]?.value)?.toString() ?? '' : '',
            })
        .where((r) => r['record_id']!.isNotEmpty)
        .toList();
  }

  static void validate(Map<String, String> record) {
    if (!['morning', 'daily', 'tolerance'].contains(record['kind']) ||
        DateTime.tryParse(record['measured_at'] ?? '') == null) {
      throw const FormatException('Selecciona un tipo y una fecha válidos.');
    }
    for (final entry in numericLimits.entries) {
      final text = record[entry.key] ?? '';
      if (text.isEmpty) continue; // Unknown is not zero.
      final number = double.tryParse(text);
      if (number == null ||
          !number.isFinite ||
          number < 0 ||
          number > entry.value ||
          (entry.key.endsWith('_cm') && number == 0) ||
          (entry.key == 'weight_kg' && number == 0)) {
        throw FormatException('Valor inválido: ${entry.key}');
      }
    }
    final bowel = record['last_bowel_movement'] ?? '';
    if (bowel.isNotEmpty &&
        (DateTime.tryParse(bowel) == null ||
            DateTime.parse(bowel)
                .isAfter(DateTime.parse(record['measured_at']!)))) {
      throw const FormatException('La evacuación debe ser anterior a la toma.');
    }
    if (record['kind'] == 'morning' &&
        ['weight_kg', 'abdomen_upper_cm', 'abdomen_lower_cm']
            .every((key) => (record[key] ?? '').isEmpty)) {
      throw const FormatException('Registra al menos peso o una medida.');
    }
    if (record['kind'] == 'tolerance' &&
        (record['exercise_name'] ?? '').trim().isEmpty) {
      throw const FormatException('Indica el ejercicio y la variante.');
    }
  }

  Future<void> save(Map<String, String> observation) {
    validate(observation);
    final operation = _pending.then((_) async {
      final file = await _file();
      final schema = kTableSchemas[filename]!;
      final book = await file.exists()
          ? Excel.decodeBytes(await file.readAsBytes())
          : Excel.createExcel();
      if (!await file.exists()) {
        book.rename(book.getDefaultSheet()!, schema.sheetName);
        book[schema.sheetName]
            .appendRow(schema.headers.map(TextCellValue.new).toList());
      }
      final now = DateTime.now();
      final row = {
        ...observation,
        'record_id':
            observation['record_id'] ?? 'checkin:${now.microsecondsSinceEpoch}',
        'date': observation['measured_at']!.split('T').first,
        'recorded_at': now.toIso8601String(),
        'source': observation['source'] ?? 'manual',
      };
      book[schema.sheetName].appendRow(schema.headers
          .map((h) => (row[h] ?? '').isEmpty ? null : TextCellValue(row[h]!))
          .toList());
      final pending = File('${file.path}.pending');
      await pending.writeAsBytes(book.save()!, flush: true);
      await pending.rename(file.path);
    });
    _pending = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }
}
