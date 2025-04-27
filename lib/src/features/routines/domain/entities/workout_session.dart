// lib/src/features/routines/domain/entities/workout_session.dart
class WorkoutSession {
  final int planId;
  final DateTime date;
  final String fatigueLevel;
  final int durationMinutes;
  final String mood;
  final String notes;

  WorkoutSession({
    required this.planId,
    required this.date,
    required this.fatigueLevel,
    required this.durationMinutes,
    required this.mood,
    required this.notes,
  });
}
