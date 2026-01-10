// lib/src/features/routines/domain/entities/plan_exercise_detail.dart
class PlanExerciseDetail {
  final int exerciseId;
  final String name;
  final String description;
  final int sets;
  final int reps;
  final double weight;
  final int restSeconds;
  final int targetRir;

  PlanExerciseDetail({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.targetRir,
  });

  PlanExerciseDetail copyWith({
    int? exerciseId,
    String? name,
    String? description,
    int? sets,
    int? reps,
    double? weight,
    int? restSeconds,
    int? targetRir,
  }) =>
      PlanExerciseDetail(
        exerciseId: exerciseId ?? this.exerciseId,
        name: name ?? this.name,
        description: description ?? this.description,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        restSeconds: restSeconds ?? this.restSeconds,
        targetRir: targetRir ?? this.targetRir,
      );
}
