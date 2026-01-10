import '../repositories/workout_plan_repository.dart';

class UpdateWorkoutPlanNameUseCase {
  final WorkoutPlanRepository _repo;

  UpdateWorkoutPlanNameUseCase(this._repo);

  Future<void> call(int planId, String name) {
    return _repo.updateWorkoutPlanName(planId, name);
  }
}
