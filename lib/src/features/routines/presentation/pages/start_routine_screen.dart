import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../performance/presentation/providers/performance_providers.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/usecases/save_workout_logs_usecase.dart';
import '../../domain/usecases/save_workout_session_usecase.dart';
import '../../services/workout_session_helper.dart';
import '../models/finish_session_summary_draft.dart';
import '../providers/exercises_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import '../widgets/active_session_exercise_card.dart';
import '../widgets/active_session_notes_card.dart';
import '../widgets/confirm_exit_sheet.dart';
import 'finish_session_summary_screen.dart';
import 'select_exercise_screen.dart';

class StartRoutineScreen extends ConsumerStatefulWidget {
  const StartRoutineScreen({
    required this.plan,
    this.now = DateTime.now,
    super.key,
  });

  final WorkoutPlan plan;
  final DateTime Function() now;

  @override
  ConsumerState<StartRoutineScreen> createState() => _StartRoutineScreenState();
}

class _StartRoutineScreenState extends ConsumerState<StartRoutineScreen>
    with WidgetsBindingObserver {
  static const int _defaultSets = 3;

  late final DateTime _sessionStartedAt;
  late final Timer _ticker;
  late DateTime _now;
  final TextEditingController _notesCtl = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  final Map<int, GlobalKey<ActiveSessionExerciseCardState>> _cardKeys = {};
  final Map<int, int> _setCountsByExercise = {};
  final Map<String, WorkoutLogEntry> _sessionLogs = {};

  List<PlanExerciseDetail>? _sessionDetails;
  Map<int, Exercise>? _exerciseMap;
  int? _expandedExerciseId;
  String? _energy;
  String? _mood;
  bool _showNotesComposer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.now();
    _sessionStartedAt = _now;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshClock(syncRestTimers: true, vibrateOnCompletion: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showSnackBar('Session started. Track clean sets and finish strong.');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.cancel();
    _notesCtl.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshClock(syncRestTimers: true, vibrateOnCompletion: false);
    }
  }

  Duration _sessionDurationAt(DateTime now) =>
      now.difference(_sessionStartedAt);

  void _refreshClock({
    bool syncRestTimers = false,
    required bool vibrateOnCompletion,
  }) {
    if (!mounted) {
      return;
    }

    final now = widget.now();
    setState(() {
      _now = now;
    });
    if (syncRestTimers) {
      _syncRestTimers(now, vibrateOnCompletion: vibrateOnCompletion);
    }
  }

  void _syncRestTimers(
    DateTime now, {
    required bool vibrateOnCompletion,
  }) {
    for (final key in _cardKeys.values) {
      unawaited(
        key.currentState?.syncRestTimer(
          now,
          vibrateOnCompletion: vibrateOnCompletion,
        ),
      );
    }
  }

  List<WorkoutLogEntry> get _completedLogs {
    return _sessionLogs.values
        .where((entry) => entry.completed)
        .toList(growable: false);
  }

  int get _completedSetCount => _completedLogs.length;

  int get _totalSetCount {
    final details = _sessionDetails;
    if (details == null) {
      return 0;
    }
    return details.fold(
      0,
      (sum, detail) =>
          sum + (_setCountsByExercise[detail.exerciseId] ?? detail.sets),
    );
  }

  double get _volumeKg {
    return _completedLogs.fold(
      0,
      (sum, entry) => sum + (entry.weight * entry.reps),
    );
  }

  double get _completionRatio {
    final totalSets = _totalSetCount;
    if (totalSets == 0) {
      return 0;
    }
    return _completedSetCount / totalSets;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _initializeSessionData(
    List<PlanExerciseDetail> details,
    List<Exercise> exercises,
  ) {
    _exerciseMap ??= {for (final exercise in exercises) exercise.id: exercise};

    if (_sessionDetails != null) {
      return;
    }

    _sessionDetails = List<PlanExerciseDetail>.from(details);
    for (final detail in _sessionDetails!) {
      _setCountsByExercise[detail.exerciseId] = detail.sets;
      _cardKeys[detail.exerciseId] =
          GlobalKey<ActiveSessionExerciseCardState>();
    }
    if (_sessionDetails!.isNotEmpty) {
      _expandedExerciseId = _sessionDetails!.first.exerciseId;
    }
  }

  String _logKey(int exerciseId, int setNumber) => '$exerciseId-$setNumber';

  void _saveDraftLog(WorkoutLogEntry entry) {
    _sessionLogs[_logKey(entry.exerciseId, entry.setNumber)] = entry;
  }

  void _completeLog(WorkoutLogEntry entry) {
    setState(() {
      _sessionLogs[_logKey(entry.exerciseId, entry.setNumber)] =
          entry.copyWith(completed: true);
    });
  }

  void _removeLog(WorkoutLogEntry entry) {
    setState(() {
      _sessionLogs.remove(_logKey(entry.exerciseId, entry.setNumber));
    });
  }

  Future<void> swapExercise(int index) async {
    if (_sessionDetails == null || _exerciseMap == null) {
      return;
    }
    final detail = _sessionDetails![index];
    final groups = <String>{};
    for (final item in _sessionDetails!) {
      final group = _exerciseMap![item.exerciseId]?.mainMuscleGroup;
      if (group != null) {
        groups.add(group);
      }
    }
    final picked = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(groups: groups),
      ),
    );
    if (picked == null) {
      return;
    }

    final existingKeys = _sessionLogs.keys
        .where((key) => key.startsWith('${detail.exerciseId}-'))
        .toList(growable: false);
    for (final key in existingKeys) {
      _sessionLogs.remove(key);
    }

    setState(() {
      _cardKeys.remove(detail.exerciseId);
      final existingSetCount =
          _setCountsByExercise.remove(detail.exerciseId) ?? detail.sets;
      final newDetail = detail.copyWith(
        exerciseId: picked.id,
        name: picked.name,
        description: picked.description,
      );
      _sessionDetails![index] = newDetail;
      _exerciseMap![picked.id] = picked;
      _setCountsByExercise[newDetail.exerciseId] = existingSetCount;
      _cardKeys[newDetail.exerciseId] =
          GlobalKey<ActiveSessionExerciseCardState>();
      if (_expandedExerciseId == detail.exerciseId) {
        _expandedExerciseId = newDetail.exerciseId;
      }
    });
  }

  Future<void> addExercise() async {
    if (_exerciseMap == null) {
      return;
    }
    final groups = <String>{};
    for (final item in _sessionDetails ?? []) {
      final group = _exerciseMap![item.exerciseId]?.mainMuscleGroup;
      if (group != null) {
        groups.add(group);
      }
    }
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(groups: groups),
      ),
    );
    if (exercise == null) {
      return;
    }

    setState(() {
      final newDetail = PlanExerciseDetail(
        exerciseId: exercise.id,
        name: exercise.name,
        description: exercise.description,
        sets: _defaultSets,
        reps: 10,
        weight: 0,
        restSeconds: 90,
        rir: 2,
        tempo: '3-1-1-0',
      );
      _sessionDetails ??= [];
      _sessionDetails!.add(newDetail);
      _exerciseMap![exercise.id] = exercise;
      _setCountsByExercise[newDetail.exerciseId] = newDetail.sets;
      _cardKeys[newDetail.exerciseId] =
          GlobalKey<ActiveSessionExerciseCardState>();
      _expandedExerciseId = newDetail.exerciseId;
    });
  }

  Future<void> _handleExitAttempt() async {
    final exit = await showConfirmExitSheet(context);
    if (!mounted || !exit) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openFinishSummary() async {
    if (_completedLogs.isEmpty) {
      _showSnackBar('Complete at least one set before finishing the session.');
      return;
    }

    final now = widget.now();
    final duration = _sessionDurationAt(now);

    final result = await FinishSessionSummaryScreen.show(
      context,
      draft: FinishSessionSummaryDraft(
        planName: widget.plan.name,
        duration: duration,
        volumeKg: _volumeKg,
        completedSets: _completedSetCount,
        totalSets: _totalSetCount,
        notes: _notesCtl.text,
        energy: _energy,
        mood: _mood,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result.action) {
      case FinishSessionSummaryAction.discard:
        return;
      case FinishSessionSummaryAction.resume:
        setState(() {
          _energy = result.energy;
          _mood = result.mood;
          _notesCtl.text = result.notes;
        });
        return;
      case FinishSessionSummaryAction.save:
        final repo = ref.read(workoutPlanRepositoryProvider);
        await SaveWorkoutLogsUseCase(repo)(_completedLogs);
        await SaveWorkoutSessionUseCase(repo)(
          WorkoutSession(
            planId: widget.plan.id,
            date: now,
            fatigueLevel: result.energy!,
            durationMinutes: duration.inMinutes,
            mood: result.mood!,
            notes: result.notes,
          ),
        );
        ref.invalidate(workoutLogsProvider);
        ref.invalidate(workoutSessionsProvider);
        ref.invalidate(performanceDashboardProvider);
        ref.invalidate(exerciseProgressDetailProvider);
        if (!mounted) {
          return;
        }
        _showSnackBar('Session saved.');
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final sessionDuration = _sessionDurationAt(now);
    final asyncDetails = ref.watch(planExerciseDetailsProvider(widget.plan.id));
    final asyncExercises = ref.watch(allExercisesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleExitAttempt();
      },
      child: Scaffold(
        backgroundColor: KineticNoirPalette.background,
        appBar: AppBar(
          backgroundColor: KineticNoirPalette.background,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 92,
          leading: IconButton(
            key: const Key('active-session-close'),
            icon: const Icon(Icons.close_rounded),
            color: KineticNoirPalette.onSurface,
            onPressed: _handleExitAttempt,
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.plan.name,
                key: const Key('active-session-title'),
                style: KineticNoirTypography.headline(
                  size: 20,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _HeaderMetaChip(
                    label: WorkoutSessionHelper.formatDuration(sessionDuration),
                  ),
                  _HeaderMetaChip(
                    label: '$_completedSetCount/$_totalSetCount sets',
                  ),
                  _HeaderMetaChip(
                    label: '${_volumeKg.toStringAsFixed(0)} KG',
                  ),
                  _HeaderMetaChip(
                    label: '${(_completionRatio * 100).round()}%',
                    isHighlighted: true,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('active-session-finish'),
              onPressed: _openFinishSummary,
              child: Text(
                'FINISH',
                style: KineticNoirTypography.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.primary,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: isKeyboardVisible ? bottomInset : 24,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: kineticPrimaryGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: KineticNoirPalette.shadow.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: FilledButton.icon(
              key: const Key('active-session-register-set'),
              onPressed: _expandedExerciseId == null
                  ? null
                  : () {
                      final cardState =
                          _cardKeys[_expandedExerciseId!]?.currentState;
                      if (cardState == null) {
                        return;
                      }
                      final didRegister = cardState.logCurrentSet();
                      if (didRegister) {
                        _showSnackBar('Set registered.');
                      } else {
                        _showSnackBar(
                          'All visible sets are complete. Add a new set to keep going.',
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor:
                    Colors.transparent.withValues(alpha: 0.4),
                shadowColor: Colors.transparent,
                foregroundColor: KineticNoirPalette.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                'REGISTER SET',
                style: KineticNoirTypography.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onPrimary,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ),
        ),
        body: asyncExercises.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: KineticNoirPalette.primary),
          ),
          error: (error, _) => _AsyncErrorState(error: '$error'),
          data: (exercises) => asyncDetails.when(
            loading: () => const Center(
              child:
                  CircularProgressIndicator(color: KineticNoirPalette.primary),
            ),
            error: (error, _) => _AsyncErrorState(error: '$error'),
            data: (details) {
              _initializeSessionData(details, exercises);

              final sessionDetails =
                  _sessionDetails ?? const <PlanExerciseDetail>[];
              if (sessionDetails.isEmpty) {
                return const _EmptySessionState();
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        12,
                        24,
                        isKeyboardVisible ? 120 + bottomInset : 132,
                      ),
                      children: [
                        ActiveSessionNotesCard(
                          controller: _notesCtl,
                          focusNode: _notesFocusNode,
                          isVisible: _showNotesComposer,
                          onToggleVisibility: () {
                            setState(
                                () => _showNotesComposer = !_showNotesComposer);
                          },
                        ),
                        const SizedBox(height: 14),
                        for (var index = 0;
                            index < sessionDetails.length;
                            index++)
                          ActiveSessionExerciseCard(
                            key: _cardKeys[sessionDetails[index].exerciseId],
                            detail: sessionDetails[index],
                            exercise:
                                _exerciseMap?[sessionDetails[index].exerciseId],
                            planId: widget.plan.id,
                            exerciseNumber: index + 1,
                            now: now,
                            expanded: _expandedExerciseId ==
                                sessionDetails[index].exerciseId,
                            logsMap: _sessionLogs,
                            onToggle: () => setState(() {
                              final exerciseId =
                                  sessionDetails[index].exerciseId;
                              _expandedExerciseId =
                                  _expandedExerciseId == exerciseId
                                      ? null
                                      : exerciseId;
                            }),
                            onSetCountChanged: (count) => setState(() {
                              _setCountsByExercise[
                                  sessionDetails[index].exerciseId] = count;
                            }),
                            saveDraftLog: _saveDraftLog,
                            completeLog: _completeLog,
                            removeLog: _removeLog,
                            onSwap: () => swapExercise(index),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('active-session-add-exercise'),
                          onPressed: addExercise,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                KineticNoirPalette.onSurfaceVariant,
                            side: BorderSide(
                              color: KineticNoirPalette.outlineVariant
                                  .withValues(alpha: 0.35),
                              style: BorderStyle.solid,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: Text(
                            'ADD EXERCISE',
                            style: KineticNoirTypography.body(
                              size: 12,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.onSurfaceVariant,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderMetaChip extends StatelessWidget {
  const _HeaderMetaChip({
    required this.label,
    this.isHighlighted = false,
  });

  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? KineticNoirPalette.primary.withValues(alpha: 0.12)
            : KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KineticNoirTypography.body(
          size: 10,
          weight: FontWeight.w800,
          color: isHighlighted
              ? KineticNoirPalette.primary
              : KineticNoirPalette.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmptySessionState extends StatelessWidget {
  const _EmptySessionState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'This routine has no exercises yet.',
          textAlign: TextAlign.center,
          style: KineticNoirTypography.body(
            size: 15,
            weight: FontWeight.w700,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AsyncErrorState extends StatelessWidget {
  const _AsyncErrorState({
    required this.error,
  });

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Unable to load the active session.\n$error',
          textAlign: TextAlign.center,
          style: KineticNoirTypography.body(
            size: 15,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
