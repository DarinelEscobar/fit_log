import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/get_workout_plans_usecase.dart';

final workoutPlanProvider = FutureProvider.autoDispose((ref) async {
  final repo = WorkoutPlanRepositoryImpl();
  final usecase = GetWorkoutPlansUseCase(repo);
  return usecase();
});
