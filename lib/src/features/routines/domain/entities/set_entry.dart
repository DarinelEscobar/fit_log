class SetEntry {
  final int reps;
  final double weight;
  final int rir;
  final bool completed;

  SetEntry({
    required this.reps,
    required this.weight,
    required this.rir,
    this.completed = true,
  });

  double get volume => reps * weight;

  SetEntry copyWith({int? reps, double? weight, int? rir, bool? completed}) =>
      SetEntry(
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rir: rir ?? this.rir,
        completed: completed ?? this.completed,
      );
}
