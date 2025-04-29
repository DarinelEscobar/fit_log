// lib/src/features/routines/presentation/pages/start_routine_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final asyncDetails =
        ref.watch(planExerciseDetailsProvider(widget.planId));
    final logs = ref.watch(workoutLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_fmt(_sw.elapsed)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Finalizar sesión',
            onPressed: () async {
              final ok = await _finishDialog(context);
              if (!ok) return;
              final repo = WorkoutPlanRepositoryImpl();
              await SaveWorkoutLogsUseCase(repo)(logs);
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
              ref.read(workoutLogProvider.notifier).clear();
              if (mounted) Navigator.pop(context);
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text('Log exercise'),
        onPressed: () {
          if (_expandedExerciseId == null) return;
          final tileKey = _keys[_expandedExerciseId]!;
          tileKey.currentState!.logNextSet(
            (e) => ref.read(workoutLogProvider.notifier).add(e),
            widget.planId,
          );
        },
      ),
      body: asyncDetails.when(
        data: (details) => ListView(
          children: details.map((d) {
            _keys[d.exerciseId] ??= GlobalKey<_ExerciseTileState>();
            return _ExerciseTile(
              key: _keys[d.exerciseId],
              detail: d,
              expanded: _expandedExerciseId == d.exerciseId,
              onExpand: () => setState(() {
                _expandedExerciseId =
                    _expandedExerciseId == d.exerciseId ? null : d.exerciseId;
              }),
              logged: logs,
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ------------- diálogo de cierre (fatiga, mood, notas) -------------
  String _fatigue = 'Normal';
  String _mood = '🙂';
  final _notesCtl = TextEditingController();

  Future<bool> _finishDialog(BuildContext ctx) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Finalizar sesión'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: _fatigue,
                  items: const [
                    DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Exhausted', child: Text('Exhausted')),
                  ],
                  onChanged: (v) => setState(() => _fatigue = v!),
                ),
                DropdownButton<String>(
                  value: _mood,
                  items: const [
                    DropdownMenuItem(value: '🙂', child: Text('🙂')),
                    DropdownMenuItem(value: '😐', child: Text('😐')),
                    DropdownMenuItem(value: '😫', child: Text('😫')),
                  ],
                  onChanged: (v) => setState(() => _mood = v!),
                ),
                TextField(
                  controller: _notesCtl,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
                const SizedBox(height: 12),
                Text('Duración: ${_sw.elapsed.inMinutes} min'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
            ],
          ),
        ) ??
        false;
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}

// ───────────────── tile con sets y logNextSet() ─────────────────────
class _ExerciseTile extends StatefulWidget {
  final dynamic detail;
  final bool expanded;
  final VoidCallback onExpand;
  final List<WorkoutLogEntry> logged;
  const _ExerciseTile({
    super.key,
    required this.detail,
    required this.expanded,
    required this.onExpand,
    required this.logged,
  });
  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _SeriesControllers extends InheritedWidget {
  final List<TextEditingController> reps;
  final List<TextEditingController> kg;
  final List<TextEditingController> rir;
  const _SeriesControllers({
    required super.child,
    required this.reps,
    required this.kg,
    required this.rir,
  });
  static _SeriesControllers? of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_SeriesControllers>();
  @override
  bool updateShouldNotify(_) => false;
}

class _ExerciseTileState extends State<_ExerciseTile> {
  late final List<TextEditingController> _repCtl;
  late final List<TextEditingController> _kgCtl;
  late final List<TextEditingController> _rirCtl;

  @override
  void initState() {
    super.initState();
    _repCtl = List.generate(
      widget.detail.sets,
      (_) => TextEditingController(text: widget.detail.reps.toString()),
    );
    _kgCtl = List.generate(
      widget.detail.sets,
      (_) => TextEditingController(text: widget.detail.weight.toString()),
    );
    _rirCtl =
        List.generate(widget.detail.sets, (_) => TextEditingController(text: '2'));
  }

  // -------- método invocado por FAB (StartRoutineScreen) -------------
  void logNextSet(void Function(WorkoutLogEntry) add, int planId) {
    final done = widget.logged
        .where((l) => l.exerciseId == widget.detail.exerciseId)
        .length;
    if (done >= widget.detail.sets) return;

    final entry = WorkoutLogEntry(
      date: DateTime.now(),
      planId: planId,
      exerciseId: widget.detail.exerciseId,
      setNumber: done + 1,
      reps: int.tryParse(_repCtl[done].text) ?? widget.detail.reps,
      weight: double.tryParse(_kgCtl[done].text) ?? widget.detail.weight,
      rir: int.tryParse(_rirCtl[done].text) ?? 2,
    );
    add(entry);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Serie ${entry.setNumber} registrada')),
    );
  }
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return _SeriesControllers(
      reps: _repCtl,
      kg: _kgCtl,
      rir: _rirCtl,
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: Text(widget.detail.name),
              trailing: IconButton(
                icon: Icon(
                    widget.expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: widget.onExpand,
              ),
            ),
            if (widget.expanded)
              Column(
                children: List.generate(widget.detail.sets, (i) {
                  final loggedSet = widget.logged.any((l) =>
                      l.exerciseId == widget.detail.exerciseId &&
                      l.setNumber == i + 1);
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('Serie ${i + 1}')),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _repCtl[i],
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Text(' reps  '),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _kgCtl[i],
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Text(' kg  '),
                        SizedBox(
                          width: 40,
                          child: TextField(
                            controller: _rirCtl[i],
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Text(' RIR'),
                        const SizedBox(width: 8),
                        Icon(
                          loggedSet
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: loggedSet ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
