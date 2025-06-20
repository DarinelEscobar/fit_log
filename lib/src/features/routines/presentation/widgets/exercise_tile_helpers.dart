part of 'exercise_tile.dart';

mixin ExerciseTileHelpers on State<ExerciseTile> {
  late List<TextEditingController> _repCtl, _kgCtl, _rirCtl;
  int _visibleSets = 0;
  bool _logsLoaded = false;
  final Map<int, WorkoutLogEntry> _extraLast = {};
  Timer? _restTimer;
  int _restRemaining = 0;

  double _tonnage(Iterable<WorkoutLogEntry> logs) =>
      logs.fold(0, (s, e) => s + e.reps * e.weight);

  Iterable<WorkoutLogEntry> get _todayCompletedLogs => widget.logsMap.values
      .where((e) => e.exerciseId == widget.detail.exerciseId && e.completed);

  double get _todayTonnage => _tonnage(_todayCompletedLogs);

  int get _restTotal => widget.detail.restSeconds;

  void _build(int sets) {
    _visibleSets = sets;
    _repCtl = [];
    _kgCtl = [];
    _rirCtl = [];
    _extraLast.clear();
    WorkoutLogEntry? lastFor(int set) =>
        widget.lastLogs?.firstWhereOrNull((l) => l.setNumber == set);
    for (var i = 0; i < _visibleSets; i++) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'] ??
          lastFor(i + 1);
      _repCtl.add(TextEditingController(
          text: e?.reps.toString() ?? widget.detail.reps.toString()));
      _kgCtl.add(TextEditingController(
          text: e?.weight.toStringAsFixed(0) ??
              widget.detail.weight.toStringAsFixed(0)));
      _rirCtl.add(TextEditingController(text: e?.rir.toString() ?? '2'));
    }
    if (widget.lastLogs != null) {
      for (final l in widget.lastLogs!) {
        if (l.setNumber > _visibleSets) _extraLast[l.setNumber] = l;
      }
    }
    _logsLoaded = widget.lastLogs != null;
  }

  void _persist(int idx, {bool completed = false}) {
    widget.update(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: idx + 1,
        reps: int.tryParse(_repCtl[idx].text) ?? widget.detail.reps,
        weight: double.tryParse(_kgCtl[idx].text) ?? widget.detail.weight,
        rir: int.tryParse(_rirCtl[idx].text) ?? 2,
        completed: completed ||
            (widget.logsMap['${widget.detail.exerciseId}-${idx + 1}']?.completed ??
                false),
      ),
    );
  }

  void logCurrentSet({required void Function(WorkoutLogEntry) addOrUpdate}) {
    final current = List.generate(_visibleSets, (i) => i + 1).firstWhere(
      (s) => !(widget.logsMap['${widget.detail.exerciseId}-$s']?.completed ?? false),
      orElse: () => _visibleSets,
    );
    addOrUpdate(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: current,
        reps: int.tryParse(_repCtl[current - 1].text) ?? widget.detail.reps,
        weight: double.tryParse(_kgCtl[current - 1].text) ?? widget.detail.weight,
        rir: int.tryParse(_rirCtl[current - 1].text) ?? 2,
        completed: true,
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Serie $current registrada')));
    setState(widget.onChanged);
    _startRestTimer();
  }

  bool isComplete(Map<String, WorkoutLogEntry> logs) =>
      List.generate(_visibleSets, (i) => i + 1)
          .every((s) => logs['${widget.detail.exerciseId}-$s']?.completed ?? false);

  void _startRestTimer() {
    _restTimer?.cancel();
    NotificationService.cancelRest();
    NotificationService.scheduleRestDone(widget.detail.restSeconds);
    setState(() => _restRemaining = widget.detail.restSeconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining <= 1) {
        t.cancel();
        NotificationService.cancelRest();
        Vibration.vibrate(duration: 1500, amplitude: 255);
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _add() {
    final setNum = _visibleSets + 1;
    final last =
        widget.logsMap['${widget.detail.exerciseId}-$setNum'] ?? _extraLast[setNum];
    setState(() {
      _repCtl.add(TextEditingController(
          text: last?.reps.toString() ?? widget.detail.reps.toString()));
      _kgCtl.add(TextEditingController(
          text: last?.weight.toStringAsFixed(0) ??
              widget.detail.weight.toStringAsFixed(0)));
      _rirCtl.add(TextEditingController(text: last?.rir.toString() ?? '2'));
      _visibleSets++;
    });
    _persist(setNum - 1);
    widget.onChanged();
  }

  void _remove() {
    if (_visibleSets <= 1) return;
    final removed = _visibleSets;
    _repCtl.removeLast();
    _kgCtl.removeLast();
    _rirCtl.removeLast();
    _visibleSets--;
    widget.removeLog(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: -1,
        exerciseId: widget.detail.exerciseId,
        setNumber: removed,
        reps: 0,
        weight: 0,
        rir: 0,
      ),
    );
    setState(widget.onChanged);
  }

