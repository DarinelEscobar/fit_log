// lib/src/features/routines/domain/usecases/save_workout_session_usecase.dart
import '../repositories/workout_plan_repository.dart';
import '../entities/workout_session.dart';

class SaveWorkoutSessionUseCase {
  final WorkoutPlanRepository _repo;
  const SaveWorkoutSessionUseCase(this._repo);
  Future<void> call(WorkoutSession session) =>
      _repo.saveWorkoutSession(session);
}
