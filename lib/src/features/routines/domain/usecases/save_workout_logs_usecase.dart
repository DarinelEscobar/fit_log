// lib/src/features/routines/domain/usecases/save_workout_logs_usecase.dart
import '../repositories/workout_plan_repository.dart';
import '../entities/workout_log_entry.dart';

class SaveWorkoutLogsUseCase {
  final WorkoutPlanRepository _repo;
  const SaveWorkoutLogsUseCase(this._repo);
  Future<void> call(List<WorkoutLogEntry> logs) => _repo.saveWorkoutLogs(logs);
}
