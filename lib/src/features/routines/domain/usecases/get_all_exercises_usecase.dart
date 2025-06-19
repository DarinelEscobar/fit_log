import '../repositories/workout_plan_repository.dart';
import '../entities/exercise.dart';

class GetAllExercisesUseCase {
  final WorkoutPlanRepository _repo;
  const GetAllExercisesUseCase(this._repo);

  Future<List<Exercise>> call() => _repo.getAllExercises();
}
