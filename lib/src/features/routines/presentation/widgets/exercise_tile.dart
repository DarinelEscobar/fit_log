import 'package:flutter/material.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_log_entry.dart';

import '../../../../utils/notification_service.dart';
import 'dart:async';

class ExerciseTile extends StatefulWidget {
  final PlanExerciseDetail detail;
  final bool expanded;
  final VoidCallback onToggle;
  final Map<String, WorkoutLogEntry> logsMap;
  final bool highlightDone;
  final VoidCallback onChanged;
  final void Function(WorkoutLogEntry) removeLog;
  final void Function(WorkoutLogEntry) update;
  final int planId;
  final List<WorkoutLogEntry>? lastLogs;
  final List<WorkoutLogEntry>? bestLogs;
  final bool showBest;
  final VoidCallback? onSwap;

  const ExerciseTile({
    super.key,
    required this.detail,
    required this.expanded,
    required this.onToggle,
    required this.logsMap,
    required this.highlightDone,
    required this.onChanged,
    required this.removeLog,
    required this.update,
    required this.planId,
    this.lastLogs,
    this.bestLogs,
    required this.showBest,
    this.onSwap,
  });

  @override
  State<ExerciseTile> createState() => ExerciseTileState();
}

class ExerciseTileState extends State<ExerciseTile> {
  int _visibleSets = 0;
  final List<TextEditingController> _repCtl = [];
  final List<TextEditingController> _kgCtl = [];
  final List<TextEditingController> _rirCtl = [];

  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 0;


  @override
  void initState() {
    super.initState();
    _visibleSets = widget.detail.sets;
    _initCtl();
  }

  @override
  void didUpdateWidget(covariant ExerciseTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.detail.exerciseId != oldWidget.detail.exerciseId ||
        widget.planId != oldWidget.planId) {
      _initCtl();
    }
  }

  void _initCtl() {
    for (final c in [..._repCtl, ..._kgCtl, ..._rirCtl]) {
      c.dispose();
    }
    _repCtl.clear();
    _kgCtl.clear();
    _rirCtl.clear();

    final prevCount = widget.lastLogs?.length ?? 0;
    for (int i = 0; i < _visibleSets; i++) {
      final key = '${widget.detail.exerciseId}-${i + 1}';
      final log = widget.logsMap[key];

      int? initReps = log?.reps;
      double? initKg = log?.weight;
      int? initRir = log?.rir;

      if (log == null && i < prevCount) {
        initReps = widget.lastLogs![i].reps;
        initKg = widget.lastLogs![i].weight;
        initRir = widget.lastLogs![i].rir;
      }

      initReps ??= widget.detail.reps;
      initKg ??= widget.detail.weight;
      initRir ??= widget.detail.rir;

      _repCtl.add(TextEditingController(text: '$initReps'));
      _kgCtl.add(TextEditingController(
          text: initKg == initKg.truncateToDouble()
              ? initKg.toInt().toString()
              : initKg.toString()));
      _rirCtl.add(TextEditingController(text: '$initRir'));
    }
  }

  bool isComplete(Map<String, WorkoutLogEntry> map) {
    for (int i = 0; i < _visibleSets; i++) {
      if (!(map['${widget.detail.exerciseId}-${i + 1}']?.completed ?? false)) {
        return false;
      }
    }
    return true;
  }

  List<WorkoutLogEntry> get _todayCompletedLogs {
    final res = <WorkoutLogEntry>[];
    for (int i = 0; i < _visibleSets; i++) {
      final log = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'];
      if (log != null && log.completed) res.add(log);
    }
    return res;
  }

  double _tonnage(List<WorkoutLogEntry> logs) =>
      logs.fold(0, (sum, item) => sum + (item.reps * item.weight));

  double get _todayTonnage => _tonnage(_todayCompletedLogs);

  void _add() {
    setState(() {
      _visibleSets++;
      _repCtl.add(TextEditingController(text: '${widget.detail.reps}'));
      _kgCtl.add(TextEditingController(
          text: widget.detail.weight == widget.detail.weight.truncateToDouble()
              ? widget.detail.weight.toInt().toString()
              : widget.detail.weight.toString()));
      _rirCtl.add(TextEditingController(text: '${widget.detail.rir}'));
    });
  }

  void _remove() {
    if (_visibleSets > 1) {
      setState(() {
        _visibleSets--;
        final key = '${widget.detail.exerciseId}-${_visibleSets + 1}';
        if (widget.logsMap.containsKey(key)) {
          widget.removeLog(widget.logsMap[key]!);
        }
        _repCtl.removeLast().dispose();
        _kgCtl.removeLast().dispose();
        _rirCtl.removeLast().dispose();
        widget.onChanged();
      });
    }
  }

  void _startRest() {
    if (widget.detail.restSeconds <= 0) return;
    _restTimer?.cancel();
    NotificationService.cancelRest();
    setState(() {
      _restTotal = widget.detail.restSeconds;
      _restRemaining = _restTotal;
    });

    NotificationService.scheduleRestDone(_restTotal);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_restRemaining > 0) {
          _restRemaining--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void logCurrentSet({required void Function(WorkoutLogEntry) addOrUpdate}) {
    int target = -1;
    for (int i = 0; i < _visibleSets; i++) {
      if (!(widget.logsMap['${widget.detail.exerciseId}-${i + 1}']?.completed ??
          false)) {
        target = i;
        break;
      }
    }
    if (target != -1) {
      _logSet(target, addOrUpdate);
    }
  }

  void _logSet(int i, void Function(WorkoutLogEntry) addOrUpdate) {
    final reps = int.tryParse(_repCtl[i].text) ?? 0;
    final kg = double.tryParse(_kgCtl[i].text) ?? 0;
    final rir = int.tryParse(_rirCtl[i].text) ?? 0;

    final key = '${widget.detail.exerciseId}-${i + 1}';
    final current = widget.logsMap[key];
    final newState = !(current?.completed ?? false);

    addOrUpdate(WorkoutLogEntry(
      date: DateTime.now(),
      planId: widget.planId,
      exerciseId: widget.detail.exerciseId,
      setNumber: i + 1,
      reps: reps,
      weight: kg,
      rir: rir,
      completed: newState,
    ));

    if (newState) {
      _startRest();
    } else {
      _restTimer?.cancel();
      NotificationService.cancelRest();
      setState(() => _restRemaining = 0);
    }
    widget.onChanged();
  }

  Widget _num(TextEditingController c, double? w, String hint, int i, bool enabled, {bool isLbs = false, bool isDone = false}) {
    return Container(
      width: w,
      height: 40,
      decoration: BoxDecoration(
        color: isDone ? Colors.transparent : const Color(0xFF2C2C2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: c,
        enabled: enabled,
        keyboardType: isLbs ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDone ? const Color(0xFFADAAAB) : const Color(0xFFCC97FF),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: isDone ? InputBorder.none : OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFCC97FF), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [..._repCtl, ..._kgCtl, ..._rirCtl]) {
      c.dispose();
    }
    _restTimer?.cancel();
    NotificationService.cancelRest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    const cardColor = Color(0xFF1A191B);
    const titleColor = Colors.white;

    int? delta;
    final lastTon = _tonnage(widget.lastLogs ?? []);
    final todayTon = _todayTonnage;
    if (_todayCompletedLogs.isNotEmpty && lastTon > 0) {
      final raw = ((todayTon - lastTon) / lastTon * 100);
      delta = raw.abs() < 1 ? 0 : raw.round();
    }

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: widget.highlightDone
              ? Border.all(color: const Color(0xFFCC97FF).withValues(alpha: 0.2))
              : Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.highlightDone)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCC97FF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IN PROGRESS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFCC97FF),
                                  ),
                                ),
                              ),
                            if (widget.highlightDone) const SizedBox(width: 8),
                            const Text(
                              'COMPOUND',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFADAAAB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.detail.name,
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onSwap != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.swap_horiz, color: Color(0xFFADAAAB)),
                      onPressed: widget.onSwap,
                    ),
                ],
              ),
            ),

            if (widget.expanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    Expanded(flex: 1, child: Text('SET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFADAAAB)))),
                    Expanded(flex: 2, child: Text('PREV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFADAAAB)))),
                    Expanded(flex: 2, child: Center(child: Text('LBS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFADAAAB))))),
                    Expanded(flex: 2, child: Center(child: Text('REPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFADAAAB))))),
                    Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('RIR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFADAAAB))))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(_visibleSets, (i) {
                  final done = widget.logsMap['${widget.detail.exerciseId}-${i + 1}']?.completed ?? false;

                  final lastLog = widget.lastLogs != null && widget.lastLogs!.length > i
                      ? '${widget.lastLogs![i].weight}x${widget.lastLogs![i].reps}'
                      : '-';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFF000000).withValues(alpha: 0.4)
                          : const Color(0xFFCC97FF).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: !done
                          ? Border.all(color: const Color(0xFFCC97FF).withValues(alpha: 0.2))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text('${i + 1}', style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 16, fontWeight: FontWeight.bold, color: done ? const Color(0xFFADAAAB) : const Color(0xFFCC97FF)))),
                        Expanded(flex: 2, child: Text(lastLog, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF767576)))),
                        Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _num(_kgCtl[i], null, '', i, !done, isLbs: true, isDone: done))),
                        Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _num(_repCtl[i], null, '', i, !done, isDone: done))),
                        Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: _num(_rirCtl[i], null, '', i, !done, isDone: done))),
                      ],
                    ),
                  );
                }),
              ),

              if (delta != null && widget.bestLogs != null && widget.bestLogs!.isNotEmpty && widget.showBest)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A2785).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6A2785).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, size: 14, color: Color(0xFFE197FC)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Best: ${widget.bestLogs![0].weight} lbs x ${widget.bestLogs![0].reps} Reps',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFE197FC), letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          logCurrentSet(addOrUpdate: widget.update);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFCC97FF), Color(0xFF842CD3)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Color.fromRGBO(204, 151, 255, 0.2), blurRadius: 12),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'REGISTER SET',
                            style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF47007C)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _add,
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFFADAAAB)),
                      ),
                    ),
                    if (_visibleSets > 1) ...[
                       const SizedBox(width: 12),
                       GestureDetector(
                        onTap: _remove,
                        child: Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
                          ),
                          child: const Icon(Icons.remove, color: Color(0xFFADAAAB)),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],

            if (!widget.expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  '${widget.detail.sets} Sets • ${widget.detail.reps} Reps',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFFADAAAB),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
