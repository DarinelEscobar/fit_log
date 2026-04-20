import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../models/exercise_list_view_data.dart';
import 'exercises_provider.dart';
import 'plan_exercise_details_provider.dart';

final exerciseListViewProvider =
    FutureProvider.family<ExerciseListViewData, int>((ref, planId) async {
  final results = await Future.wait([
    ref.watch(planExerciseDetailsProvider(planId).future),
    ref.watch(allExercisesProvider.future),
  ]);

  final details = results[0] as List<PlanExerciseDetail>;
  final exercises = results[1] as List<Exercise>;
  final exerciseMap = {
    for (final exercise in exercises) exercise.id: exercise,
  };

  return ExerciseListViewData(
    items: [
      for (final detail in details)
        ExerciseListItemView(
          exerciseId: detail.exerciseId,
          name: detail.name,
          description: detail.description,
          category: exerciseMap[detail.exerciseId]?.category ?? '',
          mainMuscleGroup:
              exerciseMap[detail.exerciseId]?.mainMuscleGroup ?? '',
          sets: detail.sets,
          reps: detail.reps,
          restSeconds: detail.restSeconds,
          weight: detail.weight,
        ),
    ],
  );
});
