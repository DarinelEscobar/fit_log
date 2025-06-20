import 'dart:async';
import 'mini_line_chart.dart';

  bool _showChart = false;
  List<WorkoutLogEntry> get _todayCompletedLogs {
    final logs = widget.logsMap.values
        .where((e) =>
            e.exerciseId == widget.detail.exerciseId && e.completed)
        .toList();
    logs.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return logs;
  }

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../../../utils/notification_service.dart';
import '../state/workout_log_state.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/plan_exercise_detail.dart';

class ExerciseTile extends StatefulWidget {
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

  @override
  ExerciseTileState createState() => ExerciseTileState();
}

class ExerciseTileState extends State<ExerciseTile>
    with AutomaticKeepAliveClientMixin {
  // ────────────────── controllers ──────────────────
  late List<TextEditingController> _repCtl, _kgCtl, _rirCtl;
  int _visibleSets = 0;
  bool _logsLoaded = false;
  final Map<int, WorkoutLogEntry> _extraLast = {};
  // ────────────────── descanso ──────────────────
  Timer? _restTimer;
  int _restRemaining = 0;

  @override
  bool get wantKeepAlive => true;

  // ────────────────── helpers ──────────────────
  double _tonnage(Iterable<WorkoutLogEntry> logs) =>
      logs.fold(0, (s, e) => s + e.reps * e.weight);

  Iterable<WorkoutLogEntry> get _todayCompletedLogs =>
      widget.logsMap.values.where(
        (e) =>
            e.exerciseId == widget.detail.exerciseId && //
            e.completed,
      );

  double get _todayTonnage => _tonnage(_todayCompletedLogs);

  // ────────────────── lifecycle ──────────────────
  @override
  void initState() {
    super.initState();
    _logsLoaded = widget.lastLogs != null;
    _build(widget.detail.sets);
  }

  @override
  void didUpdateWidget(covariant ExerciseTile old) {
    super.didUpdateWidget(old);
    final setsChanged = old.detail.sets != widget.detail.sets;
    final lastArrived = !_logsLoaded && widget.lastLogs != null;
    if (setsChanged || lastArrived) _build(widget.detail.sets);
  }

  // ────────────────── construcción de controles ──────────────────
  void _build(int sets) {
    _visibleSets = sets;
    _repCtl = [];
    _kgCtl = [];
    _rirCtl = [];
    _extraLast.clear();

    WorkoutLogEntry? _lastFor(int set) =>
        widget.lastLogs?.firstWhereOrNull((l) => l.setNumber == set);

    for (var i = 0; i < _visibleSets; i++) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'] ??
          _lastFor(i + 1);
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

  // ────────────────── persistencia ──────────────────
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
  // Duración total del descanso (para progreso circular)
  int get _restTotal => widget.detail.restSeconds;

            (widget.logsMap['${widget.detail.exerciseId}-${idx + 1}']
                    ?.completed ??
                false),
      ),
    );
  }

  // ────────────────── métodos públicos usados afuera ──────────────────
  /// Se llama desde el archivo start_routine_screen.dart
  void logCurrentSet({required void Function(WorkoutLogEntry) addOrUpdate}) {
    final current = List.generate(_visibleSets, (i) => i + 1).firstWhere(
      (s) =>
          !(widget.logsMap['${widget.detail.exerciseId}-$s']?.completed ??
              false),
      orElse: () => _visibleSets,
    );
    addOrUpdate(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: current,
        reps: int.tryParse(_repCtl[current - 1].text) ?? widget.detail.reps,
        weight:
            double.tryParse(_kgCtl[current - 1].text) ?? widget.detail.weight,
        rir: int.tryParse(_rirCtl[current - 1].text) ?? 2,
        completed: true,
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Serie $current registrada')));
    setState(widget.onChanged);
    _startRestTimer();
  }

  /// Devuelve true cuando **todas** las series del ejercicio están completadas.
  bool isComplete(Map<String, WorkoutLogEntry> logs) =>
      List.generate(_visibleSets, (i) => i + 1).every(
          (s) => logs['${widget.detail.exerciseId}-$s']?.completed ?? false);

  // ────────────────── control descanso ──────────────────
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

  // ────────────────── botones + / - ──────────────────
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

  // ────────────────── UI helpers ──────────────────
  OutlinedButton _actionBtn(IconData ic, VoidCallback fn) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: fn,
        child: Icon(ic, size: 16),
      );

  Widget _num(TextEditingController c, double w, String label, int idx) =>
      SizedBox(
        width: w + 24,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: c,
                onChanged: (_) {
                  _persist(idx);
                  widget.onChanged();
                },
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );

  Widget _info(String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white54)),
                if (highlight)
                  const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(Icons.star, size: 12, color: Colors.amber),
                  ),
              ],
            ),
            Text(value,
                style: TextStyle(
                  fontSize: 12,
                  color: highlight ? Colors.amber : Colors.white70,
                )),
          ],
        ),
      );

  Widget _deltaBadge(int delta, Color color, IconData icon, String tooltip) =>
      Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Text('${delta > 0 ? '+' : ''}$delta%',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  // ────────────────── dispose ──────────────────
  @override
  void dispose() {
    for (final c in [..._repCtl, ..._kgCtl, ..._rirCtl]) {
      c.dispose();
    }
    _restTimer?.cancel();
    NotificationService.cancelRest();
    super.dispose();
  }

  // ────────────────── build ──────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final lastTon = _tonnage(widget.lastLogs ?? []);
    final todayTon = _todayTonnage;

    int? delta;
    if (_todayCompletedLogs.isNotEmpty && lastTon > 0) {
      final raw = ((todayTon - lastTon) / lastTon * 100);
      delta = raw.abs() < 1 ? 0 : raw.round(); // ±1 % ≈ 0
    }

    Color deltaColor = Colors.grey.shade400;
    IconData deltaIcon = Icons.remove;
    if (delta != null) {
      if (delta > 0) {
        deltaColor = const Color(0xFF40CF45);
        deltaIcon = Icons.arrow_upward;
      } else if (delta < 0) {
        deltaColor = const Color(0xFFFF2600);
        deltaIcon = Icons.arrow_downward;
      }
    }

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: widget.highlightDone
              ? Colors.blueGrey.shade800
              : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
                  IconButton(
                    icon: Icon(
                      _showChart ? Icons.grid_view : Icons.show_chart,
                      size: 20,
                    ),
                    tooltip:
                        _showChart ? 'Ocultar gráfica' : 'Mostrar gráfica',
                    onPressed: () => setState(() => _showChart = !_showChart),
                  ),
            if (!_showChart)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1 - _restRemaining / _restTotal,
                        strokeWidth: 4,
                        color: Colors.amber,
                        backgroundColor: Colors.white12,
                      ),
                      Center(
                        child: Text(
                          '$_restRemaining',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
              if (_showChart)
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: MiniLineChart(
                      today: _todayCompletedLogs
                          .map((e) => e.reps * e.weight)
                          .toList(),
                      last: widget.lastLogs
                              ?.map((e) => e.reps * e.weight)
                              .toList() ??
                          [],
                      best: widget.bestLogs
                              ?.map((e) => e.reps * e.weight)
                              .toList() ??
                          [],
                    ),
                  ),
                ),
          children: [
            // ─── cabecera ───
            ListTile(
              title: Text(widget.detail.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      fontSize: 16)),
              subtitle: widget.detail.description.isNotEmpty
                  ? Text(widget.detail.description,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (delta != null)
                    _deltaBadge(delta, deltaColor, deltaIcon, 'vs última sesión'),
                  if (widget.onSwap != null)
                    IconButton(
                        icon: const Icon(Icons.swap_horiz), onPressed: widget.onSwap),
                  Icon(widget.expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            // ─── tonnage ───
            if (delta != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tonnage: ${todayTon.toStringAsFixed(0)} kg '
                    '(${delta > 0 ? '+' : ''}$delta%)',
                    style: TextStyle(fontSize: 11, color: deltaColor),
                  ),
                ),
              ),
            // ─── info plan / last / best ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _info(
                      'Plan',
                      '${widget.detail.sets}x${widget.detail.reps} '
                      '@${widget.detail.weight.toStringAsFixed(0)}kg • '
                      '${widget.detail.restSeconds}s',
                    ),
                  ),
                  Expanded(
                    child: (widget.lastLogs == null || widget.lastLogs!.isEmpty)
                        ? _info('Último', '-')
                        : _info(
                            'Último',
                            widget.lastLogs!
                                .map((l) =>
                                    '${l.setNumber}: ${l.reps}r ${l.weight.toStringAsFixed(0)}kg R${l.rir}')
                                .join('\n'),
                          ),
                  ),
                  if (widget.showBest)
                    Expanded(
                      child: (widget.bestLogs == null || widget.bestLogs!.isEmpty)
                          ? _info('Mejor', '-')
                          : _info(
                              'Mejor',
                              widget.bestLogs!
                                  .map((l) =>
                                      '${l.setNumber}: ${l.reps}r ${l.weight.toStringAsFixed(0)}kg R${l.rir}')
                                  .join('\n'),
                              highlight: true,
                            ),
                    ),
                ],
              ),
            ),
            // ─── descanso ───
            if (_restRemaining > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Descanso: $_restRemaining s',
                    style: const TextStyle(color: Colors.amber, fontSize: 12)),
              ),
            // ─── zona expandida ───
            if (widget.expanded) ...[
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionBtn(Icons.remove, _remove),
                    const SizedBox(width: 8),
                    _actionBtn(Icons.add, _add),
                  ],
                ),
              ),
              Column(
                children: List.generate(_visibleSets, (i) {
                  final done = widget.logsMap[
                              '${widget.detail.exerciseId}-${i + 1}']
                          ?.completed ??
                      false;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        _num(_repCtl[i], 50, 'r', i),
                        const SizedBox(width: 12),
                        _num(_kgCtl[i], 66, 'kg', i),
                        const SizedBox(width: 12),
                        _num(_rirCtl[i], 54, 'R', i),
                        const Spacer(),
                        Icon(
                          done ? Icons.check_circle : Icons.circle,
                          size: 18,
                          color: done ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
