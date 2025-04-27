import '../repositories/workout_plan_repository.dart';
import '../entities/workout_plan.dart';

class GetWorkoutPlansUseCase {
  final WorkoutPlanRepository _repo;
  const GetWorkoutPlansUseCase(this._repo);

  Future<List<WorkoutPlan>> call() => _repo.getAllPlans();
}
