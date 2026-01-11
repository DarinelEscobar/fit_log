part of 'start_routine_screen.dart';

extension StartRoutineActions on _StartRoutineScreenState {
  Future<void> swapExercise(int index) async {
    if (_sessionDetails == null || _exerciseMap == null) return;
    final detail = _sessionDetails![index];
    final groups = <String>{};
    for (final d in _sessionDetails!) {
      final g = _exerciseMap![d.exerciseId]?.mainMuscleGroup;
      if (g != null) groups.add(g);
    }
    final picked = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(groups: groups),
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

  Future<void> addExercise() async {
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
          sets: _StartRoutineScreenState._defaultSets,
          reps: 10,
          weight: 0,
          restSeconds: 90,
          rir: 2,
          tempo: '3-1-1-0',
        );
        _sessionDetails ??= [];
        _sessionDetails!.add(newDetail);
        _keys[newDetail.exerciseId] = GlobalKey<ExerciseTileState>();
      });
    }
  }
}
