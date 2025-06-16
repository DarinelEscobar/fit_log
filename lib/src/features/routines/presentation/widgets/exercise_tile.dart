import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/workout_log_state.dart';
import '../../domain/entities/workout_log_entry.dart';

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
  });

  final dynamic detail;
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

  @override
  ExerciseTileState createState() => ExerciseTileState();
}

class ExerciseTileState extends State<ExerciseTile>
    with AutomaticKeepAliveClientMixin {
  late List<TextEditingController> _repCtl, _kgCtl, _rirCtl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _build(widget.detail.sets);
  }

  @override
  void didUpdateWidget(covariant ExerciseTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.sets != widget.detail.sets ||
        oldWidget.lastLogs != widget.lastLogs) {
      _build(widget.detail.sets);
    }
  }

  void _build(int n) {
    final count = [n, widget.lastLogs?.length ?? 0].reduce((a, b) => a > b ? a : b);
    WorkoutLogEntry? _lastFor(int set) {
      if (widget.lastLogs == null) return null;
      for (final l in widget.lastLogs!) {
        if (l.setNumber == set) return l;
      }
      return null;
    }

    _repCtl = List.generate(count, (i) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'] ??
          _lastFor(i + 1);
      return TextEditingController(
          text: e?.reps.toString() ?? widget.detail.reps.toString());
    });
    _kgCtl = List.generate(count, (i) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'] ??
          _lastFor(i + 1);
      return TextEditingController(
          text: e?.weight.toStringAsFixed(0) ??
              widget.detail.weight.toStringAsFixed(0));
    });
    _rirCtl = List.generate(count, (i) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'] ??
          _lastFor(i + 1);
      return TextEditingController(text: e?.rir.toString() ?? '2');
    });
  }

  void _persist(int index) {
    widget.update(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: index + 1,
        reps: int.tryParse(_repCtl[index].text) ?? widget.detail.reps,
        weight: double.tryParse(_kgCtl[index].text) ?? widget.detail.weight,
        rir: int.tryParse(_rirCtl[index].text) ?? 2,
        completed:
            widget.logsMap['${widget.detail.exerciseId}-${index + 1}']?.completed ?? false,
      ),
    );
  }

  bool isComplete(Map<String, WorkoutLogEntry> logs) =>
      List.generate(_repCtl.length, (i) => i + 1)
          .every((s) => logs['${widget.detail.exerciseId}-$s']?.completed ?? false);

  void logCurrentSet({required void Function(WorkoutLogEntry) addOrUpdate}) {
    final current = List.generate(_repCtl.length, (i) => i + 1).firstWhere(
      (s) => !(widget.logsMap['${widget.detail.exerciseId}-$s']?.completed ?? false),
      orElse: () => _repCtl.length,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Serie $current registrada')),
    );
    setState(widget.onChanged);
  }

  void _add() {
    setState(() {
      _repCtl.add(TextEditingController(text: widget.detail.reps.toString()));
      _kgCtl.add(TextEditingController(text: widget.detail.weight.toStringAsFixed(0)));
      _rirCtl.add(TextEditingController(text: '2'));
    });
    _persist(_repCtl.length - 1);
    widget.onChanged();
  }

  void _remove() {
    if (_repCtl.length <= 1) return;
    final removed = _repCtl.length;
    _repCtl.removeLast();
    _kgCtl.removeLast();
    _rirCtl.removeLast();
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

  OutlinedButton _actionBtn(IconData ic, VoidCallback fn) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );

  Widget _info(String label, String value, {bool highlight = false}) =>
      Padding(
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
                    color: highlight ? Colors.amber : Colors.white70)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            BoxShadow(
              color: Colors.black.withOpacity(.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                widget.detail.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              subtitle: widget.detail.description.isNotEmpty
                  ? Text(
                      widget.detail.description,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    )
                  : null,
              trailing: Icon(widget.expanded ? Icons.expand_less : Icons.expand_more),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _info(
                        'Plan',
                        '${widget.detail.sets}x${widget.detail.reps} @${widget.detail.weight.toStringAsFixed(0)}kg'),
                  ),
                  Expanded(
                    child: widget.lastLogs == null || widget.lastLogs!.isEmpty
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
                      child: widget.bestLogs == null || widget.bestLogs!.isEmpty
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
                children: List.generate(_repCtl.length, (i) {
                  final done =
                      widget.logsMap['${widget.detail.exerciseId}-${i + 1}']?.completed ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
