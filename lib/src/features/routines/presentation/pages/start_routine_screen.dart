// lib/src/features/routines/presentation/pages/start_routine_screen.dart
//
// Minimal UI: filas limpias; botones + / – estilizados; sin etiqueta "Serie X".

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
  ConsumerState<StartRoutineScreen> createState() =>
      _StartRoutineScreenState();
}

class _StartRoutineScreenState extends ConsumerState<StartRoutineScreen> {
  late final Stopwatch _sw;
  late final Timer _ticker;

  final Map<int, GlobalKey<_ExerciseTileState>> _keys = {};
  int? _expandedExerciseId;

  String _fatigue = 'Normal';
  String _mood = '🙂';
  final TextEditingController _notesCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _sw.stop();
    _ticker.cancel();
    super.dispose();
  }

  // ═════════════════════════════════ UI ROOT ═══════════════════════════════
  @override
  Widget build(BuildContext context) {
    final asyncDetails =
        ref.watch(planExerciseDetailsProvider(widget.planId));

    final logsMap = ref.watch(workoutLogProvider);
    final notifier = ref.read(workoutLogProvider.notifier);

    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () => _confirmExit(context, notifier),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit(context, notifier)) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: Text(_formatTime(_sw.elapsed)),
          actions: [
            IconButton(
              icon: const Icon(Icons.flag_rounded),
              tooltip: 'Finalizar sesión',
              onPressed: () async {
                if (notifier.completedLogs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No has completado ninguna serie')),
                  );
                  return;
                }
                if (!await _showFinishDialog(context)) return;

                final repo = WorkoutPlanRepositoryImpl();
                try {
                  await SaveWorkoutLogsUseCase(repo)(notifier.completedLogs);
                  await SaveWorkoutSessionUseCase(repo)(
                    WorkoutSession(
                      planId: widget.planId,
                      date: DateTime.now(),
                      fatigueLevel: _fatigue,
                      durationMinutes: _sw.elapsed.inMinutes,
                      mood: _mood,
                      notes: _notesCtl.text,
                    ),
                  );
                  notifier.clear();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.check),
          label: const Text('Registrar serie'),
          onPressed: () {
            if (_expandedExerciseId == null) return;
            _keys[_expandedExerciseId]!.currentState!.logCurrentSet(
              addOrUpdate: notifier.addOrUpdate,
              planId: widget.planId,
            );
            setState(() {});
          },
        ),
        body: asyncDetails.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (details) {
            final completedExercises = details.where((d) {
              final st = _keys[d.exerciseId]?.currentState;
              return st?.isComplete(logsMap) ?? false;
            }).length;

            return Column(
              children: [
                _ProgressHeader(
                  completed: completedExercises,
                  total: details.length,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: details.map((d) {
                      _keys[d.exerciseId] ??= GlobalKey<_ExerciseTileState>();
                      final st = _keys[d.exerciseId]!.currentState;
                      final done = st?.isComplete(logsMap) ?? false;
                      return _ExerciseTile(
                        key: _keys[d.exerciseId],
                        detail: d,
                        expanded: _expandedExerciseId == d.exerciseId,
                        onToggle: () => setState(() {
                          _expandedExerciseId =
                              _expandedExerciseId == d.exerciseId ? null : d.exerciseId;
                        }),
                        logsMap: logsMap,
                        highlightDone: done,
                        onChanged: () => setState(() {}),
                        removeLog: notifier.remove,
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

  // ═════════════════════════════ helpers ══════════════════════════════════
  String _formatTime(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  Future<bool> _confirmExit(
      BuildContext ctx, WorkoutLogNotifier notifier) async {
    return await showModalBottomSheet<bool>(
          context: ctx,
          isDismissible: false,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48),
                const SizedBox(height: 12),
                const Text('¿Salir sin guardar?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Perderás el progreso de esta sesión.'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          notifier.clear();
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Salir'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ) ??
        false;
  }

  // ─────────── Diálogo de finalización ────────────
  Future<bool> _showFinishDialog(BuildContext ctx) async {
    String localFatigue = _fatigue;
    String localMood = _mood;
    final localNotesCtl = TextEditingController(text: _notesCtl.text);
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.flag_rounded),
              SizedBox(width: 8),
              Text('Finalizar sesión'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NiceDropdown(
                  icon: Icons.bolt_rounded,
                  value: localFatigue,
                  items: const ['Easy', 'Normal', 'Exhausted'],
                  onChanged: (v) => setD(() => localFatigue = v),
                ),
                const SizedBox(height: 8),
                _NiceDropdown(
                  icon: Icons.mood_rounded,
                  value: localMood,
                  items: const ['🙂', '😐', '😫'],
                  onChanged: (v) => setD(() => localMood = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: localNotesCtl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 20),
                  label: Text('${_sw.elapsed.inMinutes} min de sesión'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                _fatigue = localFatigue;
                _mood = localMood;
                _notesCtl.text = localNotesCtl.text;
                Navigator.pop(dCtx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }
}

// ════════════════════ HEADERS & WIDGETS AUX ════════════════════

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: cs.primaryContainer.withOpacity(.4),
              offset: const Offset(0, 2),
              blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded),
              const SizedBox(width: 6),
              Text('Ejercicios $completed / $total',
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 6,
            backgroundColor: cs.onPrimaryContainer.withOpacity(.2),
          )
        ],
      ),
    );
  }
}

class _NiceDropdown extends StatelessWidget {
  const _NiceDropdown(
      {required this.icon,
      required this.value,
      required this.items,
      required this.onChanged});
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v ?? value),
    );
  }
}

// ═══════════════════════════  TILE  ════════════════════════════

class _ExerciseTile extends StatefulWidget {
  final dynamic detail;
  final bool expanded;
  final VoidCallback onToggle;
  final Map<String, WorkoutLogEntry> logsMap;
  final bool highlightDone;
  final VoidCallback onChanged;
  final void Function(WorkoutLogEntry) removeLog;

  const _ExerciseTile({
    super.key,
    required this.detail,
    required this.expanded,
    required this.onToggle,
    required this.logsMap,
    required this.highlightDone,
    required this.onChanged,
    required this.removeLog,
  });

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  late List<TextEditingController> _repCtl;
  late List<TextEditingController> _kgCtl;
  late List<TextEditingController> _rirCtl;

  @override
  void initState() {
    super.initState();
    _buildControllers(widget.detail.sets);
  }

  void _buildControllers(int n) {
    _repCtl = List.generate(
        n, (_) => TextEditingController(text: widget.detail.reps.toString()));
    _kgCtl = List.generate(n,
        (_) => TextEditingController(text: widget.detail.weight.toStringAsFixed(0)));
    _rirCtl =
        List.generate(n, (_) => TextEditingController(text: '2'));
  }

  // ───── añadir / quitar sets ─────
  void _addSet() {
    setState(() {
      _repCtl
          .add(TextEditingController(text: widget.detail.reps.toString()));
      _kgCtl.add(TextEditingController(
          text: widget.detail.weight.toStringAsFixed(0)));
      _rirCtl.add(TextEditingController(text: '2'));
    });
    widget.onChanged();
  }

  void _removeSet() {
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
    setState(() {});
    widget.onChanged();
  }

  bool isComplete(Map<String, WorkoutLogEntry> logs) {
    for (var s = 1; s <= _repCtl.length; s++) {
      if (!(logs['${widget.detail.exerciseId}-$s']?.completed ?? false)) {
        return false;
      }
    }
    return true;
  }

  void logCurrentSet({
    required void Function(WorkoutLogEntry) addOrUpdate,
    required int planId,
  }) {
    int current = 1;
    String key(int s) => '${widget.detail.exerciseId}-$s';
    for (var s = 1; s <= _repCtl.length; s++) {
      if (!(widget.logsMap[key(s)]?.completed ?? false)) {
        current = s;
        break;
      }
      if (s == _repCtl.length) current = s;
    }

    addOrUpdate(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: current,
        reps: int.tryParse(_repCtl[current - 1].text) ?? widget.detail.reps,
        weight:
            double.tryParse(_kgCtl[current - 1].text) ?? widget.detail.weight,
        rir: int.tryParse(_rirCtl[current - 1].text) ?? 2,
        completed: true,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serie $current registrada/actualizada')));
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String keyBy(int s) => '${widget.detail.exerciseId}-$s';

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: widget.highlightDone ? cs.secondaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(.1),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(widget.detail.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Icon(
                widget.expanded ? Icons.expand_less : Icons.expand_more,
                color: cs.primary,
              ),
            ),
            if (widget.expanded) ...[
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _removeSet,
                      icon: const Icon(Icons.remove),
                      label: const Text('Set'),
                      style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _addSet,
                      icon: const Icon(Icons.add),
                      label: const Text('Set'),
                      style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ),
              Column(
                children: List.generate(_repCtl.length, (i) {
                  final logged =
                      widget.logsMap[keyBy(i + 1)]?.completed ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        _numField(_repCtl[i], width: 52, suffix: 'r'),
                        const SizedBox(width: 12),
                        _numField(_kgCtl[i], width: 70, suffix: 'kg'),
                        const SizedBox(width: 12),
                        _numField(_rirCtl[i], width: 54, suffix: 'RIR'),
                        const Spacer(),
                        Icon(
                          logged
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: logged ? cs.primary : cs.outline,
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctl,
      {required double width, required String suffix}) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: TextField(
        controller: ctl,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        onTap: () => ctl.selection = TextSelection(baseOffset: 0, extentOffset: ctl.text.length),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          isDense: true,
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.primary),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
