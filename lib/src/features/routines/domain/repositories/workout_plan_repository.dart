import '../entities/workout_plan.dart';
import '../entities/exercise.dart';

abstract class WorkoutPlanRepository {
  Future<List<WorkoutPlan>> getAllPlans();
  Future<List<Exercise>> getExercisesForPlan(int planId);
  Future<void> createWorkoutPlan(String name, String frequency);

}
