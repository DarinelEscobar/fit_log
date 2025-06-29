import '../repositories/workout_plan_repository.dart';
import '../entities/plan_exercise_detail.dart';

class AddExerciseToPlanUseCase {
  final WorkoutPlanRepository _repo;
  const AddExerciseToPlanUseCase(this._repo);

  Future<void> call(int planId, PlanExerciseDetail detail) {
    return _repo.addExerciseToPlan(planId, detail);
  }
}
