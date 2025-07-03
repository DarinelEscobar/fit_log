import '../repositories/workout_plan_repository.dart';

class UpdateExerciseUseCase {
  final WorkoutPlanRepository _repo;
  const UpdateExerciseUseCase(this._repo);

  Future<void> call(
    int id,
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) {
    return _repo.updateExercise(id, name, description, category, mainMuscleGroup);
  }
}

