import '../repositories/workout_plan_repository.dart';

class AddPlanExerciseUseCase {
  final WorkoutPlanRepository _repo;
  const AddPlanExerciseUseCase(this._repo);

  Future<void> call({
    required int planId,
    required int exerciseId,
    required int sets,
    required int reps,
    required double weight,
    required int restSeconds,
  }) {
    return _repo.addPlanExercise(
      planId: planId,
      exerciseId: exerciseId,
      sets: sets,
      reps: reps,
      weight: weight,
      restSeconds: restSeconds,
    );
  }
}
