// lib/src/features/routines/domain/entities/plan_exercise_detail.dart
class PlanExerciseDetail {
  final int exerciseId;
  final String name;
  final String description;
  final int sets;
  final int reps;
  final double weight;

  PlanExerciseDetail({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}
