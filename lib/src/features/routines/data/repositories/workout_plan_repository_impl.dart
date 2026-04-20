import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/plan_exercise_detail.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_plan.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_session.dart';

import '../../../../data/services/workout_storage_service.dart';
import '../../domain/repositories/workout_plan_repository.dart';

class WorkoutPlanRepositoryImpl implements WorkoutPlanRepository {
  WorkoutPlanRepositoryImpl({WorkoutStorageService? storageService})
      : _storageService = storageService ?? WorkoutStorageService();

  final WorkoutStorageService _storageService;

  @override
  Future<List<WorkoutPlan>> getAllPlans() {
    return _storageService.fetchWorkoutPlans();
  }

  @override
  Future<void> createWorkoutPlan(String name, String frequency) {
    return _storageService.createWorkoutPlan(name, frequency);
  }

  @override
  Future<void> updateWorkoutPlan(int planId, String name, String frequency) {
    return _storageService.updateWorkoutPlan(planId, name, frequency);
  }

  @override
  Future<void> setWorkoutPlanActive(int planId, bool isActive) {
    return _storageService.setWorkoutPlanActive(planId, isActive);
  }

  @override
  Future<List<Exercise>> getExercisesForPlan(int planId) {
    return _storageService.fetchExercisesForPlan(planId);
  }

  @override
  Future<List<Exercise>> getAllExercises() {
    return _storageService.fetchAllExercises();
  }

  @override
  Future<void> createExercise(
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) {
    return _storageService.createExercise(
      name,
      description,
      category,
      mainMuscleGroup,
    );
  }

  @override
  Future<void> updateExercise(
    int id,
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) {
    return _storageService.updateExercise(
      id,
      name,
      description,
      category,
      mainMuscleGroup,
    );
  }

  @override
  Future<List<Exercise>> getSimilarExercises(int exerciseId) {
    return _storageService.fetchSimilarExercises(exerciseId);
  }

  @override
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId) {
    return _storageService.fetchPlanExerciseDetails(planId);
  }

  @override
  Future<void> addExerciseToPlan(
    int planId,
    PlanExerciseDetail detail, {
    int? position,
  }) {
    return _storageService.addExerciseToPlan(
      planId,
      detail,
      position: position,
    );
  }

  @override
  Future<void> updateExerciseInPlan(int planId, PlanExerciseDetail detail) {
    return _storageService.updateExerciseInPlan(planId, detail);
  }

  @override
  Future<void> deleteExerciseFromPlan(int planId, int exerciseId) {
    return _storageService.deleteExerciseFromPlan(planId, exerciseId);
  }

  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) {
    return _storageService.saveWorkoutLogs(logs);
  }

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) {
    return _storageService.saveWorkoutSession(session);
  }
}
