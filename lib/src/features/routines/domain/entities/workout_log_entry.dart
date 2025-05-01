class WorkoutLogEntry {
  final DateTime date;
  final int planId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;
  final int rir;
  final bool completed;          // ← NEW

  WorkoutLogEntry({
    required this.date,
    required this.planId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.rir,
    this.completed = true,
  });

  WorkoutLogEntry copyWith({
    int? reps,
    double? weight,
    int? rir,
    bool? completed,
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
      );
}
