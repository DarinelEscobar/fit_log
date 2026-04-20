import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/routines/domain/entities/workout_log_entry.dart';
import '../../features/routines/domain/entities/workout_session.dart';
import '../schema/schemas.dart';

class WorkoutStorageService {
  WorkoutStorageService({DatabaseFactory? dbFactory})
      : _databaseFactory = dbFactory ?? databaseFactory;

  final DatabaseFactory _databaseFactory;
  Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    final dbPath = await _buildDatabasePath();
    final db = await _databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, _) async {
          await _createTables(database);
        },
      ),
    );
    await _createTables(db);
    await _migrateFromExcelIfNeeded(db);
    _database = db;
    return db;
  }

  Future<String> _buildDatabasePath() async {
    final basePath = await getDatabasesPath();
    return path.join(basePath, 'fit_log.db');
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        rir INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        plan_id INTEGER NOT NULL,
        fatigue_level TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        mood TEXT NOT NULL,
        notes TEXT NOT NULL
      )
    ''');

    await _deduplicateWorkoutData(db);

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_workout_sessions_unique
      ON workout_sessions(date, plan_id)
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_workout_logs_unique
      ON workout_logs(date, plan_id, exercise_id, set_number, reps, weight, rir)
    ''');
  }

  Future<void> _deduplicateWorkoutData(Database db) async {
    await db.execute('''
      DELETE FROM workout_sessions
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM workout_sessions
        GROUP BY date, plan_id
      )
    ''');

    await db.execute('''
      DELETE FROM workout_logs
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM workout_logs
        GROUP BY date, plan_id, exercise_id, set_number, reps, weight, rir
      )
    ''');
  }

  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {
    if (logs.isEmpty) return;
    final db = await _getDatabase();
    final batch = db.batch();
    for (final log in logs) {
      batch.insert(
        'workout_logs',
        {
          'date': _formatDate(log.date),
          'plan_id': log.planId,
          'exercise_id': log.exerciseId,
          'set_number': log.setNumber,
          'reps': log.reps,
          'weight': log.weight,
          'rir': log.rir,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveWorkoutSession(WorkoutSession session) async {
    final db = await _getDatabase();
    final existing = await db.query(
      'workout_sessions',
      columns: ['id'],
      where: 'date = ? AND plan_id = ?',
      whereArgs: [_formatDate(session.date), session.planId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    await db.insert(
      'workout_sessions',
      {
        'date': _formatDate(session.date),
        'plan_id': session.planId,
        'fatigue_level': session.fatigueLevel,
        'duration_minutes': session.durationMinutes,
        'mood': session.mood,
        'notes': session.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<WorkoutSession>> fetchAllSessions() async {
    final db = await _getDatabase();
    final rows = await db.query('workout_sessions', orderBy: 'id DESC');
    return rows
        .map(
          (row) => WorkoutSession(
            planId: row['plan_id'] as int,
            date: DateTime.tryParse(row['date'] as String) ?? DateTime.now(),
            fatigueLevel: row['fatigue_level'] as String,
            durationMinutes: row['duration_minutes'] as int,
            mood: row['mood'] as String,
            notes: row['notes'] as String,
          ),
        )
        .toList();
  }

  Future<List<WorkoutLogEntry>> fetchAllLogs() async {
    final db = await _getDatabase();
    final rows = await db.query('workout_logs', orderBy: 'id DESC');
    return rows
        .map(
          (row) => WorkoutLogEntry(
            date: DateTime.tryParse(row['date'] as String) ?? DateTime.now(),
            planId: row['plan_id'] as int,
            exerciseId: row['exercise_id'] as int,
            setNumber: row['set_number'] as int,
            reps: row['reps'] as int,
            weight: row['weight'] as double,
            rir: row['rir'] as int,
          ),
        )
        .toList();
  }

  Future<void> _migrateFromExcelIfNeeded(Database db) async {
    final logCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM workout_logs'),
        ) ??
        0;
    final sessionCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM workout_sessions'),
        ) ??
        0;
    if (logCount > 0 || sessionCount > 0) return;

    final directory = await getApplicationDocumentsDirectory();
    await _importLogsFromExcel(db, directory);
    await _importSessionsFromExcel(db, directory);
  }

  Future<void> _importLogsFromExcel(Database db, Directory directory) async {
    final file = File(path.join(directory.path, 'workout_log.xlsx'));
    if (!await file.exists()) return;
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_log.xlsx']!.sheetName];
    if (sheet == null) return;

    final batch = db.batch();
    for (final row in sheet.rows.skip(1)) {
      if (row.isEmpty) continue;
      batch.insert(
        'workout_logs',
        {
          'date': row[1]?.value.toString() ?? '',
          'plan_id': _parseInt(row[2]?.value),
          'exercise_id': _parseInt(row[3]?.value),
          'set_number': _parseInt(row[4]?.value),
          'reps': _parseInt(row[5]?.value),
          'weight': _parseDouble(row[6]?.value),
          'rir': _parseInt(row[7]?.value),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _importSessionsFromExcel(
      Database db, Directory directory) async {
    final file = File(path.join(directory.path, 'workout_session.xlsx'));
    if (!await file.exists()) return;
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_session.xlsx']!.sheetName];
    if (sheet == null) return;

    final batch = db.batch();
    for (final row in sheet.rows.skip(1)) {
      if (row.isEmpty) continue;
      batch.insert(
        'workout_sessions',
        {
          'date': row[1]?.value.toString() ?? '',
          'plan_id': _parseInt(row[2]?.value),
          'fatigue_level': row[3]?.value.toString() ?? '',
          'duration_minutes': _parseInt(row[4]?.value),
          'mood': row[5]?.value.toString() ?? '',
          'notes': row[6]?.value.toString() ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  int _parseInt(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

  double _parseDouble(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0.0;
}
