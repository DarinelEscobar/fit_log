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
import '../widgets/exercise_tile.dart';
import '../widgets/progress_header.dart';
import '../widgets/scale_dropdown.dart';

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
                ProgressHeader(completed: done, total: dets.length),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 100, 12, 80),
                    children: dets.map((d) {
                      _keys[d.exerciseId] ??= GlobalKey<ExerciseTileState>();
                      final doneEx =
                          _keys[d.exerciseId]!.currentState?.isComplete(logsMap) ?? false;
                      return ExerciseTile(
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
            ScaleDropdown(icon: Icons.bolt, val: lf, list: _scale10, onC: (v) => setD(() => lf = v)),
            const SizedBox(height: 8),
            ScaleDropdown(icon: Icons.mood, val: lm, list: _scale5, onC: (v) => setD(() => lm = v)),
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
