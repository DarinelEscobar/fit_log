import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/routines/domain/entities/exercise.dart';
import '../../features/routines/domain/entities/active_workout_session_draft.dart';
import '../../features/routines/domain/entities/active_session_exercise_setup_preset.dart';
import '../../features/routines/domain/entities/plan_exercise_detail.dart';
import '../../features/routines/domain/entities/workout_log_entry.dart';
import '../../features/routines/domain/entities/workout_plan.dart';
import '../../features/routines/domain/entities/workout_session.dart';
import '../../features/routines/domain/entities/warm_up_step.dart';
import '../schema/schemas.dart';

class WorkoutStorageService {
  WorkoutStorageService({DatabaseFactory? dbFactory})
      : _databaseFactory = dbFactory ?? databaseFactory;

  static const String _databaseName = 'fit_log.db';
  static const int _databaseVersion = 4;
  static const String _routineRuntimeSeededKey = 'routine_runtime_seeded';
  static const String _routineRuntimeSeededAtKey = 'routine_runtime_seeded_at';
  static const List<String> _requiredDatabaseTables = [
    'workout_logs',
    'workout_sessions',
    'workout_plans',
    'exercises',
    'plan_exercises',
    'active_workout_session_drafts',
  ];

  final DatabaseFactory _databaseFactory;

  Database? _database;
  Future<void>? _routineWarmUpFuture;
  Future<Database>? _openingDatabase;

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

  Future<void> validateDatabaseFile(File file) async {
    if (!await file.exists() || await file.length() == 0) {
      throw const FormatException('Backup database is missing or empty.');
    }

    Database? db;
    try {
      db = await _databaseFactory.openDatabase(
        file.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      await _validateRequiredTables(db);

      final integrityRows = await db.rawQuery('PRAGMA integrity_check');
      final integrityResult =
          integrityRows.isEmpty ? null : integrityRows.first.values.first;
      if (integrityResult?.toString().toLowerCase() != 'ok') {
        throw FormatException(
          'SQLite integrity check failed: $integrityResult',
        );
      }
    } catch (error) {
      if (error is FormatException) {
        rethrow;
      }
      throw FormatException('Backup database is not readable: $error');
    } finally {
      await db?.close();
    }
  }

  Future<void> repairDataIntegrity() async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await _repairDataIntegrity(txn, recoverMissingParents: true);
    });
  }

  Future<void> warmUpRoutineRuntimeCache({bool force = false}) {
    if (!force && _routineWarmUpFuture != null) {
      return _routineWarmUpFuture!;
    }

    late final Future<void> trackedFuture;
    trackedFuture = _warmUpRoutineRuntimeCacheInternal(force: force).catchError(
      (error, stackTrace) {
        if (identical(_routineWarmUpFuture, trackedFuture)) {
          _routineWarmUpFuture = null;
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
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
        conflictAlgorithm: ConflictAlgorithm.replace);
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
      {'name': name, 'frequency': frequency},
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }

  Future<void> setWorkoutPlanActive(int planId, bool isActive) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.update(
      'workout_plans',
      {'is_active': isActive ? 1 : 0},
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
        conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<List<int>> fetchExerciseIdsForPlans(List<int> planIds) async {
    await warmUpRoutineRuntimeCache();
    if (planIds.isEmpty) {
      return const [];
    }

    final db = await _getDatabase();
    final placeholders = List.filled(planIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT DISTINCT exercise_id
      FROM plan_exercises
      WHERE plan_id IN ($placeholders)
      ORDER BY exercise_id ASC
      ''', planIds);

    return rows
        .map((row) => _intValue(row['exercise_id']))
        .toList(growable: false);
  }

  Future<DateTime?> fetchLatestWorkoutLogDate({
    List<int>? planIds,
    List<int>? exerciseIds,
    int? exerciseId,
  }) async {
    final db = await _getDatabase();
    final clauses = <String>[];
    final args = <Object?>[];

    if (planIds != null) {
      if (planIds.isEmpty) {
        return null;
      }
      clauses.add(
        'plan_id IN (${List.filled(planIds.length, '?').join(', ')})',
      );
      args.addAll(planIds);
    }

    if (exerciseIds != null) {
      if (exerciseIds.isEmpty) {
        return null;
      }
      clauses.add(
        'exercise_id IN (${List.filled(exerciseIds.length, '?').join(', ')})',
      );
      args.addAll(exerciseIds);
    }

    if (exerciseId != null) {
      clauses.add('exercise_id = ?');
      args.add(exerciseId);
    }

    final rows = await db.query(
      'workout_logs',
      columns: ['date'],
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return DateTime.tryParse(_stringValue(rows.first['date']));
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

  Future<List<WarmUpStep>> fetchWarmUpSteps(int planId) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final rows = await db.query(
      'plan_warmup_steps',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'position ASC, id ASC',
    );
    return rows.map(_mapWarmUpStepRow).toList(growable: false);
  }

  Future<void> replaceWarmUpSteps(
    int planId,
    List<WarmUpStep> steps,
  ) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.delete(
        'plan_warmup_steps',
        where: 'plan_id = ?',
        whereArgs: [planId],
      );
      final batch = txn.batch();
      for (var index = 0; index < steps.length; index++) {
        batch.insert(
          'plan_warmup_steps',
          _warmUpStepRow(planId, steps[index], position: index),
        );
      }
      await batch.commit(noResult: true);
    });
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
            Map<String, Object?>.from(row),
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

  Future<ActiveSessionExerciseSetupPreset?>
      fetchActiveSessionExerciseSetupPreset(
    int exerciseId,
  ) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    final rows = await db.query(
      'active_session_exercise_setup_presets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapActiveSessionExerciseSetupPresetRow(rows.first);
  }

  Future<void> saveActiveSessionExerciseSetupPreset(
    ActiveSessionExerciseSetupPreset preset,
  ) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.insert(
      'active_session_exercise_setup_presets',
      {
        'exercise_id': preset.exerciseId,
        'target_sets': preset.sets,
        'target_reps': preset.reps,
        'estimated_weight': preset.weight,
        'rest_seconds': preset.restSeconds,
        'rir': preset.rir,
        'tempo': preset.tempo,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
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
            Map<String, Object?>.from(row),
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
            'session_id': log.storageSessionId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveWorkoutSession(WorkoutSession session) async {
    final db = await _getDatabase();
    final existing = await db.query(
      'workout_sessions',
      columns: ['id'],
      where: 'session_id = ?',
      whereArgs: [session.storageSessionId],
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
          'session_id': session.storageSessionId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Commit the history and removal of its recovery draft together.
  Future<void> finishWorkout(
      List<WorkoutLogEntry> logs, WorkoutSession session) async {
    if (logs.isEmpty ||
        logs.any((log) =>
            log.planId != session.planId ||
            log.reps <= 0 ||
            !log.weight.isFinite ||
            log.weight < 0)) {
      throw const FormatException('Check the completed sets before saving.');
    }
    final db = await _getDatabase();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final log in logs) {
        batch.insert(
            'workout_logs',
            {
              'session_id': session.storageSessionId,
              'date': _formatDate(session.date),
              'plan_id': log.planId,
              'exercise_id': log.exerciseId,
              'set_number': log.setNumber,
              'reps': log.reps,
              'weight': log.weight,
              'rir': log.rir,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      batch.insert(
          'workout_sessions',
          {
            'session_id': session.storageSessionId,
            'date': _formatDate(session.date),
            'plan_id': session.planId,
            'fatigue_level': session.fatigueLevel,
            'duration_minutes': session.durationMinutes,
            'mood': session.mood,
            'notes': session.notes,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
      batch.delete('active_workout_session_drafts', where: 'id = 1');
      await batch.commit(noResult: true);
    });
  }

  Future<ActiveWorkoutSessionDraft?> fetchActiveSessionDraft() async {
    final db = await _getDatabase();
    final rows = await db.query(
      'active_workout_session_drafts',
      columns: ['payload'],
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    final payload = _stringValue(rows.first['payload']);
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return null;
      }
      return ActiveWorkoutSessionDraft.fromJson(
        decoded.map((key, value) => MapEntry('$key', value)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveSessionDraft(
    ActiveWorkoutSessionDraft draft,
  ) async {
    final db = await _getDatabase();
    await db.insert(
      'active_workout_session_drafts',
      {
        'id': 1,
        'updated_at': draft.updatedAt.toIso8601String(),
        'payload': jsonEncode(draft.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearActiveSessionDraft() async {
    final db = await _getDatabase();
    await db.delete(
      'active_workout_session_drafts',
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<List<WorkoutSession>> fetchAllSessions() async {
    return fetchWorkoutSessions();
  }

  Future<List<WorkoutSession>> fetchWorkoutSessions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _getDatabase();
    final clauses = <String>[];
    final args = <Object?>[];
    if (startDate != null) {
      clauses.add('date >= ?');
      args.add(_formatDate(startDate));
    }
    if (endDate != null) {
      clauses.add('date <= ?');
      args.add(_formatDate(endDate));
    }
    final rows = await db.query(
      'workout_sessions',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date ASC, plan_id ASC',
    );
    return rows
        .map(
          (row) => WorkoutSession(
            sessionId: _stringValue(row['session_id']),
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
    return fetchWorkoutLogs();
  }

  Future<List<WorkoutLogEntry>> fetchWorkoutLogs({
    List<int>? planIds,
    List<int>? exerciseIds,
    int? exerciseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _getDatabase();
    final clauses = <String>[];
    final args = <Object?>[];

    if (planIds != null) {
      if (planIds.isEmpty) {
        return const [];
      }
      clauses.add(
        'plan_id IN (${List.filled(planIds.length, '?').join(', ')})',
      );
      args.addAll(planIds);
    }

    if (exerciseIds != null) {
      if (exerciseIds.isEmpty) {
        return const [];
      }
      clauses.add(
        'exercise_id IN (${List.filled(exerciseIds.length, '?').join(', ')})',
      );
      args.addAll(exerciseIds);
    }

    if (exerciseId != null) {
      clauses.add('exercise_id = ?');
      args.add(exerciseId);
    }

    if (startDate != null) {
      clauses.add('date >= ?');
      args.add(_formatDate(startDate));
    }

    if (endDate != null) {
      clauses.add('date <= ?');
      args.add(_formatDate(endDate));
    }

    final rows = await db.query(
      'workout_logs',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date ASC, plan_id ASC, exercise_id ASC, set_number ASC',
    );

    return rows
        .map(
          (row) => WorkoutLogEntry(
            sessionId: _stringValue(row['session_id']),
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

  Future<bool> hasUsableWorkoutLogs() => _hasUsableDateRows('workout_logs');

  Future<bool> hasUsableWorkoutSessions() =>
      _hasUsableDateRows('workout_sessions');

  Future<void> mergeWorkoutHistoryFromCurrentXlsxFiles({
    required bool includeLogs,
    required bool includeSessions,
  }) async {
    final db = await _getDatabase();
    final directory = await getApplicationDocumentsDirectory();
    final logs = includeLogs
        ? await compute(_parseWorkoutLogSeed, directory.path)
        : const <Map<String, Object?>>[];
    final sessions = includeSessions
        ? await compute(_parseWorkoutSessionSeed, directory.path)
        : const <Map<String, Object?>>[];

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in logs) {
        batch.insert(
          'workout_logs',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final row in sessions) {
        batch.insert(
          'workout_sessions',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
      await _repairDataIntegrity(txn, recoverMissingParents: true);
    });
  }

  /// Read and validate the entire staged backup before writing anything live.
  /// The live database is never replaced or closed by an import.
  Future<void> mergeBackup(Directory spreadsheets, {File? database}) async {
    final payload = await compute(_parseBackupSheets, spreadsheets.path);
    if (database != null) {
      final source = await _databaseFactory.openDatabase(database.path,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      try {
        if (await source.getVersion() > _databaseVersion) {
          throw const FormatException(
              'This backup needs a newer FitLog version.');
        }
        for (final table in payload.keys.toList()) {
          final exists = await source.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
              [table]);
          if (exists.isNotEmpty) {
            final rows = await source.query(table);
            if (rows.isNotEmpty) {
              payload[table] =
                  rows.map((r) => Map<String, Object?>.from(r)).toList();
            }
          }
        }
      } finally {
        await source.close();
      }
    }
    final db = await _getDatabase();
    await db.transaction((txn) async {
      final planIds = <int, int>{};
      final exerciseIds = <int, int>{};
      final configuredPlans = (await txn.query('plan_exercises',
              columns: ['plan_id'], distinct: true))
          .map((row) => _intValue(row['plan_id']))
          .toSet();
      final configuredWarmups = (await txn.query('plan_warmup_steps',
              columns: ['plan_id'], distinct: true))
          .map((row) => _intValue(row['plan_id']))
          .toSet();
      // IDs may collide after a reinstall or between two devices. Resolve
      // references together; never attach imported logs to an unrelated name.
      for (final table in ['workout_plans', 'exercises']) {
        final idColumn = table == 'exercises' ? 'exercise_id' : 'plan_id';
        final remap = table == 'exercises' ? exerciseIds : planIds;
        final local = (await txn.query(table))
            .map((r) => Map<String, Object?>.from(r))
            .toList();
        var nextId = local.fold<int>(
            0,
            (maxId, row) => _intValue(row[idColumn]) > maxId
                ? _intValue(row[idColumn])
                : maxId);
        for (final incoming in payload[table]!) {
          final row = Map<String, Object?>.from(incoming)..remove('id');
          final originalId = _intValue(row[idColumn]);
          if (originalId <= 0 || _stringValue(row['name']).trim().isEmpty) {
            throw FormatException('Invalid $table record in backup.');
          }
          final name = _stringValue(row['name']).trim().toLowerCase();
          final named = local
              .where(
                  (r) => _stringValue(r['name']).trim().toLowerCase() == name)
              .toList();
          if (named.isNotEmpty) {
            // Names are not unique. Prefer the exact identity so two routines
            // called "Upper" do not collapse into the same history.
            final matching = named.firstWhere(
              (row) => _intValue(row[idColumn]) == originalId,
              orElse: () => named.first,
            );
            remap[originalId] = _intValue(matching[idColumn]);
            continue;
          }
          final collision =
              local.any((r) => _intValue(r[idColumn]) == originalId);
          final id = collision ? ++nextId : originalId;
          if (id > nextId) nextId = id;
          remap[originalId] = id;
          row[idColumn] = id;
          await txn.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.ignore);
          local.add(row);
        }
      }
      final batch = txn.batch();
      for (final table in [
        'plan_exercises',
        'plan_warmup_steps',
        'workout_logs',
        'workout_sessions',
        'active_session_exercise_setup_presets'
      ]) {
        for (final incoming in payload[table]!) {
          final row = Map<String, Object?>.from(incoming)..remove('id');
          final originalPlan = _intValue(row['plan_id']);
          if (row.containsKey('plan_id')) {
            row['plan_id'] = planIds[originalPlan] ?? originalPlan;
          }
          if (row.containsKey('exercise_id')) {
            final originalExercise = _intValue(row['exercise_id']);
            row['exercise_id'] =
                exerciseIds[originalExercise] ?? originalExercise;
          }
          if (table == 'plan_exercises' &&
              configuredPlans.contains(row['plan_id'])) {
            continue;
          }
          if (table == 'plan_warmup_steps' &&
              configuredWarmups.contains(row['plan_id'])) {
            continue;
          }
          if (table.startsWith('workout_')) {
            final date = DateTime.tryParse(_stringValue(row['date']));
            if (date == null ||
                _intValue(row['plan_id']) <= 0 ||
                (table == 'workout_logs' &&
                    (_intValue(row['exercise_id']) <= 0 ||
                        _intValue(row['set_number']) <= 0))) {
              throw const FormatException('Invalid workout record in backup.');
            }
            var id = _stringValue(row['session_id']);
            if (id.isEmpty || id.startsWith('legacy:')) {
              id = 'legacy:${_formatDate(date)}:${row['plan_id']}';
            } else if (originalPlan != row['plan_id']) {
              id = '$id:plan:${row['plan_id']}';
            }
            row['session_id'] = id;
            if (table == 'workout_logs' && !id.startsWith('legacy:')) {
              final existing = await txn.query(table,
                  columns: ['id'],
                  where:
                      'session_id = ? AND exercise_id = ? AND set_number = ?',
                  whereArgs: [id, row['exercise_id'], row['set_number']],
                  limit: 1);
              if (existing.isNotEmpty) {
                continue; // Current edits win over an older backup.
              }
            }
          }
          if (table == 'plan_warmup_steps') {
            final existing = await txn.query(table,
                where: 'plan_id = ? AND position = ?',
                whereArgs: [row['plan_id'], row['position']],
                limit: 1);
            if (existing.isNotEmpty) continue;
          }
          batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await batch.commit(noResult: true);
      await _repairDataIntegrity(txn, recoverMissingParents: true);
      await _setMeta(txn, _routineRuntimeSeededKey, '1');
      // A full snapshot may include an unfinished workout. Keep the current
      // draft; restore a missing one only when its catalog IDs still match.
      final idsMatch = [...planIds.entries, ...exerciseIds.entries]
          .every((entry) => entry.key == entry.value);
      if (idsMatch) {
        for (final row in payload['active_workout_session_drafts']!) {
          if (_isValidBackupDraft(_stringValue(row['payload']))) {
            await txn.insert('active_workout_session_drafts', row,
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    });
  }

  Future<String?> readMetadata(String key) async {
    return _readMeta(await _getDatabase(), key);
  }

  Future<void> writeMetadata(String key, String value) async {
    await _setMeta(await _getDatabase(), key, value);
  }

  Future<void> exportRoutineRuntimeToXlsxFiles(Directory directory) async {
    await warmUpRoutineRuntimeCache();
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await _repairDataIntegrity(txn, recoverMissingParents: true);
    });

    final plans = await db.query('workout_plans', orderBy: 'plan_id ASC');
    final exercises = await db.query('exercises', orderBy: 'exercise_id ASC');
    final planExercises = await db.query(
      'plan_exercises',
      orderBy: 'plan_id ASC, position ASC',
    );
    final warmUpSteps = await db.query(
      'plan_warmup_steps',
      orderBy: 'plan_id ASC, position ASC, id ASC',
    );

    await _writeExcelExport(directory, 'workout_plan.xlsx', [
      for (final row in plans)
        [
          _intValue(row['plan_id']),
          _stringValue(row['name']),
          _stringValue(row['frequency']),
          _boolValue(row['is_active']) ? 1 : 0,
        ],
    ]);

    await _writeExcelExport(directory, 'exercise.xlsx', [
      for (final row in exercises)
        [
          _intValue(row['exercise_id']),
          _stringValue(row['name']),
          _stringValue(row['description']),
          _stringValue(row['category']),
          _stringValue(row['main_muscle_group']),
        ],
    ]);

    await _writeExcelExport(directory, 'plan_exercise.xlsx', [
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
    ]);

    await _writeExcelExport(directory, 'warm_up_step.xlsx', [
      for (final row in warmUpSteps)
        [
          _intValue(row['plan_id']),
          _intValue(row['position']),
          _stringValue(row['name']),
          _stringValue(row['notes']),
          _intValue(row['sets']),
          _intValue(row['work_seconds']),
          _intValue(row['rest_seconds']),
          _boolValue(row['per_side']) ? 1 : 0,
        ],
    ]);
  }

  Future<void> replaceWorkoutLogsFromCurrentXlsxFiles() async {
    final db = await _getDatabase();
    final directory = await getApplicationDocumentsDirectory();
    final rows = await compute(_parseWorkoutLogSeed, directory.path);

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
      await _repairDataIntegrity(txn, recoverMissingParents: true);
    });
  }

  Future<void> replaceWorkoutSessionsFromCurrentXlsxFiles() async {
    final db = await _getDatabase();
    final directory = await getApplicationDocumentsDirectory();
    final rows = await compute(_parseWorkoutSessionSeed, directory.path);

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
      await _repairDataIntegrity(txn, recoverMissingParents: true);
    });
  }

  Future<void> _warmUpRoutineRuntimeCacheInternal({required bool force}) async {
    final db = await _getDatabase();

    if (force) {
      final directory = await getApplicationDocumentsDirectory();
      final payload = await compute(_parseRoutineRuntimeSeed, directory.path);

      final plans =
          payload[_routineSeedPlansKey] ?? const <Map<String, Object?>>[];
      final exercises =
          payload[_routineSeedExercisesKey] ?? const <Map<String, Object?>>[];
      final planExercises = payload[_routineSeedPlanExercisesKey] ??
          const <Map<String, Object?>>[];
      final warmUpSteps =
          payload[_routineSeedWarmUpStepsKey] ?? const <Map<String, Object?>>[];

      await db.transaction((txn) async {
        await txn.delete('plan_warmup_steps');
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
        for (final row in warmUpSteps) {
          batch.insert('plan_warmup_steps', row);
        }
        await batch.commit(noResult: true);

        await _setMeta(txn, _routineRuntimeSeededKey, '1');
        await _setMeta(
          txn,
          _routineRuntimeSeededAtKey,
          DateTime.now().toIso8601String(),
        );
        await _repairDataIntegrity(txn, recoverMissingParents: true);
      });
      return;
    }

    final seeded = await _readMeta(db, _routineRuntimeSeededKey);
    if (seeded == '1') {
      return;
    }

    final counts = await Future.wait<int>([
      _countRows(db, 'exercises'),
      _countRows(db, 'workout_plans'),
      _countRows(db, 'plan_exercises'),
      _countRows(db, 'workout_logs'),
      _countRows(db, 'workout_sessions'),
    ]);

    final exercisesCount = counts[0];
    final hasOtherRoutineData = counts.skip(1).any((count) => count > 0);
    if (exercisesCount > 0 || hasOtherRoutineData) {
      await _setMeta(db, _routineRuntimeSeededKey, '1');
      await _setMeta(
        db,
        _routineRuntimeSeededAtKey,
        DateTime.now().toIso8601String(),
      );
      return;
    }

    // Normal releases start empty. Fictional fixtures use main_demo.dart only.
    await _setMeta(db, _routineRuntimeSeededKey, '1');
  }

  Future<Database> _getDatabase() async {
    final current = _database;
    if (current != null && current.isOpen) {
      return current;
    }

    return _openingDatabase ??= _openDatabase().whenComplete(() {
      _openingDatabase = null;
    });
  }

  Future<Database> _openDatabase() async {
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

    try {
      await _migrateWorkoutHistoryFromExcelIfNeeded(db);
      await _repairDataIntegrity(
        db,
        recoverMissingParents: await _hasRoutineRuntimeData(db),
      );
      _database = db;
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS plan_warmup_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        name TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        sets INTEGER NOT NULL DEFAULT 1,
        work_seconds INTEGER NOT NULL DEFAULT 30,
        rest_seconds INTEGER NOT NULL DEFAULT 0,
        per_side INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_workout_session_drafts (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        updated_at TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_session_exercise_setup_presets (
        exercise_id INTEGER PRIMARY KEY,
        target_sets INTEGER NOT NULL,
        target_reps INTEGER NOT NULL,
        estimated_weight REAL NOT NULL DEFAULT 0,
        rest_seconds INTEGER NOT NULL,
        rir INTEGER NOT NULL,
        tempo TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    for (final table in ['workout_logs', 'workout_sessions']) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      if (!columns.any((row) => row['name'] == 'session_id')) {
        await db.execute(
            "ALTER TABLE $table ADD COLUMN session_id TEXT NOT NULL DEFAULT ''");
      }
      await db.execute(
          "UPDATE $table SET session_id = 'legacy:' || substr(date, 1, 10) || ':' || plan_id WHERE session_id = ''");
    }
    // Version 3 keyed sessions by day, silently dropping a second workout.
    await db.execute('DROP INDEX IF EXISTS idx_workout_sessions_unique');
    await db.execute('DROP INDEX IF EXISTS idx_workout_logs_unique');
    await _deduplicateWorkoutData(db);

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_workout_sessions_unique
      ON workout_sessions(session_id) WHERE session_id != ''
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_workout_logs_unique
      ON workout_logs(session_id, exercise_id, set_number, reps, weight, rir) WHERE session_id != ''
    ''');
    for (final table in ['workout_logs', 'workout_sessions']) {
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS ${table}_legacy_session
        AFTER INSERT ON $table WHEN NEW.session_id = ''
        BEGIN
          UPDATE $table SET session_id = 'legacy:' || substr(NEW.date, 1, 10) || ':' || NEW.plan_id WHERE id = NEW.id;
        END
      ''');
    }

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_plan_exercises_unique
      ON plan_exercises(plan_id, exercise_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_logs_plan_date
      ON workout_logs(plan_id, date)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_logs_exercise_date
      ON workout_logs(exercise_id, date)
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

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_plan_warmup_steps_plan_position
      ON plan_warmup_steps(plan_id, position)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_workout_sessions_plan_date
      ON workout_sessions(plan_id, date)
    ''');
  }

  Future<void> _deduplicateWorkoutData(DatabaseExecutor db) async {
    await db.execute('''
      DELETE FROM workout_logs
      WHERE plan_id <= 0
        OR exercise_id <= 0
        OR set_number <= 0
        OR TRIM(date) = ''
    ''');

    await db.execute('''
      DELETE FROM workout_sessions
      WHERE plan_id <= 0
        OR TRIM(date) = ''
    ''');

    await db.execute('''
      DELETE FROM plan_exercises
      WHERE plan_id <= 0
        OR exercise_id <= 0
    ''');

    await db.execute('''
      DELETE FROM workout_sessions
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM workout_sessions
        GROUP BY session_id
      )
    ''');

    await db.execute('''
      DELETE FROM workout_logs
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM workout_logs
        GROUP BY session_id, exercise_id, set_number, reps, weight, rir
      )
    ''');

    await db.execute('''
      DELETE FROM plan_exercises
      WHERE rowid NOT IN (
        SELECT MIN(rowid)
        FROM plan_exercises
        GROUP BY plan_id, exercise_id
      )
    ''');
  }

  Future<void> _repairDataIntegrity(
    DatabaseExecutor db, {
    required bool recoverMissingParents,
  }) async {
    await _deduplicateWorkoutData(db);

    if (recoverMissingParents) {
      await db.execute('''
        INSERT OR IGNORE INTO workout_plans (
          plan_id,
          name,
          frequency,
          is_active
        )
        SELECT
          missing.plan_id,
          'Recovered Plan ' || missing.plan_id,
          'Recovered from imported data',
          0
        FROM (
          SELECT DISTINCT plan_id FROM workout_logs WHERE plan_id > 0
          UNION
          SELECT DISTINCT plan_id FROM workout_sessions WHERE plan_id > 0
          UNION
          SELECT DISTINCT plan_id FROM plan_exercises WHERE plan_id > 0
        ) AS missing
        WHERE NOT EXISTS (
          SELECT 1
          FROM workout_plans plans
          WHERE plans.plan_id = missing.plan_id
        )
      ''');

      await db.execute('''
        INSERT OR IGNORE INTO exercises (
          exercise_id,
          name,
          description,
          category,
          main_muscle_group
        )
        SELECT
          missing.exercise_id,
          'Recovered Exercise ' || missing.exercise_id,
          'Recovered from imported workout data.',
          'Recovered',
          'Unknown'
        FROM (
          SELECT DISTINCT exercise_id FROM workout_logs WHERE exercise_id > 0
          UNION
          SELECT DISTINCT exercise_id FROM plan_exercises WHERE exercise_id > 0
        ) AS missing
        WHERE NOT EXISTS (
          SELECT 1
          FROM exercises exercises
          WHERE exercises.exercise_id = missing.exercise_id
        )
      ''');
    }

    await db.execute('''
      DELETE FROM plan_exercises
      WHERE NOT EXISTS (
        SELECT 1
        FROM workout_plans plans
        WHERE plans.plan_id = plan_exercises.plan_id
      )
      OR NOT EXISTS (
        SELECT 1
        FROM exercises exercises
        WHERE exercises.exercise_id = plan_exercises.exercise_id
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
      final logs = await compute(_parseWorkoutLogSeed, directory.path);
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
      final sessions = await compute(_parseWorkoutSessionSeed, directory.path);
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

  Future<bool> _hasRoutineRuntimeData(DatabaseExecutor db) async {
    final counts = await Future.wait<int>([
      _countRows(db, 'workout_plans'),
      _countRows(db, 'exercises'),
      _countRows(db, 'plan_exercises'),
    ]);
    return counts.any((count) => count > 0);
  }

  Future<void> _validateRequiredTables(DatabaseExecutor db) async {
    final rows = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final tables = rows
        .map((row) => _stringValue(row['name']))
        .where((name) => name.isNotEmpty)
        .toSet();
    final missingTables = [
      for (final table in _requiredDatabaseTables)
        if (!tables.contains(table)) table,
    ];
    if (missingTables.isNotEmpty) {
      throw FormatException(
        'Backup database is missing tables: ${missingTables.join(', ')}',
      );
    }
  }

  Future<bool> _hasUsableDateRows(String table) async {
    final db = await _getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count, MIN(date) AS min_date, MAX(date) AS max_date '
      'FROM $table',
    );
    if (result.isEmpty) {
      return false;
    }

    final row = result.first;
    final count = _intValue(row['count']);
    if (count <= 0) {
      return false;
    }

    final minDate = DateTime.tryParse(_stringValue(row['min_date']));
    final maxDate = DateTime.tryParse(_stringValue(row['max_date']));
    return minDate != null && maxDate != null;
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

  Future<void> _setMeta(DatabaseExecutor db, String key, String value) async {
    await db.insert(
        'storage_meta',
        {
          'key': key,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
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

  WarmUpStep _mapWarmUpStepRow(Map<String, Object?> row) {
    return WarmUpStep(
      id: _intValue(row['id']),
      name: _stringValue(row['name']),
      notes: _stringValue(row['notes']),
      sets: _intValue(row['sets']),
      workSeconds: _intValue(row['work_seconds']),
      restSeconds: _intValue(row['rest_seconds']),
      perSide: _boolValue(row['per_side']),
    );
  }

  ActiveSessionExerciseSetupPreset _mapActiveSessionExerciseSetupPresetRow(
    Map<String, Object?> row,
  ) {
    return ActiveSessionExerciseSetupPreset(
      exerciseId: _intValue(row['exercise_id']),
      sets: _intValue(row['target_sets']),
      reps: _intValue(row['target_reps']),
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

  Map<String, Object?> _warmUpStepRow(
    int planId,
    WarmUpStep step, {
    required int position,
  }) {
    return {
      'plan_id': planId,
      'position': position,
      'name': step.name.trim(),
      'notes': step.notes.trim(),
      'sets': step.sets,
      'work_seconds': step.workSeconds,
      'rest_seconds': step.restSeconds,
      'per_side': step.perSide ? 1 : 0,
    };
  }
}

const String _routineSeedPlansKey = 'plans';
Map<String, List<Map<String, Object?>>> _parseBackupSheets(
    String directoryPath) {
  final routine = _parseRoutineRuntimeSeed(directoryPath);
  return {
    'workout_plans': routine[_routineSeedPlansKey]!,
    'exercises': routine[_routineSeedExercisesKey]!,
    'plan_exercises': routine[_routineSeedPlanExercisesKey]!,
    'plan_warmup_steps': routine[_routineSeedWarmUpStepsKey]!,
    'workout_logs': _parseWorkoutLogSeed(directoryPath),
    'workout_sessions': _parseWorkoutSessionSeed(directoryPath),
    'active_session_exercise_setup_presets': [],
    'active_workout_session_drafts': [],
  };
}

String _importSessionId(
    List<Data?> row, Map<String, int> headers, String date, int planId) {
  final supplied =
      _stringValue(_headerValue(row, headers, ['workout_session_key'])).trim();
  if (supplied.isNotEmpty) return supplied;
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    throw const FormatException('Invalid workout date in backup.');
  }
  return workoutSessionId(parsed, planId);
}

const String _routineSeedExercisesKey = 'exercises';
const String _routineSeedPlanExercisesKey = 'plan_exercises';
const String _routineSeedWarmUpStepsKey = 'warm_up_steps';

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

  final exerciseDescriptionsById = <int, String>{
    for (final row in normalizedExercises)
      _intValue(row['exercise_id']): _stringValue(row['description']),
  };

  final normalizedPlanExercises = _parsePlanExerciseSeed(
    directoryPath,
    idRemap: idRemap,
    exerciseDescriptionsById: exerciseDescriptionsById,
  );
  final warmUpSteps = _parseWarmUpStepSeed(directoryPath);

  return {
    _routineSeedPlansKey: planRows,
    _routineSeedExercisesKey: normalizedExercises,
    _routineSeedPlanExercisesKey: normalizedPlanExercises,
    _routineSeedWarmUpStepsKey: warmUpSteps,
  };
}

List<Map<String, Object?>> _parseWarmUpStepSeed(String directoryPath) {
  const filename = 'warm_up_step.xlsx';
  final schema = kTableSchemas[filename];
  if (schema == null) return const [];
  final sheet =
      _readSheet(path.join(directoryPath, filename), schema.sheetName);
  if (sheet == null || sheet.rows.isEmpty) return const [];

  final headers = _headerIndexMap(sheet.rows.first);
  final rows = <Map<String, Object?>>[];
  for (final row in sheet.rows.skip(1)) {
    final planId = _intValueOrNull(_headerValue(row, headers, ['plan_id']));
    final name = _stringValue(_headerValue(row, headers, ['name'])).trim();
    final sets = _intValue(_headerValue(row, headers, ['sets']));
    final workSeconds = _intValue(
      _headerValue(row, headers, ['work_seconds']),
    );
    if (planId == null ||
        planId <= 0 ||
        name.isEmpty ||
        sets <= 0 ||
        workSeconds <= 0) {
      continue;
    }
    rows.add({
      'plan_id': planId,
      'position': _intValue(_headerValue(row, headers, ['position'])),
      'name': name,
      'notes': _stringValue(_headerValue(row, headers, ['notes'])),
      'sets': sets,
      'work_seconds': workSeconds,
      'rest_seconds': _intValue(
        _headerValue(row, headers, ['rest_seconds']),
      ),
      'per_side': _boolValue(_headerValue(row, headers, ['per_side'])) ? 1 : 0,
    });
  }
  return rows;
}

List<Map<String, Object?>> _parseWorkoutPlanSeed(String directoryPath) {
  final sheet = _readSheet(
    path.join(directoryPath, 'workout_plan.xlsx'),
    kTableSchemas['workout_plan.xlsx']!.sheetName,
  );
  if (sheet == null || sheet.rows.isEmpty) {
    return const [];
  }

  final headers = _headerIndexMap(sheet.rows.first);
  final rows = <Map<String, Object?>>[];
  for (final row in sheet.rows.skip(1)) {
    final planId = _intValueOrNull(_headerValue(row, headers, ['plan_id']));
    if (planId == null || planId <= 0) {
      continue;
    }

    rows.add({
      'plan_id': planId,
      'name': _stringValue(_headerValue(row, headers, ['name'])),
      'frequency': _stringValue(_headerValue(row, headers, ['frequency'])),
      'is_active':
          _boolValue(_headerValue(row, headers, ['is_active'])) ? 1 : 0,
    });
  }
  return rows;
}

List<Map<String, Object?>> _parseExerciseSeed(String directoryPath) {
  final sheet = _readSheet(
    path.join(directoryPath, 'exercise.xlsx'),
    kTableSchemas['exercise.xlsx']!.sheetName,
  );
  if (sheet == null || sheet.rows.isEmpty) {
    return const [];
  }

  final headers = _headerIndexMap(sheet.rows.first);
  final rows = <Map<String, Object?>>[];
  for (final row in sheet.rows.skip(1)) {
    final exerciseId = _intValueOrNull(
      _headerValue(row, headers, ['exercise_id']),
    );
    if (exerciseId == null || exerciseId <= 0) {
      continue;
    }

    rows.add({
      'exercise_id': exerciseId,
      'name': _stringValue(_headerValue(row, headers, ['name'])),
      'description': _stringValue(_headerValue(row, headers, ['description'])),
      'category': _stringValue(_headerValue(row, headers, ['category'])),
      'main_muscle_group': _stringValue(
        _headerValue(row, headers, ['main_muscle_group']),
      ),
    });
  }
  return rows;
}

List<Map<String, Object?>> _parsePlanExerciseSeed(
  String directoryPath, {
  required Map<int, int> idRemap,
  required Map<int, String> exerciseDescriptionsById,
}) {
  final sheet = _readSheet(
    path.join(directoryPath, 'plan_exercise.xlsx'),
    kTableSchemas['plan_exercise.xlsx']!.sheetName,
  );
  if (sheet == null || sheet.rows.isEmpty) {
    return const [];
  }

  final headers = _headerIndexMap(sheet.rows.first);
  final positionsByPlan = <int, int>{};
  final rows = <Map<String, Object?>>[];
  for (final row in sheet.rows.skip(1)) {
    final planId = _intValueOrNull(_headerValue(row, headers, ['plan_id']));
    final originalExerciseId = _intValueOrNull(
      _headerValue(row, headers, ['exercise_id']),
    );
    if (planId == null ||
        planId <= 0 ||
        originalExerciseId == null ||
        originalExerciseId <= 0) {
      continue;
    }

    final exerciseId = idRemap[originalExerciseId] ?? originalExerciseId;
    final nextPosition = positionsByPlan.update(
      planId,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    final exerciseDescription = exerciseDescriptionsById[exerciseId] ?? '';

    rows.add({
      'plan_id': planId,
      'exercise_id': exerciseId,
      'position': nextPosition,
      'suggested_sets': _intValue(
        _headerValue(row, headers, ['suggested_sets']),
      ),
      'suggested_reps': _intValue(
        _headerValue(row, headers, ['suggested_reps']),
      ),
      'estimated_weight': _doubleValue(
        _headerValue(row, headers, ['estimated_weight']),
      ),
      'rest_seconds': _intValue(_headerValue(row, headers, ['rest_seconds'])),
      'rir': _resolveRoutineRir(
        canonicalRirValue: _headerValue(row, headers, ['rir']),
        legacyTargetRirValue: _headerValue(row, headers, ['target_rir']),
        legacyImagePathValue: _headerValue(row, headers, ['image_path']),
        exerciseDescription: exerciseDescription,
      ),
      'tempo': _resolveRoutineTempo(
        canonicalTempoValue: _headerValue(row, headers, ['tempo']),
        legacyTargetRirValue: _headerValue(row, headers, ['target_rir']),
        legacyImagePathValue: _headerValue(row, headers, ['image_path']),
        exerciseDescription: exerciseDescription,
      ),
      'image_path': _resolveRoutineImagePath(
        _headerValue(row, headers, ['image_path']),
      ),
    });
  }

  return rows;
}

List<Map<String, Object?>> _parseWorkoutLogSeed(String directoryPath) {
  const filename = 'workout_log.xlsx';
  final sheet = _readSheet(
    path.join(directoryPath, filename),
    kTableSchemas[filename]!.sheetName,
  );
  final sheetRows = sheet?.rows;
  if (sheetRows == null || sheetRows.isEmpty) {
    return const [];
  }

  final headers = _headerIndexMap(sheetRows.first);
  _requireHeaderGroups(filename, headers, const {
    'date': ['date'],
    'plan_id': ['plan_id'],
    'exercise_id': ['exercise_id'],
    'set_number': ['set_number'],
    'reps_completed': ['reps_completed', 'reps'],
    'weight_used': ['weight_used', 'weight'],
    'RIR': ['rir'],
  });

  final rows = <Map<String, Object?>>[];
  for (var index = 1; index < sheetRows.length; index++) {
    final row = sheetRows[index];
    if (_isBlankExcelRow(row)) {
      continue;
    }

    final date = _stringValue(_headerValue(row, headers, ['date'])).trim();
    final planId = _intValueOrNull(_headerValue(row, headers, ['plan_id']));
    final exerciseId = _intValueOrNull(
      _headerValue(row, headers, ['exercise_id']),
    );
    final setNumber = _intValueOrNull(
      _headerValue(row, headers, ['set_number']),
    );
    final reps = _intValueOrNull(
      _headerValue(row, headers, ['reps_completed', 'reps']),
    );
    final weight = _doubleValue(
      _headerValue(row, headers, ['weight_used', 'weight']),
    );
    final rir = _intValueOrNull(_headerValue(row, headers, ['rir']));

    if (date.isEmpty ||
        planId == null ||
        planId <= 0 ||
        exerciseId == null ||
        exerciseId <= 0 ||
        setNumber == null ||
        setNumber <= 0 ||
        reps == null ||
        rir == null) {
      throw FormatException('Invalid $filename row ${index + 1}.');
    }

    rows.add({
      'date': date,
      'session_id': _importSessionId(row, headers, date, planId),
      'plan_id': planId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
      'rir': rir,
    });
  }
  return rows;
}

List<Map<String, Object?>> _parseWorkoutSessionSeed(String directoryPath) {
  const filename = 'workout_session.xlsx';
  final sheet = _readSheet(
    path.join(directoryPath, filename),
    kTableSchemas[filename]!.sheetName,
  );
  final sheetRows = sheet?.rows;
  if (sheetRows == null || sheetRows.isEmpty) {
    return const [];
  }

  final headers = _headerIndexMap(sheetRows.first);
  _requireHeaderGroups(filename, headers, const {
    'date': ['date'],
    'plan_id': ['plan_id'],
    'fatigue_level': ['fatigue_level'],
    'duration_minutes': ['duration_minutes'],
    'mood': ['mood'],
    'notes': ['notes'],
  });

  final rows = <Map<String, Object?>>[];
  for (var index = 1; index < sheetRows.length; index++) {
    final row = sheetRows[index];
    if (_isBlankExcelRow(row)) {
      continue;
    }

    final date = _stringValue(_headerValue(row, headers, ['date'])).trim();
    final planId = _intValueOrNull(_headerValue(row, headers, ['plan_id']));
    final durationMinutes = _intValueOrNull(
      _headerValue(row, headers, ['duration_minutes']),
    );

    if (date.isEmpty ||
        planId == null ||
        planId <= 0 ||
        durationMinutes == null) {
      throw FormatException('Invalid $filename row ${index + 1}.');
    }

    rows.add({
      'date': date,
      'session_id': _importSessionId(row, headers, date, planId),
      'plan_id': planId,
      'fatigue_level': _stringValue(
        _headerValue(row, headers, ['fatigue_level']),
      ),
      'duration_minutes': durationMinutes,
      'mood': _stringValue(_headerValue(row, headers, ['mood'])),
      'notes': _stringValue(_headerValue(row, headers, ['notes'])),
    });
  }
  return rows;
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
  return excel.tables[sheetName];
}

Map<String, int> _headerIndexMap(List<Data?> headerRow) {
  final headers = <String, int>{};
  for (var index = 0; index < headerRow.length; index++) {
    final header = _normalizeHeaderName(
      _stringValue(_excelValueAt(headerRow, index)),
    );
    if (header.isEmpty || headers.containsKey(header)) {
      continue;
    }
    headers[header] = index;
  }
  return headers;
}

Object? _headerValue(
  List<Data?> row,
  Map<String, int> headers,
  List<String> candidateHeaders,
) {
  for (final candidate in candidateHeaders) {
    final index = headers[_normalizeHeaderName(candidate)];
    if (index != null) {
      return _excelValueAt(row, index);
    }
  }
  return null;
}

void _requireHeaderGroups(
  String filename,
  Map<String, int> headers,
  Map<String, List<String>> requiredHeaders,
) {
  final missingHeaders = <String>[];
  for (final entry in requiredHeaders.entries) {
    final hasHeader = entry.value.any(
      (header) => headers.containsKey(_normalizeHeaderName(header)),
    );
    if (!hasHeader) {
      missingHeaders.add(entry.key);
    }
  }
  if (missingHeaders.isNotEmpty) {
    throw FormatException(
      'Invalid $filename: missing columns ${missingHeaders.join(', ')}.',
    );
  }
}

bool _isBlankExcelRow(List<Data?> row) {
  for (var index = 0; index < row.length; index++) {
    if (_stringValue(_excelValueAt(row, index)).trim().isNotEmpty) {
      return false;
    }
  }
  return true;
}

String _normalizeHeaderName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
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
  if (value == null) {
    return TextCellValue('');
  }
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

int? _intValueOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return int.tryParse(text);
}

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

String? _stringValueOrNull(Object? value) {
  final text = _stringValue(value).trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
}

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

int _resolveRoutineRir({
  required Object? canonicalRirValue,
  required Object? legacyTargetRirValue,
  required Object? legacyImagePathValue,
  required String exerciseDescription,
}) {
  final canonicalRir = _intValueOrNull(canonicalRirValue);
  if (canonicalRir != null) {
    return canonicalRir;
  }

  final legacyTargetRir = _intValueOrNull(legacyTargetRirValue);
  if (legacyTargetRir != null) {
    return legacyTargetRir;
  }

  final legacyImagePathRir = _intValueOrNull(legacyImagePathValue);
  if (legacyImagePathRir != null) {
    return legacyImagePathRir;
  }

  final descriptionRir = _extractRirFromDescription(exerciseDescription);
  if (descriptionRir != null) {
    return descriptionRir;
  }

  return 2;
}

String _resolveRoutineTempo({
  required Object? canonicalTempoValue,
  required Object? legacyTargetRirValue,
  required Object? legacyImagePathValue,
  required String exerciseDescription,
}) {
  final canonicalTempo = _normalizeTempoValue(canonicalTempoValue);
  if (canonicalTempo != null) {
    return canonicalTempo;
  }

  final legacyTargetRirTempo = _normalizeTempoValue(legacyTargetRirValue);
  if (legacyTargetRirTempo != null) {
    return legacyTargetRirTempo;
  }

  final legacyImagePathTempo = _normalizeTempoValue(legacyImagePathValue);
  if (legacyImagePathTempo != null) {
    return legacyImagePathTempo;
  }

  final descriptionTempo = _extractTempoFromDescription(exerciseDescription);
  return descriptionTempo ?? '3-1-1-0';
}

String _resolveRoutineImagePath(Object? value) {
  final imagePath = _stringValueOrNull(value);
  if (imagePath == null) {
    return '';
  }

  if (_looksLikePath(imagePath)) {
    return imagePath;
  }

  return '';
}

String? _normalizeTempoValue(Object? value) {
  final text = _stringValueOrNull(value);
  if (text == null) {
    return null;
  }

  final normalized = text.toLowerCase().replaceAll('–', '-');
  final match = RegExp(
    r'(?:tempo\s*)?([0-9]+\s*-\s*[0-9]+\s*-\s*[0-9]+\s*-\s*[0-9]+)',
  ).firstMatch(normalized);
  if (match == null) {
    return null;
  }

  return _normalizeTempoString(match.group(1)!);
}

String? _extractTempoFromDescription(String description) {
  if (description.trim().isEmpty) {
    return null;
  }

  final tempo = _normalizeTempoValue(description);
  if (tempo != null) {
    return tempo;
  }

  final fallback = RegExp(
    r'([0-9]+\s*-\s*[0-9]+\s*-\s*[0-9]+\s*-\s*[0-9]+)',
  ).firstMatch(description.toLowerCase().replaceAll('–', '-'));
  if (fallback == null) {
    return null;
  }

  return _normalizeTempoString(fallback.group(1)!);
}

int? _extractRirFromDescription(String description) {
  if (description.trim().isEmpty) {
    return null;
  }

  final match = RegExp(
    r'(?:target\s*)?rir[^0-9]*([0-9]+)',
  ).firstMatch(description.toLowerCase());
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }

  return null;
}

String _normalizeTempoString(String value) {
  return value.replaceAll('–', '-').replaceAll(RegExp(r'\s+'), '');
}

bool _looksLikePath(String value) {
  if (value.contains('/') || value.contains('\\')) {
    return true;
  }
  final lower = value.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.bmp');
}

bool _isValidBackupDraft(String payload) {
  try {
    final decoded = jsonDecode(payload);
    return decoded is Map &&
        ActiveWorkoutSessionDraft.fromJson(
                decoded.map((key, value) => MapEntry('$key', value))) !=
            null;
  } catch (_) {
    return false;
  }
}
