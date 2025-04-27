// lib/src/features/routines/domain/usecases/get_plan_exercise_details_usecase.dart
import '../repositories/workout_plan_repository.dart';
import '../entities/plan_exercise_detail.dart';

class GetPlanExerciseDetailsUseCase {
  final WorkoutPlanRepository _repo;
  const GetPlanExerciseDetailsUseCase(this._repo);

  Future<List<PlanExerciseDetail>> call(int planId) =>
      _repo.getPlanExerciseDetails(planId);
}
