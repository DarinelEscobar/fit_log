import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_plan_repository_sqlite.dart';
import '../../domain/usecases/get_exercises_for_plan_usecase.dart';
import '../../domain/usecases/get_all_exercises_usecase.dart';
import '../../domain/usecases/get_similar_exercises_usecase.dart';
import '../../domain/entities/exercise.dart';

final exercisesForPlanProvider = FutureProvider.family((ref, int planId) async {
  final repo = WorkoutPlanRepositorySqlite();
  final usecase = GetExercisesForPlanUseCase(repo);
  return usecase(planId);
});

final allExercisesProvider = FutureProvider((ref) async {
  final repo = WorkoutPlanRepositorySqlite();
  final usecase = GetAllExercisesUseCase(repo);
  return usecase();
});

final similarExercisesProvider =
    FutureProvider.family<List<Exercise>, int>((ref, int exerciseId) async {
  final repo = WorkoutPlanRepositorySqlite();
  final usecase = GetSimilarExercisesUseCase(repo);
  return usecase(exerciseId);
});
