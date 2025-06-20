part of 'start_routine_screen.dart';

mixin StartRoutineActions on ConsumerState<StartRoutineScreen> {
  Future<void> _swapExercise(int index) async {
    if (_sessionDetails == null) return;
    final detail = _sessionDetails![index];
    final alternatives = await ref.read(similarExercisesProvider(detail.exerciseId).future);
    if (alternatives.isEmpty) return;
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (_) => ListView(
        children: alternatives
            .map((e) => ListTile(
                  title: Text(e.name),
                  subtitle: Text('${e.category} • ${e.mainMuscleGroup}'),
                  onTap: () => Navigator.pop(context, e),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      final notifier = ref.read(workoutLogProvider.notifier);
      final existingEntries = notifier.state.values.where((entry) =>
          entry.planId == widget.planId &&
          entry.exerciseId == detail.exerciseId &&
          entry.setNumber <= detail.sets);
      for (var entry in existingEntries) {
        notifier.remove(entry);
      }
      setState(() {
        _keys.remove(detail.exerciseId);
        final newDetail = detail.copyWith(
          exerciseId: picked.id,
          name: picked.name,
          description: picked.description,
        );
        _sessionDetails![index] = newDetail;
        _keys[newDetail.exerciseId] = GlobalKey<ExerciseTileState>();
        if (_expandedExerciseId == detail.exerciseId) {
          _expandedExerciseId = newDetail.exerciseId;
        }
      });
    }
  }

  Future<void> _addExercise() async {
    if (_exerciseMap == null) return;
    final groups = <String>{};
    for (final d in _sessionDetails ?? []) {
      final g = _exerciseMap![d.exerciseId]?.mainMuscleGroup;
      if (g != null) groups.add(g);
    }
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(groups: groups),
      ),
    );
    if (exercise != null) {
      setState(() {
        final newDetail = PlanExerciseDetail(
          exerciseId: exercise.id,
          name: exercise.name,
          description: exercise.description,
          sets: _defaultSets,
          reps: 10,
          weight: 0,
          restSeconds: 90,
        );
        _sessionDetails ??= [];
        _sessionDetails!.add(newDetail);
        _keys[newDetail.exerciseId] = GlobalKey<ExerciseTileState>();
      });
    }
  }
}
