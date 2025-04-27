import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/get_exercises_for_plan_usecase.dart';

final exercisesForPlanProvider = FutureProvider.family((ref, int planId) async {
  final repo = WorkoutPlanRepositoryImpl();
  final usecase = GetExercisesForPlanUseCase(repo);
  return usecase(planId);
});
