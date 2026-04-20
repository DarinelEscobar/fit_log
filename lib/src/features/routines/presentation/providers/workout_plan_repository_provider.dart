import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/workout_storage_service_provider.dart';
import '../../domain/repositories/workout_plan_repository.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';

final workoutPlanRepositoryProvider = Provider<WorkoutPlanRepository>((ref) {
  return WorkoutPlanRepositoryImpl(
    storageService: ref.watch(workoutStorageServiceProvider),
  );
});
