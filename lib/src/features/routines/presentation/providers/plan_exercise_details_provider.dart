// lib/src/features/routines/presentation/providers/plan_exercise_details_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_plan_exercise_details_usecase.dart';
import 'workout_plan_repository_provider.dart';

final planExerciseDetailsProvider = FutureProvider.family((ref, int planId) async {
  final usecase =
      GetPlanExerciseDetailsUseCase(ref.watch(workoutPlanRepositoryProvider));
  return usecase(planId);
});
