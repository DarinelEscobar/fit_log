import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_plan_repository_provider.dart';
import '../../domain/usecases/get_exercises_for_plan_usecase.dart';
import '../../domain/usecases/get_all_exercises_usecase.dart';
import '../../domain/usecases/get_similar_exercises_usecase.dart';
import '../../domain/entities/exercise.dart';

final exercisesForPlanProvider = FutureProvider.family((ref, int planId) async {
  final usecase =
      GetExercisesForPlanUseCase(ref.watch(workoutPlanRepositoryProvider));
  return usecase(planId);
});

final allExercisesProvider = FutureProvider((ref) async {
  final usecase = GetAllExercisesUseCase(ref.watch(workoutPlanRepositoryProvider));
  return usecase();
});

final similarExercisesProvider =
    FutureProvider.family<List<Exercise>, int>((ref, int exerciseId) async {
  final usecase =
      GetSimilarExercisesUseCase(ref.watch(workoutPlanRepositoryProvider));
  return usecase(exerciseId);
});
