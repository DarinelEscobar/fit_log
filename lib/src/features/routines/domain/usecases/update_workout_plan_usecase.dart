import '../repositories/workout_plan_repository.dart';

class UpdateWorkoutPlanUseCase {
  final WorkoutPlanRepository _repo;
  const UpdateWorkoutPlanUseCase(this._repo);

  Future<void> call(int planId, String name, String frequency) {
    return _repo.updateWorkoutPlan(planId, name, frequency);
  }
}
