import '../repositories/workout_plan_repository.dart';
import '../entities/exercise.dart';

class GetSimilarExercisesUseCase {
  final WorkoutPlanRepository _repo;
  const GetSimilarExercisesUseCase(this._repo);

  Future<List<Exercise>> call(int exerciseId) =>
      _repo.getSimilarExercises(exerciseId);
}
