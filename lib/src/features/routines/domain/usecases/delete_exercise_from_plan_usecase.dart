import '../repositories/workout_plan_repository.dart';

class DeleteExerciseFromPlanUseCase {
  final WorkoutPlanRepository _repo;
  const DeleteExerciseFromPlanUseCase(this._repo);

  Future<void> call(int planId, int exerciseId) {
    return _repo.deleteExerciseFromPlan(planId, exerciseId);
  }
}
