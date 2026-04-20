import 'dart:io';
import 'dart:isolate';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/routines/domain/entities/exercise.dart';
import '../../features/routines/domain/entities/plan_exercise_detail.dart';
import '../../features/routines/domain/entities/workout_log_entry.dart';
import '../../features/routines/domain/entities/workout_plan.dart';
import '../../features/routines/domain/entities/workout_session.dart';
import '../schema/schemas.dart';

class WorkoutStorageService {
  WorkoutStorageService({DatabaseFactory? dbFactory})
      : _databaseFactory = dbFactory ?? databaseFactory;

  static const String _databaseName = 'fit_log.db';
  static const int _databaseVersion = 2;
  static const String _routineRuntimeSeededKey = 'routine_runtime_seeded';
  static const String _routineRuntimeSeededAtKey = 'routine_runtime_seeded_at';

  final DatabaseFactory _databaseFactory;

  Database? _database;
  Future<void>? _routineWarmUpFuture;

  Future<void> close() async {
    final db = _database;
    _database = null;
    _routineWarmUpFuture = null;
    if (db == null) {
      return;
    }
    try {
      await db.close();
    } catch (_) {
      // Ignore close errors. The next open will recreate the handle.
    }
  }

  Future<void> reopenIfNeeded() async {
    await _getDatabase();
  }

  Future<void> warmUpRoutineRuntimeCache({bool force = false}) {
    if (!force && _routineWarmUpFuture != null) {
      return _routineWarmUpFuture!;
    }

    late final Future<void> trackedFuture;
    trackedFuture =
        _warmUpRoutineRuntimeCacheInternal(force: force).catchError((
      error,
      stackTrace,
    ) {
      if (identical(_routineWarmUpFuture, trackedFuture)) {
        _routineWarmUpFuture = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _routineWarmUpFuture = trackedFuture;
    return _routineWarmUpFuture!;
  }

  Future<List<WorkoutPlan>> fetchWorkoutPlans() async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final rows = await db.query('workout_plans', orderBy: 'plan_id ASC');
    return rows.map(_mapWorkoutPlanRow).toList(growable: false);
  }

  Future<void> createWorkoutPlan(String name, String frequency) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final nextId = await _nextId(db, 'workout_plans', 'plan_id');
    await db.insert(
      'workout_plans',
      {
        'plan_id': nextId,
        'name': name,
        'frequency': frequency,
        'is_active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateWorkoutPlan(
    int planId,
    String name,
    String frequency,
  ) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.update(
      'workout_plans',
      {
        'name': name,
        'frequency': frequency,
      },
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }

  Future<void> setWorkoutPlanActive(int planId, bool isActive) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.update(
      'workout_plans',
      {
        'is_active': isActive ? 1 : 0,
      },
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }

  Future<List<Exercise>> fetchAllExercises() async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final rows = await db.query('exercises', orderBy: 'exercise_id ASC');
    return rows.map(_mapExerciseRow).toList(growable: false);
  }

  Future<void> createExercise(
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final nextId = await _nextId(db, 'exercises', 'exercise_id');
    await db.insert(
      'exercises',
      {
        'exercise_id': nextId,
        'name': name,
        'description': description,
        'category': category,
        'main_muscle_group': mainMuscleGroup,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateExercise(
    int id,
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.update(
      'exercises',
      {
        'name': name,
        'description': description,
        'category': category,
        'main_muscle_group': mainMuscleGroup,
      },
      where: 'exercise_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Exercise>> fetchExercisesForPlan(int planId) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final rows = await db.rawQuery(
      '''
      SELECT
        e.exercise_id,
        e.name,
        e.description,
        e.category,
        e.main_muscle_group
      FROM plan_exercises pe
      INNER JOIN exercises e ON e.exercise_id = pe.exercise_id
      WHERE pe.plan_id = ?
      ORDER BY pe.position ASC
      ''',
      [planId],
    );
    return rows.map(_mapExerciseRow).toList(growable: false);
  }

  Future<List<PlanExerciseDetail>> fetchPlanExerciseDetails(int planId) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final rows = await db.rawQuery(
      '''
      SELECT
        pe.exercise_id,
        e.name,
        e.description,
        pe.suggested_sets,
        pe.suggested_reps,
        pe.estimated_weight,
        pe.rest_seconds,
        pe.rir,
        pe.tempo
      FROM plan_exercises pe
      INNER JOIN exercises e ON e.exercise_id = pe.exercise_id
      WHERE pe.plan_id = ?
      ORDER BY pe.position ASC
      ''',
      [planId],
    );
    return rows.map(_mapPlanExerciseDetailRow).toList(growable: false);
  }

  Future<List<Exercise>> fetchSimilarExercises(int exerciseId) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final baseRows = await db.query(
      'exercises',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      limit: 1,
    );
    if (baseRows.isEmpty) {
      return const [];
    }

    final base = baseRows.first;
    final rows = await db.query(
      'exercises',
      where: 'exercise_id != ? AND (category = ? OR main_muscle_group = ?)',
      whereArgs: [
        exerciseId,
        _stringValue(base['category']),
        _stringValue(base['main_muscle_group']),
      ],
      orderBy: 'exercise_id ASC',
    );
    return rows.map(_mapExerciseRow).toList(growable: false);
  }

  Future<void> addExerciseToPlan(
    int planId,
    PlanExerciseDetail detail, {
    int? position,
  }) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.transaction((txn) async {
      final currentRows = await txn.query(
        'plan_exercises',
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'position ASC',
      );

      final entries = <Map<String, Object?>>[
        for (final row in currentRows)
          if (_intValue(row['exercise_id']) != detail.exerciseId)
            Map<String, Object?>.from(row)
      ];

      final insertIndex = (position ?? entries.length).clamp(0, entries.length);
      entries.insert(
        insertIndex,
        _planExerciseRow(planId, detail, position: insertIndex),
      );

      await _rewritePlanExercises(txn, planId, entries);
    });
  }

  Future<void> updateExerciseInPlan(
    int planId,
    PlanExerciseDetail detail,
  ) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.update(
      'plan_exercises',
      {
        'suggested_sets': detail.sets,
        'suggested_reps': detail.reps,
        'estimated_weight': detail.weight,
        'rest_seconds': detail.restSeconds,
        'rir': detail.rir,
        'tempo': detail.tempo,
      },
      where: 'plan_id = ? AND exercise_id = ?',
      whereArgs: [planId, detail.exerciseId],
    );
  }

  Future<void> deleteExerciseFromPlan(int planId, int exerciseId) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.transaction((txn) async {
      final currentRows = await txn.query(
        'plan_exercises',
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'position ASC',
      );

      final entries = <Map<String, Object?>>[
        for (final row in currentRows)
          if (_intValue(row['exercise_id']) != exerciseId)
            Map<String, Object?>.from(row)
      ];

      await _rewritePlanExercises(txn, planId, entries);
    });
  }

  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {
    if (logs.isEmpty) {
      return;
    }

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
    if (existing.isNotEmpty) {
      return;
    }

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
            planId: _intValue(row['plan_id']),
            date:
                DateTime.tryParse(_stringValue(row['date'])) ?? DateTime.now(),
            fatigueLevel: _stringValue(row['fatigue_level']),
            durationMinutes: _intValue(row['duration_minutes']),
            mood: _stringValue(row['mood']),
            notes: _stringValue(row['notes']),
          ),
        )
        .toList(growable: false);
  }

  Future<List<WorkoutLogEntry>> fetchAllLogs() async {
    final db = await _getDatabase();
    final rows = await db.query('workout_logs', orderBy: 'id DESC');
    return rows
        .map(
          (row) => WorkoutLogEntry(
            date:
                DateTime.tryParse(_stringValue(row['date'])) ?? DateTime.now(),
            planId: _intValue(row['plan_id']),
            exerciseId: _intValue(row['exercise_id']),
            setNumber: _intValue(row['set_number']),
            reps: _intValue(row['reps']),
            weight: _doubleValue(row['weight']),
            rir: _intValue(row['rir']),
          ),
        )
        .toList(growable: false);
  }

  Future<void> exportRoutineRuntimeToXlsxFiles(Directory directory) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();

    final plans = await db.query('workout_plans', orderBy: 'plan_id ASC');
    final exercises = await db.query('exercises', orderBy: 'exercise_id ASC');
    final planExercises = await db.query(
      'plan_exercises',
      orderBy: 'plan_id ASC, position ASC',
    );

    await _writeExcelExport(
      directory,
      'workout_plan.xlsx',
      [
        for (final row in plans)
          [
            _intValue(row['plan_id']),
            _stringValue(row['name']),
            _stringValue(row['frequency']),
            _boolValue(row['is_active']) ? 1 : 0,
          ],
      ],
    );

    await _writeExcelExport(
      directory,
      'exercise.xlsx',
      [
        for (final row in exercises)
          [
            _intValue(row['exercise_id']),
            _stringValue(row['name']),
            _stringValue(row['description']),
            _stringValue(row['category']),
            _stringValue(row['main_muscle_group']),
          ],
      ],
    );

    await _writeExcelExport(
      directory,
      'plan_exercise.xlsx',
      [
        for (final row in planExercises)
          [
            _intValue(row['plan_id']),
            _intValue(row['exercise_id']),
            _intValue(row['suggested_sets']),
            _intValue(row['suggested_reps']),
            _doubleValue(row['estimated_weight']),
            _intValue(row['rest_seconds']),
            _intValue(row['rir']),
            _stringValue(row['tempo']),
            _stringValue(row['image_path']),
          ],
      ],
    );
  }

  Future<void> replaceWorkoutLogsFromCurrentXlsxFiles() async {
    final db = await _getDatabase();
    final directory = await getApplicationDocumentsDirectory();
    final rows = await Isolate.run(
      () => _parseWorkoutLogSeed(directory.path),
    );

    await db.transaction((txn) async {
      await txn.delete('workout_logs');
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(
          'workout_logs',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
      await _deduplicateWorkoutData(txn);
    });
  }

  Future<void> replaceWorkoutSessionsFromCurrentXlsxFiles() async {
    final db = await _getDatabase();
    final directory = await getApplicationDocumentsDirectory();
    final rows = await Isolate.run(
      () => _parseWorkoutSessionSeed(directory.path),
    );

    await db.transaction((txn) async {
      await txn.delete('workout_sessions');
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(
          'workout_sessions',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
      await _deduplicateWorkoutData(txn);
    });
  }

  Future<void> _warmUpRoutineRuntimeCacheInternal({required bool force}) async {
    final db = await _getDatabase();

    if (!force) {
      final seeded = await _readMeta(db, _routineRuntimeSeededKey);
      if (seeded == '1') {
        return;
      }

      final counts = await Future.wait<int>([
        _countRows(db, 'workout_plans'),
        _countRows(db, 'exercises'),
        _countRows(db, 'plan_exercises'),
      ]);
      if (counts.any((count) => count > 0)) {
        await _setMeta(db, _routineRuntimeSeededKey, '1');
        return;
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final payload = await Isolate.run(
      () => _parseRoutineRuntimeSeed(directory.path),
    );

    final plans =
        payload[_routineSeedPlansKey] ?? const <Map<String, Object?>>[];
    final exercises =
        payload[_routineSeedExercisesKey] ?? const <Map<String, Object?>>[];
    final planExercises =
        payload[_routineSeedPlanExercisesKey] ?? const <Map<String, Object?>>[];

    await db.transaction((txn) async {
      await txn.delete('plan_exercises');
      await txn.delete('exercises');
      await txn.delete('workout_plans');

      final batch = txn.batch();
      for (final row in plans) {
        batch.insert(
          'workout_plans',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in exercises) {
        batch.insert(
          'exercises',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final row in planExercises) {
        batch.insert(
          'plan_exercises',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      await _setMeta(txn, _routineRuntimeSeededKey, '1');
      await _setMeta(
        txn,
        _routineRuntimeSeededAtKey,
        DateTime.now().toIso8601String(),
      );
    });
  }

  Future<Database> _getDatabase() async {
    final current = _database;
    if (current != null && current.isOpen) {
      return current;
    }

    final dbPath = await _buildDatabasePath();
    final db = await _databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (database, _) async {
          await _ensureSchema(database);
        },
        onUpgrade: (database, _, __) async {
          await _ensureSchema(database);
        },
        onOpen: (database) async {
          await _ensureSchema(database);
        },
      ),
    );

    await _migrateWorkoutHistoryFromExcelIfNeeded(db);
    _database = db;
    return db;
  }

  Future<String> _buildDatabasePath() async {
    final basePath = await getDatabasesPath();
    return path.join(basePath, _databaseName);
  }

  Future<void> _ensureSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS storage_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_plans (
        plan_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        frequency TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises (
        exercise_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT '',
        main_muscle_group TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS plan_exercises (
        plan_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        suggested_sets INTEGER NOT NULL DEFAULT 0,
        suggested_reps INTEGER NOT NULL DEFAULT 0,
        estimated_weight REAL NOT NULL DEFAULT 0,
        rest_seconds INTEGER NOT NULL DEFAULT 0,
        rir INTEGER NOT NULL DEFAULT 2,
        tempo TEXT NOT NULL DEFAULT '3-1-1-0',
        image_path TEXT NOT NULL DEFAULT '',
        PRIMARY KEY (plan_id, exercise_id)
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

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_plans_is_active
      ON workout_plans(is_active)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_plan_exercises_plan_position
      ON plan_exercises(plan_id, position)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_plan_exercises_exercise
      ON plan_exercises(exercise_id)
    ''');
  }

  Future<void> _deduplicateWorkoutData(DatabaseExecutor db) async {
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

  Future<void> _migrateWorkoutHistoryFromExcelIfNeeded(Database db) async {
    final logCount = await _countRows(db, 'workout_logs');
    final sessionCount = await _countRows(db, 'workout_sessions');
    if (logCount > 0 && sessionCount > 0) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    if (logCount == 0) {
      final logs =
          await Isolate.run(() => _parseWorkoutLogSeed(directory.path));
      final batch = db.batch();
      for (final row in logs) {
        batch.insert(
          'workout_logs',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }

    if (sessionCount == 0) {
      final sessions =
          await Isolate.run(() => _parseWorkoutSessionSeed(directory.path));
      final batch = db.batch();
      for (final row in sessions) {
        batch.insert(
          'workout_sessions',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _rewritePlanExercises(
    Transaction txn,
    int planId,
    List<Map<String, Object?>> entries,
  ) async {
    await txn.delete(
      'plan_exercises',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );

    final batch = txn.batch();
    for (var index = 0; index < entries.length; index++) {
      final entry = Map<String, Object?>.from(entries[index]);
      entry['plan_id'] = planId;
      entry['position'] = index;
      batch.insert(
        'plan_exercises',
        entry,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _writeExcelExport(
    Directory directory,
    String filename,
    List<List<Object?>> rows,
  ) async {
    final schema = kTableSchemas[filename];
    if (schema == null) {
      return;
    }

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, schema.sheetName);
    }

    final sheet = excel[schema.sheetName];
    sheet.appendRow(
      schema.headers
          .map<CellValue?>((header) => TextCellValue(header))
          .toList(),
    );

    for (final row in rows) {
      sheet.appendRow(
        row.map<CellValue?>((value) => _toCellValue(value)).toList(),
      );
    }

    final bytes = excel.save();
    if (bytes == null) {
      return;
    }

    final file = File(path.join(directory.path, filename));
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<int> _countRows(DatabaseExecutor db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> _nextId(
    DatabaseExecutor db,
    String table,
    String idColumn,
  ) async {
    final result = await db.rawQuery(
      'SELECT MAX($idColumn) AS max_id FROM $table',
    );
    return (Sqflite.firstIntValue(result) ?? 0) + 1;
  }

  Future<String?> _readMeta(DatabaseExecutor db, String key) async {
    final rows = await db.query(
      'storage_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _stringValue(rows.first['value']);
  }

  Future<void> _setMeta(
    DatabaseExecutor db,
    String key,
    String value,
  ) async {
    await db.insert(
      'storage_meta',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  WorkoutPlan _mapWorkoutPlanRow(Map<String, Object?> row) {
    return WorkoutPlan(
      id: _intValue(row['plan_id']),
      name: _stringValue(row['name']),
      frequency: _stringValue(row['frequency']),
      isActive: _boolValue(row['is_active']),
    );
  }

  Exercise _mapExerciseRow(Map<String, Object?> row) {
    return Exercise(
      id: _intValue(row['exercise_id']),
      name: _stringValue(row['name']),
      description: _stringValue(row['description']),
      category: _stringValue(row['category']),
      mainMuscleGroup: _stringValue(row['main_muscle_group']),
    );
  }

  PlanExerciseDetail _mapPlanExerciseDetailRow(Map<String, Object?> row) {
    return PlanExerciseDetail(
      exerciseId: _intValue(row['exercise_id']),
      name: _stringValue(row['name']),
      description: _stringValue(row['description']),
      sets: _intValue(row['suggested_sets']),
      reps: _intValue(row['suggested_reps']),
      weight: _doubleValue(row['estimated_weight']),
      restSeconds: _intValue(row['rest_seconds']),
      rir: _intValue(row['rir']),
      tempo: _stringValue(row['tempo']),
    );
  }

  Map<String, Object?> _planExerciseRow(
    int planId,
    PlanExerciseDetail detail, {
    required int position,
  }) {
    return {
      'plan_id': planId,
      'exercise_id': detail.exerciseId,
      'position': position,
      'suggested_sets': detail.sets,
      'suggested_reps': detail.reps,
      'estimated_weight': detail.weight,
      'rest_seconds': detail.restSeconds,
      'rir': detail.rir,
      'tempo': detail.tempo,
      'image_path': '',
    };
  }
}

const String _routineSeedPlansKey = 'plans';
const String _routineSeedExercisesKey = 'exercises';
const String _routineSeedPlanExercisesKey = 'plan_exercises';

Map<String, List<Map<String, Object?>>> _parseRoutineRuntimeSeed(
  String directoryPath,
) {
  final exerciseRows = _parseExerciseSeed(directoryPath);
  final planRows = _parseWorkoutPlanSeed(directoryPath);
  final idRemap = <int, int>{};
  final normalizedExercises = <Map<String, Object?>>[];
  var maxExerciseId = 0;

  for (final row in exerciseRows) {
    final originalId = _intValue(row['exercise_id']);
    if (normalizedExercises.any(
      (item) => _intValue(item['exercise_id']) == originalId,
    )) {
      maxExerciseId++;
      idRemap[originalId] = maxExerciseId;
      final next = Map<String, Object?>.from(row);
      next['exercise_id'] = maxExerciseId;
      normalizedExercises.add(next);
      continue;
    }

    if (originalId > maxExerciseId) {
      maxExerciseId = originalId;
    }
    normalizedExercises.add(row);
  }

  final normalizedPlanExercises = _parsePlanExerciseSeed(
    directoryPath,
    idRemap: idRemap,
  );

  return {
    _routineSeedPlansKey: planRows,
    _routineSeedExercisesKey: normalizedExercises,
    _routineSeedPlanExercisesKey: normalizedPlanExercises,
  };
}

List<Map<String, Object?>> _parseWorkoutPlanSeed(String directoryPath) {
  final sheet = _readSheet(
    path.join(directoryPath, 'workout_plan.xlsx'),
    kTableSchemas['workout_plan.xlsx']!.sheetName,
  );
  if (sheet == null) {
    return const [];
  }

  return [
    for (final row in sheet.rows.skip(1))
      if (row.isNotEmpty)
        {
          'plan_id': _intValue(_excelValueAt(row, 0)),
          'name': _stringValue(_excelValueAt(row, 1)),
          'frequency': _stringValue(_excelValueAt(row, 2)),
          'is_active': _boolValue(_excelValueAt(row, 3)) ? 1 : 0,
        },
  ];
}

List<Map<String, Object?>> _parseExerciseSeed(String directoryPath) {
  final sheet = _readSheet(
    path.join(directoryPath, 'exercise.xlsx'),
    kTableSchemas['exercise.xlsx']!.sheetName,
  );
  if (sheet == null) {
    return const [];
  }

  return [
    for (final row in sheet.rows.skip(1))
      if (row.isNotEmpty)
        {
          'exercise_id': _intValue(_excelValueAt(row, 0)),
          'name': _stringValue(_excelValueAt(row, 1)),
          'description': _stringValue(_excelValueAt(row, 2)),
          'category': _stringValue(_excelValueAt(row, 3)),
          'main_muscle_group': _stringValue(_excelValueAt(row, 4)),
        },
  ];
}

List<Map<String, Object?>> _parsePlanExerciseSeed(
  String directoryPath, {
  required Map<int, int> idRemap,
}) {
  final sheet = _readSheet(
    path.join(directoryPath, 'plan_exercise.xlsx'),
    kTableSchemas['plan_exercise.xlsx']!.sheetName,
  );
  if (sheet == null) {
    return const [];
  }

  final positionsByPlan = <int, int>{};
  return [
    for (final row in sheet.rows.skip(1))
      if (row.isNotEmpty)
        () {
          final planId = _intValue(_excelValueAt(row, 0));
          final originalExerciseId = _intValue(_excelValueAt(row, 1));
          final nextPosition = positionsByPlan.update(
            planId,
            (value) => value + 1,
            ifAbsent: () => 0,
          );
          return {
            'plan_id': planId,
            'exercise_id': idRemap[originalExerciseId] ?? originalExerciseId,
            'position': nextPosition,
            'suggested_sets': _intValue(_excelValueAt(row, 2)),
            'suggested_reps': _intValue(_excelValueAt(row, 3)),
            'estimated_weight': _doubleValue(_excelValueAt(row, 4)),
            'rest_seconds': _intValue(_excelValueAt(row, 5)),
            'rir': _intValue(_excelValueAt(row, 6)),
            'tempo': _stringValue(_excelValueAt(row, 7)),
            'image_path': _stringValue(_excelValueAt(row, 8)),
          };
        }(),
  ];
}

List<Map<String, Object?>> _parseWorkoutLogSeed(String directoryPath) {
  final sheet = _readSheet(
    path.join(directoryPath, 'workout_log.xlsx'),
    kTableSchemas['workout_log.xlsx']!.sheetName,
  );
  if (sheet == null) {
    return const [];
  }

  return [
    for (final row in sheet.rows.skip(1))
      if (row.isNotEmpty)
        {
          'date': _stringValue(_excelValueAt(row, 1)),
          'plan_id': _intValue(_excelValueAt(row, 2)),
          'exercise_id': _intValue(_excelValueAt(row, 3)),
          'set_number': _intValue(_excelValueAt(row, 4)),
          'reps': _intValue(_excelValueAt(row, 5)),
          'weight': _doubleValue(_excelValueAt(row, 6)),
          'rir': _intValue(_excelValueAt(row, 7)),
        },
  ];
}

List<Map<String, Object?>> _parseWorkoutSessionSeed(String directoryPath) {
  final sheet = _readSheet(
    path.join(directoryPath, 'workout_session.xlsx'),
    kTableSchemas['workout_session.xlsx']!.sheetName,
  );
  if (sheet == null) {
    return const [];
  }

  return [
    for (final row in sheet.rows.skip(1))
      if (row.isNotEmpty)
        {
          'date': _stringValue(_excelValueAt(row, 1)),
          'plan_id': _intValue(_excelValueAt(row, 2)),
          'fatigue_level': _stringValue(_excelValueAt(row, 3)),
          'duration_minutes': _intValue(_excelValueAt(row, 4)),
          'mood': _stringValue(_excelValueAt(row, 5)),
          'notes': _stringValue(_excelValueAt(row, 6)),
        },
  ];
}

Sheet? _readSheet(String filePath, String sheetName) {
  final file = File(filePath);
  if (!file.existsSync()) {
    return null;
  }

  final bytes = file.readAsBytesSync();
  if (bytes.isEmpty) {
    return null;
  }

  final excel = Excel.decodeBytes(bytes);
  return excel[sheetName];
}

Object? _excelValueAt(List<Data?> row, int index) {
  if (index >= row.length) {
    return null;
  }

  final value = row[index]?.value;
  if (value == null) {
    return null;
  }
  if (value is TextCellValue) {
    return value.value;
  }
  if (value is IntCellValue) {
    return value.value;
  }
  if (value is DoubleCellValue) {
    return value.value;
  }
  if (value is BoolCellValue) {
    return value.value;
  }
  return value.toString();
}

CellValue _toCellValue(Object? value) {
  if (value is int) {
    return IntCellValue(value);
  }
  if (value is double) {
    return DoubleCellValue(value);
  }
  if (value is bool) {
    return BoolCellValue(value);
  }
  return TextCellValue(_stringValue(value));
}

String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _stringValue(Object? value) => value?.toString() ?? '';

bool _boolValue(Object? value) {
  if (value == null) {
    return true;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }

  final text = value.toString().trim().toLowerCase();
  if (text.isEmpty) {
    return true;
  }
  return text != '0' && text != 'false' && text != 'no';
}
