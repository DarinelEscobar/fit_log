import '../repositories/workout_history_repository.dart';
import '../../../routines/domain/entities/workout_session.dart';

class GetWorkoutSessionsUseCase {
  final WorkoutHistoryRepository _repo;
  const GetWorkoutSessionsUseCase(this._repo);
  Future<List<WorkoutSession>> call() => _repo.getAllSessions();
}