class WorkoutPlan {
  final int id;
  final String name;
  final String frequency;
  final bool isActive;

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.frequency,
    this.isActive = true,
  });
}
