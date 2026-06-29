import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/workout_storage_service_provider.dart';
import '../../domain/models/active_exercise_progress.dart';
import '../../domain/services/active_exercise_progress_calculator.dart';

final activeExerciseProgressProvider = FutureProvider.family<
    ActiveExerciseProgressInsight, ActiveExerciseProgressRequest>(
  (ref, request) async {
    final storage = ref.watch(workoutStorageServiceProvider);
    final logs = await storage.fetchWorkoutLogs(
      exerciseId: request.exerciseId,
      endDate: request.sessionDate,
    );

    return ActiveExerciseProgressCalculator.buildInsight(
      logs: logs,
      currentSessionDate: request.sessionDate,
    );
  },
);
