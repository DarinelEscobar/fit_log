class ExerciseListViewData {
  const ExerciseListViewData({
    required this.items,
  });

  final List<ExerciseListItemView> items;
}

class ExerciseListItemView {
  const ExerciseListItemView({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.category,
    required this.mainMuscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.weight,
  });

  final int exerciseId;
  final String name;
  final String description;
  final String category;
  final String mainMuscleGroup;
  final int sets;
  final int reps;
  final int restSeconds;
  final double weight;
}
