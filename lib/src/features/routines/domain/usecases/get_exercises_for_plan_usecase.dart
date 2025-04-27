import '../repositories/workout_plan_repository.dart';
import '../entities/exercise.dart';

class GetExercisesForPlanUseCase {
  final WorkoutPlanRepository _repo;
  const GetExercisesForPlanUseCase(this._repo);

  Future<List<Exercise>> call(int planId) => _repo.getExercisesForPlan(planId);
}
