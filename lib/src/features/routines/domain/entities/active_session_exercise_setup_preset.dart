import 'plan_exercise_detail.dart';

class ActiveSessionExerciseSetupPreset {
  const ActiveSessionExerciseSetupPreset({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.rir,
    required this.tempo,
  });

  final int exerciseId;
  final int sets;
  final int reps;
  final double weight;
  final int restSeconds;
  final int rir;
  final String tempo;

  factory ActiveSessionExerciseSetupPreset.fromDetail(
    PlanExerciseDetail detail,
  ) {
    return ActiveSessionExerciseSetupPreset(
      exerciseId: detail.exerciseId,
      sets: detail.sets,
      reps: detail.reps,
      weight: detail.weight,
      restSeconds: detail.restSeconds,
      rir: detail.rir,
      tempo: detail.tempo,
    );
  }

  PlanExerciseDetail applyTo(PlanExerciseDetail detail) {
    return detail.copyWith(
      sets: sets,
      reps: reps,
      weight: weight,
      restSeconds: restSeconds,
      rir: rir,
      tempo: tempo,
    );
  }
}
