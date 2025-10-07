import 'package:sqflite/sqflite.dart';
import '../../../../data/sqlite/app_database.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workout_plan_repository.dart';

class WorkoutPlanRepositorySqlite implements WorkoutPlanRepository {
  Future<Database> get _db async => AppDatabase.instance;

  Exercise _mapExercise(Map<String, Object?> row) => Exercise(
        id: (row['id'] as int?) ?? 0,
        name: (row['name'] as String?) ?? '',
        description: (row['description'] as String?) ?? '',
        category: (row['category'] as String?) ?? '',
        mainMuscleGroup: (row['main_muscle_group'] as String?) ?? '',
      );

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    final db = await _db;
    final rows = await db.query('workout_plan', orderBy: 'id');
    return rows
        .map((r) => WorkoutPlan(
              id: (r['id'] as int?) ?? 0,
              name: (r['name'] as String?) ?? '',
              frequency: (r['frequency'] as String?) ?? '',
            ))
        .toList();
  }

  @override
  Future<List<Exercise>> getExercisesForPlan(int planId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT e.* FROM plan_exercise pe
      JOIN exercise e ON e.id = pe.exercise_id
      WHERE pe.plan_id = ?
      ORDER BY pe.position
    ''', [planId]);
    return rows.map(_mapExercise).toList();
  }

  @override
  Future<List<Exercise>> getAllExercises() async {
    final db = await _db;
    final rows = await db.query('exercise', orderBy: 'name');
    return rows.map(_mapExercise).toList();
  }

  @override
  Future<List<Exercise>> getSimilarExercises(int exerciseId) async {
    final db = await _db;
    final group = await db.query('exercise',
        columns: ['main_muscle_group'], where: 'id = ?', whereArgs: [exerciseId]);
    if (group.isEmpty) return [];
    final rows = await db.query('exercise',
        where: 'main_muscle_group = ? AND id != ?',
        whereArgs: [group.first['main_muscle_group'], exerciseId]);
    return rows.map(_mapExercise).toList();
  }

  @override
  Future<void> createExercise(
      String name, String description, String category, String group) async {
    final db = await _db;
    await db.insert('exercise', {
      'name': name,
      'description': description,
      'category': category,
      'main_muscle_group': group,
    });
  }

  @override
  Future<void> updateExercise(int id, String name, String description,
      String category, String group) async {
    final db = await _db;
    await db.update(
      'exercise',
      {
        'name': name,
        'description': description,
        'category': category,
        'main_muscle_group': group,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> createWorkoutPlan(String name, String frequency) async {
    final db = await _db;
    await db.insert('workout_plan', {
      'name': name,
      'frequency': frequency,
    });
  }

  @override
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT pe.*, e.name, e.description FROM plan_exercise pe
      JOIN exercise e ON e.id = pe.exercise_id
      WHERE pe.plan_id = ?
      ORDER BY pe.position
    ''', [planId]);
    return rows
        .map((r) => PlanExerciseDetail(
              exerciseId: (r['exercise_id'] as int?) ?? 0,
              name: (r['name'] as String?) ?? '',
              description: (r['description'] as String?) ?? '',
              sets: (r['suggested_sets'] as int?) ?? 0,
              reps: (r['suggested_reps'] as int?) ?? 0,
              weight: (r['estimated_weight'] as num?)?.toDouble() ?? 0,
              restSeconds: (r['rest_seconds'] as int?) ?? 0,
            ))
        .toList();
  }

  @override
  Future<void> addExerciseToPlan(int planId, PlanExerciseDetail detail,
      {int? position}) async {
    final db = await _db;
    final maxPosRes = await db.rawQuery(
      'SELECT MAX(position) as m FROM plan_exercise WHERE plan_id = ?',
      [planId],
    );
    final maxPos = maxPosRes.first['m'] as int? ?? -1;
    final insertPos = (position ?? maxPos + 1).clamp(0, maxPos + 1);
    await db.transaction((txn) async {
      await txn.rawUpdate(
          'UPDATE plan_exercise SET position = position + 1 WHERE plan_id = ? AND position >= ?',
          [planId, insertPos]);
      await txn.insert('plan_exercise', {
        'plan_id': planId,
        'exercise_id': detail.exerciseId,
        'suggested_sets': detail.sets,
        'suggested_reps': detail.reps,
        'estimated_weight': detail.weight,
        'rest_seconds': detail.restSeconds,
        'position': insertPos,
        'image_path': null,
      });
    });
  }

  @override
  Future<void> updateExerciseInPlan(int planId, PlanExerciseDetail detail) async {
    final db = await _db;
    await db.update(
      'plan_exercise',
      {
        'suggested_sets': detail.sets,
        'suggested_reps': detail.reps,
        'estimated_weight': detail.weight,
        'rest_seconds': detail.restSeconds,
      },
      where: 'plan_id = ? AND exercise_id = ?',
      whereArgs: [planId, detail.exerciseId],
    );
  }

  @override
  Future<void> deleteExerciseFromPlan(int planId, int exerciseId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final posRes = await txn.query(
        'plan_exercise',
        columns: ['position'],
        where: 'plan_id = ? AND exercise_id = ?',
        whereArgs: [planId, exerciseId],
      );
      if (posRes.isEmpty) {
        return;
      }
      final pos = posRes.first['position'] as int? ?? 0;
      await txn.delete('plan_exercise',
          where: 'plan_id = ? AND exercise_id = ?',
          whereArgs: [planId, exerciseId]);
      await txn.rawUpdate(
          'UPDATE plan_exercise SET position = position - 1 WHERE plan_id = ? AND position > ?',
          [planId, pos]);
    });
  }

  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {
    if (logs.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (final l in logs) {
      batch.insert('workout_log', {
        'date': l.date.toIso8601String().split('T').first,
        'plan_id': l.planId,
        'exercise_id': l.exerciseId,
        'set_number': l.setNumber,
        'reps': l.reps,
        'weight': l.weight,
        'rir': l.rir,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveWorkoutSession(WorkoutSession s) async {
    final db = await _db;
    await db.insert('workout_session', {
      'date': s.date.toIso8601String().split('T').first,
      'plan_id': s.planId,
      'fatigue_level': s.fatigueLevel,
      'duration_minutes': s.durationMinutes,
      'mood': s.mood,
      'notes': s.notes,
    });
  }
}
