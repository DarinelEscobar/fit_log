import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/warm_up_step.dart';
import 'workout_plan_repository_provider.dart';

final warmUpStepsProvider =
    FutureProvider.family<List<WarmUpStep>, int>((ref, planId) {
  return ref.watch(workoutPlanRepositoryProvider).getWarmUpSteps(planId);
});
