import 'dart:async';
import 'package:flutter/material.dart';
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
import '../providers/workout_plan_provider.dart';
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
    final asyncPlans = ref.watch(workoutPlanProvider);
    final currentVolume = notifier.completedLogs.fold<double>(
      0.0,
      (sum, log) => sum + (log.reps * log.weight),
    );

    final currentPlanName = asyncPlans.maybeWhen(
      data: (plans) {
        for (final plan in plans) {
          if (plan.id == widget.planId) return plan.name;
        }
        return 'WORKOUT';
      },
      orElse: () => 'WORKOUT',
    );

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) async {
        if (didPop) return;
        final exit = await showConfirmExitSheet(context);
        if (exit) {
          notifier.clear();
          if (mounted) {
            _showSnackBar('Sesión cancelada. Tu progreso quedó sin guardar.');
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E0E0F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFADAAAB)),
            onPressed: () async {
              final exit = await showConfirmExitSheet(context);
              if (exit) {
                notifier.clear();
                if (mounted) {
                  _showSnackBar(
                      'Sesión cancelada. Tu progreso quedó sin guardar.');
                  Navigator.pop(context);
                }
              }
            },
          ),
          title: ValueListenableBuilder<Duration>(
            valueListenable: _elapsed,
            builder: (_, duration, __) {
              final minutes = duration.inMinutes.toString().padLeft(2, '0');
              final seconds =
                  (duration.inSeconds % 60).toString().padLeft(2, '0');
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Color(0xFFCC97FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$minutes:$seconds',
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Color(0xFFCC97FF),
                    ),
                  ),
                ],
              );
            },
          ),
          centerTitle: false,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () async {
                    if (notifier.completedLogs.isEmpty) {
                      _showSnackBar(
                          'Completa al menos una serie antes de finalizar.');
                      return;
                    }
                    final result = await FinishSessionDialog.show(
                      context,
                      initialEnergy: _energy,
                      initialMood: _mood,
                      initialNotes: _notesCtl.text,
                      durationMinutes: notifier.sessionDuration.inMinutes,
                      volume: currentVolume,
                    );
                    if (result == null) return;
                    final repo = ref.read(workoutPlanRepositoryProvider);
                    await SaveWorkoutLogsUseCase(repo)(notifier.completedLogs);
                    await SaveWorkoutSessionUseCase(repo)(
                      WorkoutSession(
                        durationMinutes: notifier.sessionDuration.inMinutes,
                        planId: widget.planId,
                        date: DateTime.now(),
                        fatigueLevel: result.energy,
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
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC97FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'FINISH',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Color(0xFFCC97FF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: asyncAll.when(
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
                      _keys[detail.exerciseId]
                          ?.currentState
                          ?.isComplete(logsMap) ??
                      false;
                  final done =
                      entries.where((entry) => isComplete(entry.value)).length;
                  final completion = '$done/${list.length}';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: Text(
                          currentPlanName.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Color(0xFFCC97FF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: SessionSummaryCard(
                          duration: WorkoutSessionHelper.formatDuration(
                              _elapsed.value),
                          completion: completion,
                          showBest: _showBest,
                          onToggleBest: () =>
                              setState(() => _showBest = !_showBest),
                          volume: currentVolume,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            24,
                            24,
                            80 + bottomInset,
                          ),
                          itemCount:
                              entries.length + 1, // +1 for the global actions
                          itemBuilder: (context, index) {
                            if (index == entries.length) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, bottom: 32.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: addExercise,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A191B),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: const Color(0xFF484849)
                                                    .withValues(alpha: 0.1)),
                                          ),
                                          child: const Column(
                                            children: [
                                              Icon(Icons.add_circle,
                                                  color: Color(0xFFADAAAB)),
                                              SizedBox(height: 4),
                                              Text(
                                                'ADD EXERCISE',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  color: Color(0xFFADAAAB),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
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
      ),
    );
  }
}
