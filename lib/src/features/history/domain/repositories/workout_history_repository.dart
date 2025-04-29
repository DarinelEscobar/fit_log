import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_session.dart';

abstract class WorkoutHistoryRepository {
  Future<List<WorkoutSession>> getAllSessions();
  Future<List<WorkoutLogEntry>> getAllLogs();
}