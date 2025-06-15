// lib/src/features/routines/presentation/pages/start_routine_screen.dart
//
// Neutral-toned, shadow-light redesign with fixed compile errors.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../state/workout_log_state.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/workout_session.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/save_workout_logs_usecase.dart';
import '../../domain/usecases/save_workout_session_usecase.dart';

class StartRoutineScreen extends ConsumerStatefulWidget {
  final int planId;
  const StartRoutineScreen({required this.planId, super.key});
  @override
  ConsumerState<StartRoutineScreen> createState() => _StartRoutineScreenState();
}

class _StartRoutineScreenState extends ConsumerState<StartRoutineScreen> {
  late final Timer _ticker;
  final Map<int, GlobalKey<_ExerciseTileState>> _keys = {};
  int? _expandedExerciseId;

  String _fatigue = '5';
  String _mood = '3';
  final TextEditingController _notesCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(workoutLogProvider.notifier);
    notifier.startSession();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDets = ref.watch(planExerciseDetailsProvider(widget.planId));
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
              icon: const Icon(Icons.flag),
              onPressed: () async {
                if (notifier.completedLogs.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('No has completado ninguna serie')));
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
        body: asyncDets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (dets) {
            final done = dets
                .where((d) => _keys[d.exerciseId]?.currentState?.isComplete(logsMap) ?? false)
                .length;
            return Column(
              children: [
                _ProgressHeader(completed: done, total: dets.length),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 100, 12, 80),
                    children: dets.map((d) {
                      _keys[d.exerciseId] ??= GlobalKey<_ExerciseTileState>();
                      final doneEx =
                          _keys[d.exerciseId]!.currentState?.isComplete(logsMap) ?? false;
                      return _ExerciseTile(
                        key: _keys[d.exerciseId],
                        detail: d,
                        expanded: _expandedExerciseId == d.exerciseId,
                        onToggle: () => setState(() =>
                            _expandedExerciseId =
                                _expandedExerciseId == d.exerciseId ? null : d.exerciseId),
                        logsMap: logsMap,
                        highlightDone: doneEx,
                        onChanged: () => setState(() {}),
                        removeLog: notifier.remove,
                        update: notifier.update,
                        planId: widget.planId,
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  Future<bool> _confirmExit(BuildContext ctx) async =>
      await showModalBottomSheet<bool>(
            context: ctx,
            backgroundColor: const Color(0xFF1F1F1F),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('¿Salir sin guardar?', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white38)),
                const SizedBox(height: 8),
                const Text('Perderás el progreso de esta sesión.', style: TextStyle(color: Colors.white38)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Salir'))),
                ]),
              ]),
            ),
          ) ??
          false;

  Future<bool> _showFinishDialog(BuildContext ctx) async {
    String lf = _fatigue, lm = _mood;
    final noteCtl = TextEditingController(text: _notesCtl.text);
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Finalizar sesión'),
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _Drop(icon: Icons.bolt, val: lf, list: _scale10, onC: (v) => setD(() => lf = v)),
            const SizedBox(height: 8),
            _Drop(icon: Icons.mood, val: lm, list: _scale5, onC: (v) => setD(() => lm = v)),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Notas',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            Text('${notifier.sessionDuration.inMinutes} min de sesión',
                style: const TextStyle(color: Colors.white70)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dCtx, false),
                child: const Text('Cancelar', style: TextStyle(color: Color.fromARGB(179, 219, 57, 57)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              onPressed: () {
                _fatigue = lf;
                _mood = lm;
                _notesCtl.text = noteCtl.text;
                Navigator.pop(dCtx, true);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }
}

const _scale10 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
const _scale5 = ['1', '2', '3', '4', '5'];

// ────────────────────────── HEADER ──────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.completed, required this.total});
  final int completed, total;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 6, offset: const Offset(0, 3))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ejercicios $completed / $total',
              style: const TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 6,
            backgroundColor: Colors.grey.shade700,
            color: Colors.blueGrey.shade200,
          ),
        ]),
      );
}

// ────────────────────────── DROPDOWN ──────────────────────────

class _Drop extends StatelessWidget {
  const _Drop({required this.icon, required this.val, required this.list, required this.onC});
  final IconData icon;
  final String val;
  final List<String> list;
  final ValueChanged<String> onC;
  @override
  Widget build(BuildContext ctx) => DropdownButtonFormField<String>(
        value: val,
        dropdownColor: const Color(0xFF2A2A2A),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          border: const OutlineInputBorder(),
        ),
        items: list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => onC(v ?? val),
      );
}

// ────────────────────────── TILE ──────────────────────────

class _ExerciseTile extends StatefulWidget {
  const _ExerciseTile({
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
  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  late List<TextEditingController> _repCtl, _kgCtl, _rirCtl;
  @override
  void initState() {
    super.initState();
    _build(widget.detail.sets);
  }

  void _build(int n) {
    _repCtl = List.generate(n, (i) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'];
      return TextEditingController(
          text: e?.reps.toString() ?? widget.detail.reps.toString());
    });
    _kgCtl = List.generate(n, (i) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'];
      return TextEditingController(
          text: e?.weight.toStringAsFixed(0) ??
              widget.detail.weight.toStringAsFixed(0));
    });
    _rirCtl = List.generate(n, (i) {
      final e = widget.logsMap['${widget.detail.exerciseId}-${i + 1}'];
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

  bool isComplete(Map<String, WorkoutLogEntry> logs) => List.generate(_repCtl.length, (i) => i + 1)
      .every((s) => logs['${widget.detail.exerciseId}-$s']?.completed ?? false);

  void logCurrentSet({required void Function(WorkoutLogEntry) addOrUpdate}) {
    int current = List.generate(_repCtl.length, (i) => i + 1)
        .firstWhere((s) => !(widget.logsMap['${widget.detail.exerciseId}-$s']?.completed ?? false),
            orElse: () => _repCtl.length);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Serie $current registrada')));
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
    widget.removeLog(WorkoutLogEntry(
      date: DateTime.now(),
      planId: -1,
      exerciseId: widget.detail.exerciseId,
      setNumber: removed,
      reps: 0,
      weight: 0,
      rir: 0,
    ));
    setState(widget.onChanged);
  }

  OutlinedButton _actionBtn(IconData ic, VoidCallback fn) => OutlinedButton(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: fn,
        child: Icon(ic, size: 16),
      );

    Widget _num(TextEditingController c, double w, String label, int idx) => SizedBox(
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
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
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


  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: widget.highlightDone ? Colors.blueGrey.shade800 : const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 6, offset: const Offset(0, 3))
            ],
          ),
          child: Column(children: [
            ListTile(
              title: Text(widget.detail.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70,)),
              trailing: Icon(widget.expanded ? Icons.expand_less : Icons.expand_more),
            ),
            if (widget.expanded) ...[
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _actionBtn(Icons.remove, _remove),
                  const SizedBox(width: 8),
                  _actionBtn(Icons.add, _add),
                ]),
              ),
              Column(
                children: List.generate(_repCtl.length, (i) {
                  final done =
                      widget.logsMap['${widget.detail.exerciseId}-${i + 1}']?.completed ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(children: [
                      _num(_repCtl[i], 50, 'r', i),
                      const SizedBox(width: 12),
                      _num(_kgCtl[i], 66, 'kg', i),
                      const SizedBox(width: 12),
                      _num(_rirCtl[i], 54, 'R', i),
                      const Spacer(),
                      Icon(done ? Icons.check_circle : Icons.circle,
                          size: 18, color: done ? Colors.green : Colors.grey),
                    ]),
                  );
                }),
              ),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      );
}
