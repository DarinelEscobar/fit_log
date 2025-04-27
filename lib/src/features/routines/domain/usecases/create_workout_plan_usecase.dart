import '../repositories/workout_plan_repository.dart';

class CreateWorkoutPlanUseCase {
  final WorkoutPlanRepository _repo;
  const CreateWorkoutPlanUseCase(this._repo);

  Future<void> call(String name, String frequency) {
    return _repo.createWorkoutPlan(name, frequency);
  }
}
