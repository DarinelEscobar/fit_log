import '../repositories/workout_plan_repository.dart';

class CreateExerciseUseCase {
  final WorkoutPlanRepository _repo;
  const CreateExerciseUseCase(this._repo);

  Future<void> call(
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) {
    return _repo.createExercise(name, description, category, mainMuscleGroup);
  }
}
