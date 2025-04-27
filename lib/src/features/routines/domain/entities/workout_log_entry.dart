// lib/src/features/routines/domain/entities/workout_log_entry.dart
class WorkoutLogEntry {
  final DateTime date;       
  final int planId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;
  final int rir;

  WorkoutLogEntry({
    required this.date,
    required this.planId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.rir,
  });
}
