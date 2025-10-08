import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../create/initialize_xlsx.dart';
import '../schema/schemas.dart';

/// Internal configuration describing how an Excel worksheet maps to a database
/// table.
class _TableConfig {
  const _TableConfig({
    required this.tableName,
    required this.headerToColumn,
    this.orderBy,
    this.parsers = const {},
  });

  final String tableName;
  final Map<String, String> headerToColumn;
  final String? orderBy;
  final Map<String, Object? Function(Object?)> parsers;

  List<String> orderedColumns(TableSchema schema) =>
      schema.headers.map((h) => headerToColumn[h]!).toList();
}

/// Service to sync data between SQLite and Excel files.
class ExcelSyncService {
  ExcelSyncService(this.db);

  final Database db;

  static final Map<String, _TableConfig> _tables = {
    'exercise.xlsx': _TableConfig(
      tableName: 'exercise',
      orderBy: 'id',
      headerToColumn: const {
        'exercise_id': 'id',
        'name': 'name',
        'description': 'description',
        'category': 'category',
        'main_muscle_group': 'main_muscle_group',
      },
      parsers: const {
        'id': _parseInt,
        'name': _parseString,
        'description': _parseString,
        'category': _parseString,
        'main_muscle_group': _parseString,
      },
    ),
    'workout_plan.xlsx': _TableConfig(
      tableName: 'workout_plan',
      orderBy: 'id',
      headerToColumn: const {
        'plan_id': 'id',
        'name': 'name',
        'frequency': 'frequency',
      },
      parsers: const {
        'id': _parseInt,
        'name': _parseString,
        'frequency': _parseString,
      },
    ),
    'plan_exercise.xlsx': _TableConfig(
      tableName: 'plan_exercise',
      orderBy: 'plan_id ASC, position ASC',
      headerToColumn: const {
        'plan_id': 'plan_id',
        'exercise_id': 'exercise_id',
        'suggested_sets': 'suggested_sets',
        'suggested_reps': 'suggested_reps',
        'estimated_weight': 'estimated_weight',
        'rest_seconds': 'rest_seconds',
        'image_path': 'image_path',
      },
      parsers: const {
        'plan_id': _parseInt,
        'exercise_id': _parseInt,
        'suggested_sets': _parseInt,
        'suggested_reps': _parseInt,
        'estimated_weight': _parseDouble,
        'rest_seconds': _parseInt,
        'image_path': _parseString,
      },
    ),
    'workout_session.xlsx': _TableConfig(
      tableName: 'workout_session',
      orderBy: 'date',
      headerToColumn: const {
        'session_id': 'id',
        'date': 'date',
        'plan_id': 'plan_id',
        'fatigue_level': 'fatigue_level',
        'duration_minutes': 'duration_minutes',
        'mood': 'mood',
        'notes': 'notes',
      },
      parsers: const {
        'id': _parseInt,
        'date': _parseDate,
        'plan_id': _parseInt,
        'fatigue_level': _parseString,
        'duration_minutes': _parseInt,
        'mood': _parseString,
        'notes': _parseString,
      },
    ),
    'workout_log.xlsx': _TableConfig(
      tableName: 'workout_log',
      orderBy: 'date',
      headerToColumn: const {
        'log_id': 'id',
        'date': 'date',
        'plan_id': 'plan_id',
        'exercise_id': 'exercise_id',
        'set_number': 'set_number',
        'reps_completed': 'reps',
        'weight_used': 'weight',
        'RIR': 'rir',
      },
      parsers: const {
        'id': _parseInt,
        'date': _parseDate,
        'plan_id': _parseInt,
        'exercise_id': _parseInt,
        'set_number': _parseInt,
        'reps': _parseInt,
        'weight': _parseDouble,
        'rir': _parseInt,
      },
    ),
  };

  /// Exports the current database contents to `.xlsx` files.
  Future<void> exportToExcel() async {
    final dir = await getApplicationDocumentsDirectory();
    for (final entry in _tables.entries) {
      final schema = kTableSchemas[entry.key];
      if (schema == null) continue;
      final config = entry.value;
      final columns = config.orderedColumns(schema);
      final rows = await db.query(
        config.tableName,
        columns: columns,
        orderBy: config.orderBy,
      );
      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.rename(defaultSheet, schema.sheetName);
      }
      final sheet = excel[schema.sheetName]!;
      sheet.appendRow(
        schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList(),
      );
      for (final row in rows) {
        final values = schema.headers.map<CellValue?>((header) {
          final column = config.headerToColumn[header]!;
          final value = row[column];
          return _toCellValue(value);
        }).toList();
        sheet.appendRow(values);
      }
      final file = File('${dir.path}/${entry.key}');
      final bytes = excel.save();
      if (bytes != null) {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      }
    }
  }

  /// Imports data from existing `.xlsx` files into the database.
  Future<void> importFromExcel() async {
    final dir = await getApplicationDocumentsDirectory();
    await db.transaction((txn) async {
      for (final entry in _tables.entries) {
        final schema = kTableSchemas[entry.key];
        if (schema == null) continue;
        final config = entry.value;
        final file = File('${dir.path}/${entry.key}');
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel[schema.sheetName];
        if (sheet == null) continue;

        await txn.delete(config.tableName);
        final batch = txn.batch();
        final positions = <int, int>{};

        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (_isRowEmpty(row)) continue;

          final values = <String, Object?>{};
          for (var c = 0; c < schema.headers.length && c < row.length; c++) {
            final header = schema.headers[c];
            final column = config.headerToColumn[header];
            if (column == null) continue;
            final parser = config.parsers[column];
            final parsedValue = parser != null
                ? parser(_unwrapCellValue(row[c]?.value))
                : _defaultParse(_unwrapCellValue(row[c]?.value));
            values[column] = parsedValue;
          }

          if (values.isEmpty) {
            continue;
          }

          if (config.tableName == 'plan_exercise') {
            final planId = values['plan_id'] as int?;
            final exerciseId = values['exercise_id'] as int?;
            if (planId == null || exerciseId == null) {
              continue;
            }
            final pos = positions.update(planId, (value) => value + 1,
                ifAbsent: () => 0);
            values['position'] = pos;
          }

          if (values.containsKey('id') && values['id'] == null) {
            values.remove('id');
          }

          batch.insert(
            config.tableName,
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      }
    });
  }

  /// Migrates legacy Excel data into SQLite on first launch.
  Future<void> migrateFromExcel() async {
    await XlsxInitializer.ensureXlsxFilesExist();
    final tables = _tables.values.map((e) => e.tableName);
    for (final table in tables) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'),
      );
      if (count != null && count > 0) {
        return;
      }
    }
    await importFromExcel();
  }
}

bool _isRowEmpty(List<Data?> row) {
  for (final cell in row) {
    final value = _unwrapCellValue(cell?.value);
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    return false;
  }
  return true;
}

Object? _unwrapCellValue(Object? raw) {
  if (raw is IntCellValue) return raw.value;
  if (raw is DoubleCellValue) return raw.value;
  if (raw is TextCellValue) return raw.value;
  if (raw is BoolCellValue) return raw.value;
  if (raw is FormulaCellValue) return raw.formula;
  if (raw is DateCellValue) return raw.asDateTimeUtc();
  if (raw is DateTimeCellValue) return raw.asDateTimeUtc();
  if (raw is TimeCellValue) return raw.asDuration();
  if (raw is CellValue) return raw.toString();
  return raw;
}

CellValue? _toCellValue(Object? value) {
  if (value == null) return null;
  if (value is int) return IntCellValue(value);
  if (value is double) return DoubleCellValue(value);
  if (value is num) return DoubleCellValue(value.toDouble());
  if (value is DateTime) {
    return TextCellValue(_formatDate(value));
  }
  return TextCellValue(value.toString());
}

Object? _defaultParse(Object? value) => value;

Object? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return int.tryParse(str);
}

Object? _parseDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return double.tryParse(str);
}

Object? _parseString(Object? value) {
  if (value == null) return '';
  return value.toString();
}

Object? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return _formatDate(value);
  if (value is num) {
    final numeric = value.toInt();
    final digits = numeric.toString();
    if (digits.length == 8) {
      final maybeDate = DateTime.tryParse(
          '${digits.substring(0, 4)}-${digits.substring(4, 6)}-${digits.substring(6, 8)}');
      if (maybeDate != null) {
        return _formatDate(maybeDate);
      }
    }
    final base = DateTime(1899, 12, 30);
    final date = base.add(Duration(
      milliseconds: (value * Duration.millisecondsPerDay).round(),
    ));
    return _formatDate(date);
  }
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  final parsed = DateTime.tryParse(str);
  if (parsed != null) {
    return _formatDate(parsed);
  }
  return str;
}

String _formatDate(DateTime value) => value.toIso8601String().split('T').first;
