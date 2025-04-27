import '../repositories/workout_history_repository.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';

class GetWorkoutLogsUseCase {
  final WorkoutHistoryRepository _repo;
  const GetWorkoutLogsUseCase(this._repo);
  Future<List<WorkoutLogEntry>> call() => _repo.getAllLogs();
}