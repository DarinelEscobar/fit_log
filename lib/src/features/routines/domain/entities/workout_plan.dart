class WorkoutPlan {
  final int id;
  final String name;
  final String frequency;
  final bool isActive;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.frequency,
    this.isActive = true,
  });

  WorkoutPlan copyWith({
    int? id,
    String? name,
    String? frequency,
    bool? isActive,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
    );
  }
}
