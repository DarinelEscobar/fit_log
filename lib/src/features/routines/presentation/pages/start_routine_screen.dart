import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../state/workout_log_state.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/usecases/save_workout_logs_usecase.dart';
import '../../domain/usecases/save_workout_session_usecase.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/finish_session_dialog.dart';
import '../widgets/confirm_exit_sheet.dart';
import '../widgets/session_summary_card.dart';
import '../widgets/session_exercise_tile.dart';
import '../providers/exercises_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import 'select_exercise_screen.dart';
import '../../services/workout_session_helper.dart';
part 'start_routine_screen_actions.dart';

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
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);

  String? _energy;
  String? _mood;
  final TextEditingController _notesCtl = TextEditingController();
  bool _showBest = true;

  static const int _defaultSets = 3;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(workoutLogProvider.notifier);
    notifier.startSession();
    _elapsed.value = notifier.sessionDuration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed.value = notifier.sessionDuration;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showSnackBar('Sesión en marcha. ¡A por todas!');
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _notesCtl.dispose();
    _elapsed.dispose();
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
        final exit = await showConfirmExitSheet(context);
        if (exit) {
          notifier.clear();
          if (mounted) {
            _showSnackBar('Sesión cancelada. Tu progreso quedó sin guardar.');
          }
        }
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
              final exit = await showConfirmExitSheet(context);
              if (exit) {
                notifier.clear();
                if (mounted) {
                  _showSnackBar('Sesión cancelada. Tu progreso quedó sin guardar.');
                }
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: const Text('Sesión activa'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: addExercise,
            ),
            IconButton(
              icon: const Icon(Icons.flag),
              onPressed: () async {
                if (notifier.completedLogs.isEmpty) {
                  _showSnackBar('Completa al menos una serie antes de finalizar.');
                  return;
                }
                final result = await FinishSessionDialog.show(
                  context,
                  initialEnergy: _energy,
                  initialMood: _mood,
                  initialNotes: _notesCtl.text,
                );
                if (result == null) return;
                final repo = ref.read(workoutPlanRepositoryProvider);
                await SaveWorkoutLogsUseCase(repo)(notifier.completedLogs);
                await SaveWorkoutSessionUseCase(repo)(
                  WorkoutSession(
                    planId: widget.planId,
                    date: DateTime.now(),
                    fatigueLevel: result.energy,
                    durationMinutes: notifier.sessionDuration.inMinutes,
                    mood: result.mood,
                    notes: result.notes,
                  ),
                );
                _energy = result.energy;
                _mood = result.mood;
                _notesCtl.text = result.notes;
                notifier.clear();
                if (mounted) {
                  _showSnackBar('Sesión finalizada. ¡Gran trabajo hoy!');
                }
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
                final entries = list.asMap().entries.toList();
                bool isComplete(PlanExerciseDetail detail) =>
                    _keys[detail.exerciseId]?.currentState?.isComplete(logsMap) ??
                    false;
                final done = entries.where((entry) => isComplete(entry.value)).length;
                final completion = '$done/${list.length}';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: ValueListenableBuilder<Duration>(
                        valueListenable: _elapsed,
                        builder: (_, duration, __) => SessionSummaryCard(
                          duration: WorkoutSessionHelper.formatDuration(duration),
                          completion: completion,
                          showBest: _showBest,
                          onToggleBest: () => setState(() => _showBest = !_showBest),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return SessionExerciseTile(
                            detail: entry.value,
                            index: entry.key,
                            expandedExerciseId: _expandedExerciseId,
                            onToggle: (exerciseId) => setState(() {
                              _expandedExerciseId =
                                  _expandedExerciseId == exerciseId
                                      ? null
                                      : exerciseId;
                            }),
                            keys: _keys,
                            logsMap: logsMap,
                            highlightDone: isComplete(entry.value),
                            onChanged: () => setState(() {}),
                            removeLog: notifier.remove,
                            updateLog: notifier.update,
                            planId: widget.planId,
                            showBest: _showBest,
                            onSwap: () => swapExercise(entry.key),
                          );
                        },
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
