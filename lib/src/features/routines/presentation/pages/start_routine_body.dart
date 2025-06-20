part of 'start_routine_screen.dart';

extension _StartRoutineScreenUI on _StartRoutineScreenState {
  Widget buildBody(BuildContext context) {
    final asyncDets = ref.watch(planExerciseDetailsProvider(widget.planId));
    final asyncAll = ref.watch(allExercisesProvider);
    final logsMap = ref.watch(workoutLogProvider);
    final notifier = ref.read(workoutLogProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        final exit = await _confirmExit(context);
        if (exit) notifier.clear();
        return exit;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B1B1B),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final exit = await _confirmExit(context);
              if (exit) {
                notifier.clear();
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _fmt(notifier.sessionDuration),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_showBest ? Icons.star : Icons.star_border),
              onPressed: () => setState(() => _showBest = !_showBest),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addExercise,
            ),
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: () async {
                if (notifier.completedLogs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No has completado ninguna serie')),
                  );
                  return;
                }
                if (!await _showFinishDialog(context)) return;
                final repo = WorkoutPlanRepositoryImpl();
                await SaveWorkoutLogsUseCase(repo)(notifier.completedLogs);
                await SaveWorkoutSessionUseCase(repo)(
                  WorkoutSession(
                    planId: widget.planId,
                    date: DateTime.now(),
                    fatigueLevel: _fatigue,
                    durationMinutes: notifier.sessionDuration.inMinutes,
                    mood: _mood,
                    notes: _notesCtl.text,
                  ),
                );
                notifier.clear();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          icon: const Icon(Icons.check),
          label: const Text('Registrar serie'),
          onPressed: () {
            if (_expandedExerciseId == null) return;
            _keys[_expandedExerciseId]!
                .currentState!
                .logCurrentSet(addOrUpdate: notifier.addOrUpdate);
            setState(() {});
          },
        ),
        body: asyncAll.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (allEx) {
            _exerciseMap ??= {for (var e in allEx) e.id: e};
            return asyncDets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (dets) {
                _sessionDetails ??= List.of(dets);
                final list = _sessionDetails!;
                final done = list.where((d) =>
                    _keys[d.exerciseId]?.currentState?.isComplete(logsMap) ?? false).length;
                return Column(
                  children: [
                    ProgressHeader(completed: done, total: list.length),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 100, 12, 80),
                        children: [
                          for (var entry in list.asMap().entries)
                            Consumer(builder: (context, ref, _) {
                              final detail = entry.value;
                              final idx = entry.key;
                              _keys[detail.exerciseId] ??= GlobalKey<ExerciseTileState>();
                              final doneEx =
                                  _keys[detail.exerciseId]?.currentState?.isComplete(logsMap) ?? false;
                              final asyncLogs = ref.watch(logsByExerciseProvider(detail.exerciseId));
                              return asyncLogs.when(
                                data: (logs) {
                                  final last = _lastLogs(logs);
                                  final best = _bestLogs(logs);
                                  return ExerciseTile(
                                    key: _keys[detail.exerciseId],
                                    detail: detail,
                                    expanded: _expandedExerciseId == detail.exerciseId,
                                    onToggle: () => setState(() {
                                      _expandedExerciseId =
                                          _expandedExerciseId == detail.exerciseId ? null : detail.exerciseId;
                                    }),
                                    logsMap: logsMap,
                                    highlightDone: doneEx,
                                    onChanged: () => setState(() {}),
                                    removeLog: notifier.remove,
                                    update: notifier.update,
                                    planId: widget.planId,
                                    lastLogs: last,
                                    bestLogs: best,
                                    showBest: _showBest,
                                    onSwap: () => _swapExercise(idx),
                                  );
                                },
                                loading: () => ExerciseTile(
                                  key: _keys[detail.exerciseId],
                                  detail: detail,
                                  expanded: _expandedExerciseId == detail.exerciseId,
                                  onToggle: () => setState(() {
                                    _expandedExerciseId =
                                        _expandedExerciseId == detail.exerciseId ? null : detail.exerciseId;
                                  }),
                                  logsMap: logsMap,
                                  highlightDone: doneEx,
                                  onChanged: () => setState(() {}),
                                  removeLog: notifier.remove,
                                  update: notifier.update,
                                  planId: widget.planId,
                                  showBest: _showBest,
                                  onSwap: () => _swapExercise(idx),
                                ),
                                error: (e, _) => ExerciseTile(
                                  key: _keys[detail.exerciseId],
                                  detail: detail,
                                  expanded: _expandedExerciseId == detail.exerciseId,
                                  onToggle: () => setState(() {
                                    _expandedExerciseId =
                                        _expandedExerciseId == detail.exerciseId ? null : detail.exerciseId;
                                  }),
                                  logsMap: logsMap,
                                  highlightDone: doneEx,
                                  onChanged: () => setState(() {}),
                                  removeLog: notifier.remove,
                                  update: notifier.update,
                                  planId: widget.planId,
                                  showBest: _showBest,
                                  onSwap: () => _swapExercise(idx),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
