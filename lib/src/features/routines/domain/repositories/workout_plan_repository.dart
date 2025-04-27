import '../entities/workout_plan.dart';

abstract class WorkoutPlanRepository {
  Future<List<WorkoutPlan>> getAllPlans();
}
