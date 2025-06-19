import '../entities/workout_plan.dart';
import '../entities/exercise.dart';
import '../entities/plan_exercise_detail.dart';
import '../entities/workout_log_entry.dart';
import '../entities/workout_session.dart';


abstract class WorkoutPlanRepository {
  Future<List<WorkoutPlan>> getAllPlans();
  Future<List<Exercise>> getExercisesForPlan(int planId);
  Future<List<Exercise>> getAllExercises();
  Future<List<Exercise>> getSimilarExercises(int exerciseId);
  Future<void> createWorkoutPlan(String name, String frequency);
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId);

  //Start session 
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs);
  Future<void> saveWorkoutSession(WorkoutSession session);
}
