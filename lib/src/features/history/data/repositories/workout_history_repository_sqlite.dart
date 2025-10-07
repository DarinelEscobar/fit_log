import 'package:sqflite/sqflite.dart';
import '../../../../data/sqlite/app_database.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_session.dart';
import '../../domain/repositories/workout_history_repository.dart';

class WorkoutHistoryRepositorySqlite implements WorkoutHistoryRepository {
  Future<Database> get _db async => AppDatabase.instance;

  @override
  Future<List<WorkoutSession>> getAllSessions() async {
    final db = await _db;
    final rows = await db.query('workout_session', orderBy: 'date');
    return rows
        .map((r) => WorkoutSession(
              planId: (r['plan_id'] as int?) ?? 0,
              date: DateTime.tryParse((r['date'] as String?) ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              fatigueLevel: (r['fatigue_level'] as String?) ?? '',
              durationMinutes: (r['duration_minutes'] as int?) ?? 0,
              mood: (r['mood'] as String?) ?? '',
              notes: (r['notes'] as String?) ?? '',
            ))
        .toList();
  }

  @override
  Future<List<WorkoutLogEntry>> getAllLogs() async {
    final db = await _db;
    final rows = await db.query('workout_log', orderBy: 'date');
    return rows
        .map((r) => WorkoutLogEntry(
              date: DateTime.tryParse((r['date'] as String?) ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              planId: (r['plan_id'] as int?) ?? 0,
              exerciseId: (r['exercise_id'] as int?) ?? 0,
              setNumber: (r['set_number'] as int?) ?? 0,
              reps: (r['reps'] as int?) ?? 0,
              weight: (r['weight'] as num?)?.toDouble() ?? 0,
              rir: (r['rir'] as int?) ?? 0,
            ))
        .toList();
  }
}
