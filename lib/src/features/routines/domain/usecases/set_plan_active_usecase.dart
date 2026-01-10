import '../repositories/workout_plan_repository.dart';

class SetPlanActiveUseCase {
  final WorkoutPlanRepository _repo;
  const SetPlanActiveUseCase(this._repo);

  Future<void> call(int planId, bool isActive) {
    return _repo.setPlanActive(planId, isActive);
  }
}
