import '../repositories/workout_plan_repository.dart';
import '../entities/plan_exercise_detail.dart';

class UpdateExerciseInPlanUseCase {
  final WorkoutPlanRepository _repo;
  const UpdateExerciseInPlanUseCase(this._repo);

  Future<void> call(int planId, PlanExerciseDetail detail) {
    return _repo.updateExerciseInPlan(planId, detail);
  }
}
