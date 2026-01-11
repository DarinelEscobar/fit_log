import '../repositories/workout_plan_repository.dart';

class SetWorkoutPlanActiveUseCase {
  final WorkoutPlanRepository _repo;
  const SetWorkoutPlanActiveUseCase(this._repo);

  Future<void> call(int planId, bool isActive) {
    return _repo.setWorkoutPlanActive(planId, isActive);
  }
}
