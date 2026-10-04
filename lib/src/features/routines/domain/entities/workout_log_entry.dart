class WorkoutLogEntry {
  final DateTime date;
  final int planId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;
  final int rir;
  final bool completed; // ← NEW
  final String? sessionId;

  String get storageSessionId => sessionId ?? workoutSessionId(date, planId);

  WorkoutLogEntry({
    required this.date,
    required this.planId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.rir,
    this.completed = true,
    this.sessionId,
  });

  WorkoutLogEntry copyWith({
    int? reps,
    double? weight,
    int? rir,
    bool? completed,
    String? sessionId,
  }) =>
      WorkoutLogEntry(
        date: date,
        planId: planId,
        exerciseId: exerciseId,
        setNumber: setNumber,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rir: rir ?? this.rir,
        completed: completed ?? this.completed,
        sessionId: sessionId ?? this.sessionId,
      );
}

/// Old day-only records have a deterministic key so repeated imports are safe.
String workoutSessionId(DateTime date, int planId) {
  final iso = date.toIso8601String();
  return date.hour == 0 &&
          date.minute == 0 &&
          date.second == 0 &&
          date.millisecond == 0 &&
          date.microsecond == 0
      ? 'legacy:${iso.split('T').first}:$planId'
      : 'workout:$planId:$iso';
}
