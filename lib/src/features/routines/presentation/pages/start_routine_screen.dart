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
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/save_workout_logs_usecase.dart';
import '../../domain/usecases/save_workout_session_usecase.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/progress_header.dart';
import '../widgets/scale_dropdown.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../providers/exercises_provider.dart';
import 'select_exercise_screen.dart';

class StartRoutineScreen extends ConsumerStatefulWidget {
  final int planId;
  const StartRoutineScreen({required this.planId, super.key});
  @override
  ConsumerState<StartRoutineScreen> createState() => _StartRoutineScreenState();
}

class _StartRoutineScreenState extends ConsumerState<StartRoutineScreen> {
  late final Timer _ticker;
  final Map<int, GlobalKey<ExerciseTileState>> _keys = {};
  int? _expandedExerciseId;
  List<PlanExerciseDetail>? _sessionDetails;
  Map<int, Exercise>? _exerciseMap;

  String _fatigue = '5';
  String _mood = '3';
  final TextEditingController _notesCtl = TextEditingController();
  bool _showBest = true;

  static const List<String> _scale10 = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];
  static const List<String> _scale5 = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(workoutLogProvider.notifier);
    notifier.startSession();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('No has completado ninguna serie')));
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                final done = list
                    .where((d) =>
                        _keys[d.exerciseId]?.currentState?.isComplete(logsMap) ??
                        false)
                    .length;
                return Column(
                  children: [
                    ProgressHeader(completed: done, total: list.length),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 100, 12, 80),
                        children: [
                          for (var entry in list.asMap().entries)
                            Consumer(
                              builder: (context, ref, _) {
                                final d = entry.value;
                                final idx = entry.key;
                                _keys[d.exerciseId] ??=
                                    GlobalKey<ExerciseTileState>();
                                final doneEx = _keys[d.exerciseId]
                                        ?.currentState
                                        ?.isComplete(logsMap) ??
                                    false;
                                final asyncLogs = ref.watch(
                                    logsByExerciseProvider(d.exerciseId));
                                return asyncLogs.when(
                                  data: (logs) {
                                    final last = _lastLogs(logs);
                                    final best = _bestLogs(logs);
                                    return ExerciseTile(
                                      key: _keys[d.exerciseId],
                                      detail: d,
                                      expanded: _expandedExerciseId ==
                                          d.exerciseId,
                                      onToggle: () => setState(() {
                                        _expandedExerciseId =
                                            _expandedExerciseId ==
                                                    d.exerciseId
                                                ? null
                                                : d.exerciseId;
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
                                    key: _keys[d.exerciseId],
                                    detail: d,
                                    expanded: _expandedExerciseId ==
                                        d.exerciseId,
                                    onToggle: () => setState(() {
                                      _expandedExerciseId =
                                          _expandedExerciseId ==
                                                  d.exerciseId
                                              ? null
                                              : d.exerciseId;
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
                                    key: _keys[d.exerciseId],
                                    detail: d,
                                    expanded: _expandedExerciseId ==
                                        d.exerciseId,
                                    onToggle: () => setState(() {
                                      _expandedExerciseId =
                                          _expandedExerciseId ==
                                                  d.exerciseId
                                              ? null
                                              : d.exerciseId;
                                    }),
                                    logsMap: logsMap,
                                    highlightDone: doneEx,
    final groups = ['Todos', ...{
      for (final e in alternatives) if (e.mainMuscleGroup.isNotEmpty) e.mainMuscleGroup
    }];
      isScrollControlled: true,
      builder: (ctx) {
        String query = '';
        String group = 'Todos';
        return StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = alternatives.where((e) {
              final byGroup = group == 'Todos' || e.mainMuscleGroup == group;
              final byName = e.name.toLowerCase().contains(query.toLowerCase());
              return byGroup && byName;
            }).toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                  if (groups.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: group,
                        onChanged: (v) => setState(() => group = v!),
                        items: groups
                            .map((g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g),
                                ))
                            .toList(),
                      ),
                    ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: filtered
                          .map((e) => ListTile(
                                title: Text(e.name),
                                subtitle:
                                    Text('${e.category} • ${e.mainMuscleGroup}'),
                                onTap: () => Navigator.pop(ctx, e),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
                            ),
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

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  Future<void> _swapExercise(int index) async {
    if (_sessionDetails == null) return;
    final detail = _sessionDetails![index];
    final alternatives = await ref
        .read(similarExercisesProvider(detail.exerciseId).future);
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
      for (var i = 1; i <= detail.sets; i++) {
        notifier.remove(WorkoutLogEntry(
            date: DateTime.now(),
            planId: widget.planId,
            exerciseId: detail.exerciseId,
            setNumber: i,
            reps: 0,
            weight: 0,
            rir: 0));
      }
      setState(() {
        _keys.remove(detail.exerciseId);
        final newDetail = detail.copyWith(
            exerciseId: picked.id,
            name: picked.name,
            description: picked.description);
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
        builder: (_) => SelectExerciseScreen(
          groups: groups,
        ),
      ),
    );
    if (exercise != null) {
      setState(() {
        final newDetail = PlanExerciseDetail(
          exerciseId: exercise.id,
          name: exercise.name,
          description: exercise.description,
          sets: 3,
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

  List<WorkoutLogEntry> _lastLogs(List<WorkoutLogEntry> logs) {
    if (logs.isEmpty) return [];
    logs.sort((a, b) => a.date.compareTo(b.date));
    final lastDate = logs.last.date;
    return logs
        .where((l) => l.date.isAtSameMomentAs(lastDate))
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  List<WorkoutLogEntry> _bestLogs(List<WorkoutLogEntry> logs) {
    final filtered = logs.where((l) => l.reps >= 5).toList();
    if (filtered.isEmpty) return [];
    filtered.sort((a, b) {
      final c = b.weight.compareTo(a.weight);
      if (c != 0) return c;
      return b.reps.compareTo(a.reps);
    });
    final best = filtered.first;
    return logs
        .where((l) => l.date.isAtSameMomentAs(best.date))
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  Future<bool> _confirmExit(BuildContext ctx) async =>
      await showModalBottomSheet<bool>(
        context: ctx,
        backgroundColor: const Color(0xFF1F1F1F),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('¿Salir sin guardar?',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white38)),
            const SizedBox(height: 8),
            const Text('Perderás el progreso de esta sesión.',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
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
        builder: (dCtx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Finalizar sesión'),
          titleTextStyle: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleDropdown(
                  icon: Icons.bolt,
                  val: lf,
                  list: _scale10,
                  onC: (v) => setState(() => lf = v)),
              const SizedBox(height: 8),
              ScaleDropdown(
                  icon: Icons.mood,
                  val: lm,
                  list: _scale5,
                  onC: (v) => setState(() => lm = v)),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dCtx).pop(false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.of(dCtx).pop(true),
                child: const Text('Finalizar')),
          ],
        ),
      ),
    );
    if (ok == true) {
      _fatigue = lf;
      _mood = lm;
      _notesCtl.text = noteCtl.text;
    }
    return ok ?? false;
  }
}
