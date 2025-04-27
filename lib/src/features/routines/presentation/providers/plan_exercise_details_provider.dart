// lib/src/features/routines/presentation/providers/plan_exercise_details_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/get_plan_exercise_details_usecase.dart';

final planExerciseDetailsProvider = FutureProvider.family((ref, int planId) async {
  final repo = WorkoutPlanRepositoryImpl();
  final usecase = GetPlanExerciseDetailsUseCase(repo);
  return usecase(planId);
});
