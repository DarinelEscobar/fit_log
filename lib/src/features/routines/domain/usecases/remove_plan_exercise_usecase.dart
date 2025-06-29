import '../repositories/workout_plan_repository.dart';

class RemovePlanExerciseUseCase {
  final WorkoutPlanRepository _repo;
  const RemovePlanExerciseUseCase(this._repo);

  Future<void> call(int planId, int exerciseId) {
    return _repo.removePlanExercise(planId, exerciseId);
  }
}
