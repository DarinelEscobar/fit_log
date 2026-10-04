import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../performance/presentation/providers/performance_providers.dart';
import '../../../performance/presentation/providers/active_exercise_progress_provider.dart';
import '../../domain/entities/active_session_exercise_setup_preset.dart';
import '../../domain/entities/active_workout_session_draft.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/weight_display_unit.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/warm_up_session_state.dart';
import '../../domain/entities/warm_up_step.dart';
import '../../domain/usecases/active_session_draft_usecases.dart';
import '../../domain/usecases/active_session_exercise_setup_preset_usecases.dart';
import '../../services/workout_session_helper.dart';
import '../models/finish_session_summary_draft.dart';
import '../providers/exercises_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import '../providers/warm_up_steps_provider.dart';
import '../widgets/active_session_exercise_card.dart';
import '../widgets/active_session_exercise_sections.dart';
import '../widgets/active_session_exercise_setup_sheet.dart';
import '../widgets/active_session_notes_card.dart';
import '../widgets/confirm_exit_sheet.dart';
import '../widgets/warm_up_flow.dart';
import '../../../../utils/notification_service.dart';
import 'finish_session_summary_screen.dart';
import 'select_exercise_screen.dart';

class StartRoutineScreen extends ConsumerStatefulWidget {
  const StartRoutineScreen({
    required this.plan,
    this.recoveredDraft,
    this.now = DateTime.now,
    super.key,
  });

  final WorkoutPlan plan;
  final ActiveWorkoutSessionDraft? recoveredDraft;
  final DateTime Function() now;

  @override
  ConsumerState<StartRoutineScreen> createState() => _StartRoutineScreenState();
}

class _StartRoutineScreenState extends ConsumerState<StartRoutineScreen>
    with WidgetsBindingObserver {
  static const int _defaultSets = 3;

  late final DateTime _sessionStartedAt;
  late final Timer _ticker;
  late final ValueNotifier<DateTime> _clockNotifier;
  late DateTime _now;
  Timer? _draftSaveTimer;
  Future<void> _draftWrite = Future<void>.value();
  bool _endingSession = false;
  bool _savingSession = false;
  final TextEditingController _notesCtl = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  final Map<int, GlobalKey<ActiveSessionExerciseCardState>> _cardKeys = {};
  final Map<int, int> _setCountsByExercise = {};
  final Map<int, WeightDisplayUnit> _weightUnitsByExercise = {};
  final Map<String, WorkoutLogEntry> _sessionLogs = {};
  final Map<int, DateTime> _restEndsAtByExercise = {};
  final Set<int> _setupEditableExerciseIds = <int>{};

  List<PlanExerciseDetail>? _sessionDetails;
  Map<int, Exercise>? _exerciseMap;
  int? _expandedExerciseId;
  int? _lastFocusedExerciseId;
  String? _energy;
  String? _mood;
  bool _showNotesComposer = false;
  List<WarmUpStep>? _warmUpSteps;
  WarmUpSessionState? _warmUpState;
  int _warmUpGetReadySeconds = 10;
  final ValueNotifier<bool> _warmUpVisible = ValueNotifier(false);
  bool _warmUpInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.now();
    _clockNotifier = ValueNotifier<DateTime>(_now);
    _sessionStartedAt = widget.recoveredDraft?.startedAt ?? _now;
    _restoreDraftIfNeeded();
    _notesCtl.addListener(_scheduleDraftPersist);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshClock(syncRestTimers: true, vibrateOnCompletion: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveTimer?.cancel();
    _ticker.cancel();
    _clockNotifier.dispose();
    _notesCtl.dispose();
    _notesFocusNode.dispose();
    _warmUpVisible.dispose();
    unawaited(
      NotificationService.cancelRest(notificationId: 700000 + widget.plan.id),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshClock(syncRestTimers: true, vibrateOnCompletion: false);
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistDraftNow());
    }
  }

  void _restoreDraftIfNeeded() {
    final draft = widget.recoveredDraft;
    if (draft == null) {
      return;
    }

    _notesCtl.text = draft.notes;
    _energy = draft.energy;
    _mood = draft.mood;
    final restoredIds = <int>{};
    _sessionDetails = draft.details
        .where((detail) => restoredIds.add(detail.exerciseId))
        .toList();
    _exerciseMap = {
      for (final exercise in draft.exercises) exercise.id: exercise,
    };
    _setCountsByExercise.addAll(draft.setCountsByExercise);
    _weightUnitsByExercise.addAll(draft.weightUnitsByExercise);
    _setupEditableExerciseIds.addAll(draft.setupEditableExerciseIds);
    _warmUpState = draft.warmUpState;
    if (draft.warmUpState != null) {
      _warmUpGetReadySeconds = draft.warmUpState!.getReadySeconds;
    }
    for (final detail in _sessionDetails!) {
      _setCountsByExercise.putIfAbsent(detail.exerciseId, () => detail.sets);
      _weightUnitsByExercise.putIfAbsent(
        detail.exerciseId,
        () => WeightDisplayUnit.kg,
      );
      _cardKeys[detail.exerciseId] =
          GlobalKey<ActiveSessionExerciseCardState>();
    }
    for (final log in draft.logs) {
      _sessionLogs[_logKey(log.exerciseId, log.setNumber)] = log;
    }
    _restEndsAtByExercise.addAll(
      Map<int, DateTime>.fromEntries(
        draft.restEndsAtByExercise.entries.where(
          (entry) => entry.value.isAfter(_now),
        ),
      ),
    );
    _expandedExerciseId = draft.expandedExerciseId ??
        (_sessionDetails!.isNotEmpty
            ? _sessionDetails!.first.exerciseId
            : null);
    _lastFocusedExerciseId = _expandedExerciseId;
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
    _now = now;
    _clockNotifier.value = now;
    if (syncRestTimers) {
      _syncRestTimers(now, vibrateOnCompletion: vibrateOnCompletion);
      _syncWarmUpTimer(now, vibrateOnCompletion: vibrateOnCompletion);
    }
  }

  bool get _isWarmUpActive {
    final state = _warmUpState;
    return _warmUpSteps?.isNotEmpty == true &&
        state != null &&
        state.status != WarmUpSessionStatus.completed;
  }

  bool get _showWarmUpPreview =>
      _warmUpSteps?.isNotEmpty == true && _warmUpState == null;

  void _initializeWarmUp(List<WarmUpStep> steps) {
    if (_warmUpInitialized) {
      return;
    }
    _warmUpInitialized = true;
    _warmUpSteps = List<WarmUpStep>.from(steps);
    if (_warmUpSteps!.isEmpty) {
      return;
    }
    if (_warmUpState != null) {
      _warmUpVisible.value =
          _warmUpState!.status != WarmUpSessionStatus.completed;
      if (_warmUpState!.status == WarmUpSessionStatus.running) {
        if (_warmUpState!.phaseEndsAt != null &&
            _warmUpState!.phaseEndsAt!.isAfter(_now)) {
          _scheduleWarmUpNotification(_warmUpState!);
        } else {
          _syncWarmUpTimer(_now, vibrateOnCompletion: false);
        }
      }
      return;
    }
    _warmUpVisible.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _startWarmUp() {
    final steps = _warmUpSteps;
    if (steps == null || steps.isEmpty || _warmUpState != null) {
      return;
    }
    final first = steps.first;
    final state = WarmUpSessionState(
      status: WarmUpSessionStatus.running,
      stepIndex: 0,
      setNumber: 1,
      phase: WarmUpPhase.getReady,
      side: first.perSide ? WarmUpSide.left : WarmUpSide.none,
      phaseEndsAt: _now.add(Duration(seconds: _warmUpGetReadySeconds)),
      getReadySeconds: _warmUpGetReadySeconds,
    );
    setState(() => _warmUpState = state);
    _warmUpVisible.value = true;
    _scheduleWarmUpNotification(state);
    _scheduleDraftPersist();
  }

  void _setWarmUpGetReadySeconds(int seconds) {
    setState(() => _warmUpGetReadySeconds = seconds);
  }

  void _skipWarmUpPreview() {
    final steps = _warmUpSteps;
    if (steps == null || steps.isEmpty) {
      return;
    }
    final first = steps.first;
    setState(() {
      _warmUpState = WarmUpSessionState(
        status: WarmUpSessionStatus.completed,
        stepIndex: 0,
        setNumber: 1,
        phase: WarmUpPhase.work,
        side: first.perSide ? WarmUpSide.left : WarmUpSide.none,
        getReadySeconds: _warmUpGetReadySeconds,
      );
    });
    _warmUpVisible.value = false;
    unawaited(
      NotificationService.cancelRest(notificationId: 700000 + widget.plan.id),
    );
    _scheduleDraftPersist();
  }

  Future<void> _scheduleWarmUpNotification(WarmUpSessionState state) async {
    if (state.status != WarmUpSessionStatus.running ||
        state.phaseEndsAt == null) {
      return;
    }
    final remainingSeconds =
        state.phaseEndsAt!.difference(_now).inSeconds.clamp(1, 86400).toInt();
    final steps = _warmUpSteps;
    final step = steps == null || state.stepIndex >= steps.length
        ? null
        : steps[state.stepIndex];
    if (step == null) {
      return;
    }
    final cue = _warmUpUpcomingCue(state, step);
    await NotificationService.scheduleWarmUpPhaseDone(
      remainingSeconds,
      title: cue.title,
      body: cue.body,
      notificationId: 700000 + widget.plan.id,
      scheduledAt: _now,
    );
  }

  ({String title, String body}) _warmUpUpcomingCue(
    WarmUpSessionState state,
    WarmUpStep step,
  ) {
    if (state.phase == WarmUpPhase.getReady) {
      return (
        title: 'Warm-up: ${step.name}',
        body: 'Start set 1 now.',
      );
    }
    if (state.phase == WarmUpPhase.work &&
        step.perSide &&
        state.side == WarmUpSide.left) {
      return (
        title: 'Warm-up: right side',
        body: '${step.name}, set ${state.setNumber}.',
      );
    }
    if (state.phase == WarmUpPhase.work &&
        step.restSeconds > 0 &&
        state.setNumber < step.sets) {
      return (
        title: 'Warm-up: rest',
        body: '${step.restSeconds} seconds before set ${state.setNumber + 1}.',
      );
    }
    if (state.phase == WarmUpPhase.rest || state.setNumber < step.sets) {
      return (
        title: 'Warm-up: ${step.name}',
        body: 'Start set ${state.setNumber + 1} now.',
      );
    }
    var nextIndex = state.stepIndex + 1;
    while (state.skippedStepIndexes.contains(nextIndex)) {
      nextIndex++;
    }
    final nextStep = nextIndex < (_warmUpSteps?.length ?? 0)
        ? _warmUpSteps![nextIndex]
        : null;
    return nextStep == null
        ? (title: 'Warm-up complete', body: 'Start your strength session.')
        : (title: 'Warm-up: ${nextStep.name}', body: 'Start set 1 now.');
  }

  void _syncWarmUpTimer(
    DateTime now, {
    required bool vibrateOnCompletion,
  }) {
    final state = _warmUpState;
    if (state == null || state.status != WarmUpSessionStatus.running) {
      return;
    }
    final endsAt = state.phaseEndsAt;
    if (endsAt == null || now.isBefore(endsAt)) return;
    _advanceWarmUp(now, vibrateOnCompletion: vibrateOnCompletion);
  }

  void _advanceWarmUp(DateTime now, {required bool vibrateOnCompletion}) {
    final state = _warmUpState;
    final steps = _warmUpSteps;
    if (state == null || steps == null || state.stepIndex >= steps.length) {
      return;
    }
    final step = steps[state.stepIndex];
    WarmUpSessionState next;
    if (state.phase == WarmUpPhase.getReady) {
      next = state.copyWith(
        phase: WarmUpPhase.work,
        side: step.perSide ? WarmUpSide.left : WarmUpSide.none,
        phaseEndsAt: now.add(Duration(seconds: step.workSeconds)),
        pausedRemainingSeconds: 0,
      );
    } else if (state.phase == WarmUpPhase.work &&
        step.perSide &&
        state.side == WarmUpSide.left) {
      next = state.copyWith(
        side: WarmUpSide.right,
        phaseEndsAt: now.add(Duration(seconds: step.workSeconds)),
        pausedRemainingSeconds: 0,
      );
    } else if (state.phase == WarmUpPhase.work &&
        step.restSeconds > 0 &&
        state.setNumber < step.sets) {
      next = state.copyWith(
        phase: WarmUpPhase.rest,
        side: WarmUpSide.none,
        phaseEndsAt: now.add(Duration(seconds: step.restSeconds)),
        pausedRemainingSeconds: 0,
      );
    } else if (state.phase == WarmUpPhase.rest) {
      next = _nextWarmUpSet(state, step, now);
    } else if (state.setNumber < step.sets) {
      next = _nextWarmUpSet(state, step, now);
    } else {
      next = _nextWarmUpStep(state, now);
    }
    setState(() => _warmUpState = next);
    _warmUpVisible.value = next.status != WarmUpSessionStatus.completed;
    unawaited(NotificationService.cancelRest(
        notificationId: 700000 + widget.plan.id));
    if (next.status == WarmUpSessionStatus.running) {
      _scheduleWarmUpNotification(next);
    }
    _scheduleDraftPersist();
    if (vibrateOnCompletion) {
      unawaited(SystemSound.play(SystemSoundType.alert));
      unawaited(() async {
        if (await Vibration.hasVibrator()) {
          await Vibration.vibrate(
            preset: VibrationPreset.countdownTimerAlert,
          );
        }
      }());
      final cue = next.status == WarmUpSessionStatus.completed
          ? 'Warm-up complete. Start strength work.'
          : _warmUpCurrentCue(next);
      _showSnackBar(cue);
    }
  }

  String _warmUpCurrentCue(WarmUpSessionState state) {
    final steps = _warmUpSteps;
    if (steps == null || state.stepIndex >= steps.length) {
      return 'Warm-up complete.';
    }
    final step = steps[state.stepIndex];
    if (state.phase == WarmUpPhase.rest) {
      return 'Rest. ${step.name} set ${state.setNumber + 1} is next.';
    }
    final side = switch (state.side) {
      WarmUpSide.left => ' left side',
      WarmUpSide.right => ' right side',
      WarmUpSide.none => '',
    };
    return 'Work: ${step.name}$side, set ${state.setNumber}.';
  }

  WarmUpSessionState _nextWarmUpSet(
    WarmUpSessionState state,
    WarmUpStep step,
    DateTime now,
  ) =>
      state.copyWith(
        status: WarmUpSessionStatus.running,
        setNumber: state.setNumber + 1,
        phase: WarmUpPhase.work,
        side: step.perSide ? WarmUpSide.left : WarmUpSide.none,
        phaseEndsAt: now.add(Duration(seconds: step.workSeconds)),
        pausedRemainingSeconds: 0,
      );

  WarmUpSessionState _nextWarmUpStep(WarmUpSessionState state, DateTime now) {
    final steps = _warmUpSteps!;
    var nextIndex = state.stepIndex + 1;
    while (state.skippedStepIndexes.contains(nextIndex)) {
      nextIndex++;
    }
    if (nextIndex >= steps.length) {
      return state.copyWith(
        status: WarmUpSessionStatus.completed,
        clearPhaseEndsAt: true,
        pausedRemainingSeconds: 0,
      );
    }
    final nextStep = steps[nextIndex];
    return state.copyWith(
      status: WarmUpSessionStatus.running,
      stepIndex: nextIndex,
      setNumber: 1,
      phase: WarmUpPhase.work,
      side: nextStep.perSide ? WarmUpSide.left : WarmUpSide.none,
      phaseEndsAt: now.add(Duration(seconds: nextStep.workSeconds)),
      pausedRemainingSeconds: 0,
    );
  }

  void _toggleWarmUpPause() {
    final state = _warmUpState;
    if (state == null) return;
    if (state.status == WarmUpSessionStatus.paused) {
      final resumed = state.copyWith(
        status: WarmUpSessionStatus.running,
        phaseEndsAt: _now.add(Duration(seconds: state.pausedRemainingSeconds)),
        pausedRemainingSeconds: 0,
      );
      setState(() => _warmUpState = resumed);
      _warmUpVisible.value = true;
      _scheduleWarmUpNotification(resumed);
    } else {
      final remaining = (state.phaseEndsAt?.difference(_now).inSeconds ?? 0)
          .clamp(0, 86400)
          .toInt();
      setState(() => _warmUpState = state.copyWith(
            status: WarmUpSessionStatus.paused,
            clearPhaseEndsAt: true,
            pausedRemainingSeconds: remaining,
          ));
      unawaited(NotificationService.cancelRest(
          notificationId: 700000 + widget.plan.id));
    }
    _scheduleDraftPersist();
  }

  void _skipWarmUpStep() {
    final state = _warmUpState;
    if (state == null) return;
    final skipped = {...state.skippedStepIndexes, state.stepIndex};
    final next =
        _nextWarmUpStep(state.copyWith(skippedStepIndexes: skipped), _now);
    setState(() => _warmUpState = next);
    _warmUpVisible.value = next.status != WarmUpSessionStatus.completed;
    unawaited(NotificationService.cancelRest(
        notificationId: 700000 + widget.plan.id));
    if (next.status == WarmUpSessionStatus.running) {
      _scheduleWarmUpNotification(next);
    }
    _scheduleDraftPersist();
  }

  void _finishWarmUp() {
    final state = _warmUpState;
    if (state == null) {
      _skipWarmUpPreview();
      return;
    }
    setState(() => _warmUpState = state.copyWith(
          status: WarmUpSessionStatus.completed,
          clearPhaseEndsAt: true,
          pausedRemainingSeconds: 0,
        ));
    _warmUpVisible.value = false;
    unawaited(NotificationService.cancelRest(
        notificationId: 700000 + widget.plan.id));
    _scheduleDraftPersist();
  }

  void _syncRestTimers(
    DateTime now, {
    required bool vibrateOnCompletion,
  }) {
    var timerExpired = false;
    for (final entry in _restEndsAtByExercise.entries.toList()) {
      if (!entry.value.isAfter(now)) {
        _restEndsAtByExercise.remove(entry.key);
        timerExpired = true;
      }
    }
    if (timerExpired && mounted) {
      setState(() {});
    }
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

  int? get _expandedExerciseIndex {
    final details = _sessionDetails;
    final expandedExerciseId = _expandedExerciseId ?? _lastFocusedExerciseId;
    if (details == null || expandedExerciseId == null) {
      return null;
    }

    final index = details.indexWhere(
      (detail) => detail.exerciseId == expandedExerciseId,
    );
    return index == -1 ? null : index;
  }

  _ActiveRestTimerSummary? _activeRestTimerSummary(DateTime now) {
    final details = _sessionDetails;
    if (details == null || details.isEmpty || _restEndsAtByExercise.isEmpty) {
      return null;
    }

    _ActiveRestTimerSummary? nextTimer;
    for (final detail in details) {
      final endsAt = _restEndsAtByExercise[detail.exerciseId];
      if (endsAt == null || !endsAt.isAfter(now)) {
        continue;
      }

      final remaining = endsAt.difference(now);
      final summary = _ActiveRestTimerSummary(
        exerciseName: detail.name,
        remaining: remaining,
      );
      if (nextTimer == null || summary.remaining < nextTimer.remaining) {
        nextTimer = summary;
      }
    }
    return nextTimer;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  void _scheduleDraftPersist() {
    if (_endingSession || !mounted) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistDraftNow());
    });
  }

  Future<void> _persistDraftNow() async {
    if (_endingSession || !mounted) return;
    final details = _sessionDetails;
    final exerciseMap = _exerciseMap;
    if (details == null || details.isEmpty || exerciseMap == null) {
      return;
    }

    final activeExerciseIds =
        details.map((detail) => detail.exerciseId).toSet();
    final draft = ActiveWorkoutSessionDraft(
      plan: widget.plan,
      startedAt: _sessionStartedAt,
      updatedAt: widget.now(),
      notes: _notesCtl.text,
      energy: _energy,
      mood: _mood,
      expandedExerciseId: _expandedExerciseId,
      details: List<PlanExerciseDetail>.from(details),
      exercises: [
        for (final exercise in exerciseMap.values)
          if (activeExerciseIds.contains(exercise.id)) exercise,
      ],
      setCountsByExercise: {
        for (final detail in details)
          detail.exerciseId:
              _setCountsByExercise[detail.exerciseId] ?? detail.sets,
      },
      weightUnitsByExercise: {
        for (final detail in details)
          detail.exerciseId:
              _weightUnitsByExercise[detail.exerciseId] ?? WeightDisplayUnit.kg,
      },
      setupEditableExerciseIds:
          _setupEditableExerciseIds.intersection(activeExerciseIds),
      warmUpState: _warmUpState,
      logs: _sessionLogs.values.toList(growable: false),
      restEndsAtByExercise: Map<int, DateTime>.from(_restEndsAtByExercise),
    );

    final repo = ref.read(workoutPlanRepositoryProvider);
    _draftWrite = _draftWrite
        .then((_) => SaveActiveSessionDraftUseCase(repo)(draft))
        .catchError((Object error) {
      _showSnackBar(
          'Could not save recovery data. Keep this session open and retry.');
    });
    await _draftWrite;
  }

  void _ensureExerciseVisible(int exerciseId, {bool alignTop = false}) {
    final exerciseContext = _cardKeys[exerciseId]?.currentContext;
    if (exerciseContext != null && exerciseContext.mounted) {
      unawaited(
        Scrollable.ensureVisible(
          exerciseContext,
          duration: KineticMotion.duration(context, 260),
          curve: Curves.easeOutCubic,
          alignment: alignTop ? 0.0 : 0.06,
        ),
      );
    }
  }

  void _openExerciseAtIndex(int index) {
    final details = _sessionDetails;
    if (details == null || index < 0 || index >= details.length) {
      return;
    }

    final exerciseId = details[index].exerciseId;
    if (_expandedExerciseId == exerciseId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _ensureExerciseVisible(exerciseId);
      });
      return;
    }

    setState(() {
      _expandedExerciseId = exerciseId;
      _lastFocusedExerciseId = exerciseId;
      _scheduleDraftPersist();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _ensureExerciseVisible(exerciseId);
    });
  }

  void _moveExpandedExercise(int offset) {
    final index = _expandedExerciseIndex;
    final details = _sessionDetails;
    if (index == null || details == null) {
      return;
    }

    final nextIndex = index + offset;
    if (nextIndex < 0 || nextIndex >= details.length) {
      return;
    }

    _openExerciseAtIndex(nextIndex);
  }

  Future<void> _clearPersistedDraft() async {
    _endingSession = true;
    _draftSaveTimer?.cancel();
    await _draftWrite;
    final repo = ref.read(workoutPlanRepositoryProvider);
    await ClearActiveSessionDraftUseCase(repo)();
  }

  void _initializeSessionData(
    List<PlanExerciseDetail> details,
    List<Exercise> exercises,
  ) {
    final allExercises = {
      for (final exercise in exercises) exercise.id: exercise
    };
    _exerciseMap ??= allExercises;
    _exerciseMap!.addEntries(
      allExercises.entries
          .where((entry) => !_exerciseMap!.containsKey(entry.key)),
    );

    if (_sessionDetails != null) {
      for (final detail in _sessionDetails!) {
        _setCountsByExercise.putIfAbsent(detail.exerciseId, () => detail.sets);
        _weightUnitsByExercise.putIfAbsent(
          detail.exerciseId,
          () => WeightDisplayUnit.kg,
        );
        _cardKeys.putIfAbsent(
          detail.exerciseId,
          () => GlobalKey<ActiveSessionExerciseCardState>(),
        );
      }
      return;
    }

    _sessionDetails = List<PlanExerciseDetail>.from(details);
    for (final detail in _sessionDetails!) {
      _setCountsByExercise[detail.exerciseId] = detail.sets;
      _weightUnitsByExercise[detail.exerciseId] = WeightDisplayUnit.kg;
      _cardKeys[detail.exerciseId] =
          GlobalKey<ActiveSessionExerciseCardState>();
    }
    if (_sessionDetails!.isNotEmpty) {
      _expandedExerciseId = _sessionDetails!.first.exerciseId;
      _lastFocusedExerciseId = _expandedExerciseId;
    }
    _scheduleDraftPersist();
  }

  String _logKey(int exerciseId, int setNumber) => '$exerciseId-$setNumber';

  void _saveDraftLog(WorkoutLogEntry entry) {
    _sessionLogs[_logKey(entry.exerciseId, entry.setNumber)] = entry;
    _scheduleDraftPersist();
  }

  void _completeLog(WorkoutLogEntry entry) {
    setState(() {
      _sessionLogs[_logKey(entry.exerciseId, entry.setNumber)] =
          entry.copyWith(completed: true);
    });
    _scheduleDraftPersist();
  }

  void _removeLog(WorkoutLogEntry entry) {
    setState(() {
      _sessionLogs.remove(_logKey(entry.exerciseId, entry.setNumber));
    });
    _scheduleDraftPersist();
  }

  void _updateRestEndsAt(int exerciseId, DateTime? restEndsAt) {
    setState(() {
      if (restEndsAt == null || !restEndsAt.isAfter(widget.now())) {
        _restEndsAtByExercise.remove(exerciseId);
      } else {
        _restEndsAtByExercise[exerciseId] = restEndsAt;
      }
    });
    _scheduleDraftPersist();
  }

  PlanExerciseDetail _genericSessionDetail(Exercise exercise) {
    return PlanExerciseDetail(
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
  }

  Future<ActiveSessionExerciseSetupPreset?> _loadSetupPreset(
    int exerciseId,
  ) {
    final repo = ref.read(workoutPlanRepositoryProvider);
    return GetActiveSessionExerciseSetupPresetUseCase(repo)(exerciseId);
  }

  void _removeLogsAboveSetCount(int exerciseId, int setCount) {
    _sessionLogs.removeWhere(
      (_, log) => log.exerciseId == exerciseId && log.setNumber > setCount,
    );
  }

  Future<void> _editSessionExerciseSetup(int exerciseId) async {
    final details = _sessionDetails;
    if (details == null) {
      return;
    }

    final index =
        details.indexWhere((detail) => detail.exerciseId == exerciseId);
    if (index == -1) {
      return;
    }

    final currentDetail = details[index].copyWith(
      sets: _setCountsByExercise[exerciseId] ?? details[index].sets,
    );
    final updatedDetail = await showActiveSessionExerciseSetupSheet(
      context,
      detail: currentDetail,
    );
    if (!mounted || updatedDetail == null) {
      return;
    }

    final removedLogs = _sessionLogs.values
        .where((log) =>
            log.exerciseId == exerciseId &&
            log.completed &&
            log.setNumber > updatedDetail.sets)
        .length;
    if (removedLogs > 0) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Remove logged sets?'),
                content: Text(
                    'Reducing the set count removes $removedLogs completed sets from this workout.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep sets')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove sets'))
                ],
              ));
      if (!mounted || confirmed != true) return;
    }

    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      await SaveActiveSessionExerciseSetupPresetUseCase(repo)(
        ActiveSessionExerciseSetupPreset.fromDetail(updatedDetail),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Unable to save exercise setup: $error');
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      details[index] = updatedDetail;
      _setCountsByExercise[exerciseId] = updatedDetail.sets;
      _setupEditableExerciseIds.remove(exerciseId);
      _removeLogsAboveSetCount(exerciseId, updatedDetail.sets);
    });
    _scheduleDraftPersist();
    _showSnackBar('Exercise setup saved.');
  }

  Future<void> swapExercise(int index) async {
    if (_sessionDetails == null ||
        _exerciseMap == null ||
        _savingSession ||
        index < 0 ||
        index >= _sessionDetails!.length) {
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
    if (!mounted) return;
    if (picked.id != detail.exerciseId &&
        _sessionDetails!.any((item) => item.exerciseId == picked.id)) {
      _showSnackBar(
          '${picked.name} is already in this workout. Choose a different exercise.');
      return;
    }
    final hasCompletedSets = _sessionLogs.values
        .any((log) => log.exerciseId == detail.exerciseId && log.completed);
    if (picked.id == detail.exerciseId || hasCompletedSets) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(picked.id == detail.exerciseId
                    ? 'Reset this exercise?'
                    : 'Replace this exercise?'),
                content: Text(picked.id == detail.exerciseId
                    ? 'To correct weight or reps, tap EDIT on the completed set. Resetting removes all sets logged for this exercise in this workout.'
                    : 'Replacing ${detail.name} removes its sets from this workout. Your previously saved history is kept.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep sets')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(picked.id == detail.exerciseId
                          ? 'Reset sets'
                          : 'Replace & discard sets')),
                ],
              ));
      if (!mounted || confirmed != true) return;
    }
    final hasSavedSetup = await _loadSetupPreset(picked.id) != null;
    if (!mounted) {
      return;
    }

    final existingKeys = _sessionLogs.keys
        .where((key) => key.startsWith('${detail.exerciseId}-'))
        .toList(growable: false);
    for (final key in existingKeys) {
      _sessionLogs.remove(key);
    }
    _restEndsAtByExercise.remove(detail.exerciseId);
    _weightUnitsByExercise.remove(detail.exerciseId);

    setState(() {
      _cardKeys.remove(detail.exerciseId);
      final existingSetCount =
          _setCountsByExercise.remove(detail.exerciseId) ?? detail.sets;
      final newDetail = detail.copyWith(
        exerciseId: picked.id,
        name: picked.name,
        description: picked.description,
        sets: existingSetCount,
      );
      _sessionDetails![index] = newDetail;
      _exerciseMap![picked.id] = picked;
      _setCountsByExercise[newDetail.exerciseId] = existingSetCount;
      _weightUnitsByExercise[newDetail.exerciseId] = WeightDisplayUnit.kg;
      _cardKeys[newDetail.exerciseId] =
          GlobalKey<ActiveSessionExerciseCardState>();
      if (_expandedExerciseId == detail.exerciseId) {
        _expandedExerciseId = newDetail.exerciseId;
      }
      if (_lastFocusedExerciseId == detail.exerciseId) {
        _lastFocusedExerciseId = newDetail.exerciseId;
      }
      _setupEditableExerciseIds.remove(detail.exerciseId);
      if (hasSavedSetup) {
        _setupEditableExerciseIds.remove(newDetail.exerciseId);
      } else {
        _setupEditableExerciseIds.add(newDetail.exerciseId);
      }
    });
    _scheduleDraftPersist();
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

    final existingIndex = _sessionDetails?.indexWhere(
          (item) => item.exerciseId == exercise.id,
        ) ??
        -1;
    if (existingIndex != -1) {
      _showSnackBar('${exercise.name} is already in this session.');
      _openExerciseAtIndex(existingIndex);
      return;
    }

    final preset = await _loadSetupPreset(exercise.id);
    if (!mounted) {
      return;
    }
    final genericDetail = _genericSessionDetail(exercise);
    final newDetail = preset?.applyTo(genericDetail) ?? genericDetail;
    final shouldOfferSetup = preset == null;

    setState(() {
      _sessionDetails ??= [];
      _sessionDetails!.add(newDetail);
      _exerciseMap![exercise.id] = exercise;
      _setCountsByExercise[newDetail.exerciseId] = newDetail.sets;
      _weightUnitsByExercise[newDetail.exerciseId] = WeightDisplayUnit.kg;
      _cardKeys[newDetail.exerciseId] =
          GlobalKey<ActiveSessionExerciseCardState>();
      _expandedExerciseId = newDetail.exerciseId;
      _lastFocusedExerciseId = newDetail.exerciseId;
      if (shouldOfferSetup) {
        _setupEditableExerciseIds.add(newDetail.exerciseId);
      } else {
        _setupEditableExerciseIds.remove(newDetail.exerciseId);
      }
    });
    _scheduleDraftPersist();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureExerciseVisible(newDetail.exerciseId, alignTop: true);
    });
  }

  Future<void> _cancelAllSessionNotifications() async {
    await NotificationService.cancelRest(
      notificationId: 700000 + widget.plan.id,
    );
    final count = _sessionDetails?.length ?? 0;
    for (var i = 1; i <= count; i++) {
      await NotificationService.cancelRest(
        notificationId: widget.plan.id * 1000 + i,
      );
    }
  }

  Future<void> _handleExitAttempt() async {
    if (_savingSession || _endingSession) return;
    final exit = await showConfirmExitSheet(context);
    if (!mounted || !exit) {
      return;
    }
    await _cancelAllSessionNotifications();
    await _clearPersistedDraft();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openFinishSummary() async {
    if (_savingSession || _endingSession) return;
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
        await _cancelAllSessionNotifications();
        await _clearPersistedDraft();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
        return;
      case FinishSessionSummaryAction.resume:
        setState(() {
          _energy = result.energy;
          _mood = result.mood;
          _notesCtl.text = result.notes;
        });
        _scheduleDraftPersist();
        return;
      case FinishSessionSummaryAction.save:
        final repo = ref.read(workoutPlanRepositoryProvider);
        setState(() {
          _savingSession = true;
          _endingSession = true;
        });
        _draftSaveTimer?.cancel();
        try {
          await _draftWrite;
          await repo.finishWorkout(
              _completedLogs,
              WorkoutSession(
                planId: widget.plan.id,
                date: _sessionStartedAt,
                sessionId:
                    'workout:${widget.plan.id}:${_sessionStartedAt.toIso8601String()}',
                fatigueLevel: result.energy!,
                durationMinutes: duration.inMinutes,
                mood: result.mood!,
                notes: result.notes,
              ));
          // Saving is authoritative. Notification cleanup must not report a
          // failed save after the transaction has already committed.
          try {
            await _cancelAllSessionNotifications();
          } catch (_) {}
          if (!mounted) return;
          ref.invalidate(workoutLogsProvider);
          ref.invalidate(workoutSessionsProvider);
          ref.invalidate(performanceDashboardProvider);
          ref.invalidate(exerciseProgressDetailProvider);
          ref.invalidate(activeExerciseProgressProvider);
          _showSnackBar('Session saved.');
          Navigator.of(context).pop();
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _savingSession = false;
            _endingSession = false;
          });
          _energy = result.energy;
          _mood = result.mood;
          _notesCtl.text = result.notes;
          _scheduleDraftPersist();
          _showSnackBar(
              'Session could not be saved. Your sets are still here; try again.');
        }
    }
  }

  void _logExpandedSet(int exerciseId) {
    final result = _cardKeys[exerciseId]?.currentState?.logCurrentSet();
    switch (result) {
      case LogCurrentSetResult.registered:
        unawaited(HapticFeedback.lightImpact());
        break;
      case LogCurrentSetResult.invalidReps:
        _showSnackBar('Enter valid reps (>0) for this set.');
        break;
      case LogCurrentSetResult.noPendingSet:
        _showSnackBar(
            'All visible sets are complete. Add a new set to keep going.');
        break;
      case null:
        break;
    }
  }

  Widget _buildExerciseFocusHeader(PlanExerciseDetail detail) {
    final totalSets = _setCountsByExercise[detail.exerciseId] ?? detail.sets;
    int? currentSet;
    for (var number = 1; number <= totalSets; number++) {
      if (!(_sessionLogs[_logKey(detail.exerciseId, number)]?.completed ??
          false)) {
        currentSet = number;
        break;
      }
    }
    return Container(
      key: const Key('active-session-focus-header'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: KineticNoirPalette.background,
        border: Border(
            bottom: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActiveSessionExerciseTitle(
            key: Key('active-exercise-title-${detail.exerciseId}'),
            fullName: detail.name,
            expanded: true,
          ),
          const SizedBox(height: 8),
          ActiveSessionExecutionSummary(
            key: Key('active-exercise-summary-${detail.exerciseId}'),
            currentSet: currentSet,
            totalSets: totalSets,
            targetReps: detail.reps,
            rir: detail.rir,
            tempo: detail.tempo,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _completionRatio,
            minHeight: 2,
            color: KineticNoirPalette.primary,
            backgroundColor: KineticNoirPalette.surfaceBright,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetails = ref.watch(planExerciseDetailsProvider(widget.plan.id));
    final asyncExercises = ref.watch(allExercisesProvider);
    final asyncWarmUpSteps = ref.watch(warmUpStepsProvider(widget.plan.id));
    final showWarmUpChrome = _isWarmUpActive ||
        (_warmUpState == null &&
            (asyncWarmUpSteps.asData?.value.isNotEmpty ?? false));
    final resolvedSessionDetails =
        (_sessionDetails ?? asyncDetails.asData?.value) ??
            const <PlanExerciseDetail>[];
    final activeExpandedExerciseId = _expandedExerciseId ??
        _lastFocusedExerciseId ??
        (resolvedSessionDetails.isNotEmpty
            ? resolvedSessionDetails.first.exerciseId
            : null);
    const scrollBottomPadding = 24.0;
    final expandedExerciseIndex = activeExpandedExerciseId == null
        ? null
        : resolvedSessionDetails.indexWhere(
            (detail) => detail.exerciseId == activeExpandedExerciseId,
          );
    final resolvedExpandedExerciseIndex =
        expandedExerciseIndex == -1 ? null : expandedExerciseIndex;
    final canNavigateUp = resolvedExpandedExerciseIndex != null &&
        resolvedExpandedExerciseIndex > 0;
    final canNavigateDown = resolvedExpandedExerciseIndex != null &&
        resolvedExpandedExerciseIndex < resolvedSessionDetails.length - 1;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleExitAttempt();
      },
      child: Stack(children: [
        Scaffold(
          backgroundColor: KineticNoirPalette.background,
          appBar: AppBar(
            backgroundColor: KineticNoirPalette.background,
            surfaceTintColor: Colors.transparent,
            toolbarHeight:
                MediaQuery.orientationOf(context) == Orientation.landscape
                    ? 48
                    : 64,
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
                  showWarmUpChrome ? 'WARM-UP' : widget.plan.name,
                  key: const Key('active-session-title'),
                  style: KineticNoirTypography.headline(
                    size: 20,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                showWarmUpChrome
                    ? Text(
                        'Prepare for your session',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KineticNoirTypography.body(
                            size: 11,
                            color: KineticNoirPalette.onSurfaceVariant),
                      )
                    : ValueListenableBuilder<DateTime>(
                        valueListenable: _clockNotifier,
                        builder: (context, clockTime, _) {
                          final sessionDuration = _sessionDurationAt(clockTime);
                          return Text(
                            '${WorkoutSessionHelper.formatDuration(sessionDuration)} · $_completedSetCount/$_totalSetCount sets · ${_volumeKg.toStringAsFixed(0)} kg',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KineticNoirTypography.body(
                                size: 11,
                                color: KineticNoirPalette.onSurfaceVariant),
                          );
                        },
                      ),
              ],
            ),
            actions: [
              if (!showWarmUpChrome)
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
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: _warmUpVisible,
            builder: (context, warmUpVisible, _) =>
                showWarmUpChrome || warmUpVisible
                    ? const SizedBox.shrink()
                    : _ActiveSessionBottomBar(
                        clockNotifier: _clockNotifier,
                        getRestTimerSummary: _activeRestTimerSummary,
                        canNavigateUp: canNavigateUp,
                        canNavigateDown: canNavigateDown,
                        onNavigateUp: () => _moveExpandedExercise(-1),
                        onNavigateDown: () => _moveExpandedExercise(1),
                        onLogSet: activeExpandedExerciseId == null
                            ? null
                            : () => _logExpandedSet(activeExpandedExerciseId),
                      ),
          ),
          body: asyncExercises.when(
            loading: () => const Center(
              child:
                  CircularProgressIndicator(color: KineticNoirPalette.primary),
            ),
            error: (error, _) => _AsyncErrorState(error: '$error'),
            data: (exercises) => asyncDetails.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: KineticNoirPalette.primary),
              ),
              error: (error, _) => _AsyncErrorState(error: '$error'),
              data: (details) {
                return asyncWarmUpSteps.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: KineticNoirPalette.primary,
                    ),
                  ),
                  error: (error, _) => _AsyncErrorState(error: '$error'),
                  data: (warmUpSteps) {
                    _initializeSessionData(details, exercises);
                    _initializeWarmUp(warmUpSteps);

                    if (_showWarmUpPreview) {
                      return WarmUpPreview(
                        steps: _warmUpSteps!,
                        getReadySeconds: _warmUpGetReadySeconds,
                        onGetReadySecondsChanged: _setWarmUpGetReadySeconds,
                        onStart: _startWarmUp,
                        onSkip: _skipWarmUpPreview,
                      );
                    }

                    if (_isWarmUpActive) {
                      return ValueListenableBuilder<DateTime>(
                        valueListenable: _clockNotifier,
                        builder: (context, clockTime, _) => WarmUpFlow(
                          steps: _warmUpSteps!,
                          state: _warmUpState!,
                          now: clockTime,
                          onPauseResume: _toggleWarmUpPause,
                          onSkipStep: _skipWarmUpStep,
                          onFinish: _finishWarmUp,
                        ),
                      );
                    }

                    final sessionDetails =
                        _sessionDetails ?? const <PlanExerciseDetail>[];
                    if (sessionDetails.isEmpty) {
                      return const _EmptySessionState();
                    }

                    return Column(
                      children: [
                        if (activeExpandedExerciseId != null)
                          _buildExerciseFocusHeader(
                            sessionDetails
                                    .where((detail) =>
                                        detail.exerciseId ==
                                        activeExpandedExerciseId)
                                    .firstOrNull ??
                                sessionDetails.first,
                          ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              scrollBottomPadding,
                            ),
                            children: [
                              if (_showNotesComposer) ...[
                                ActiveSessionNotesCard(
                                  controller: _notesCtl,
                                  focusNode: _notesFocusNode,
                                  isVisible: _showNotesComposer,
                                  onToggleVisibility: () {
                                    setState(() => _showNotesComposer =
                                        !_showNotesComposer);
                                  },
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _AddSessionExerciseButton(
                                    onPressed: addExercise,
                                  ),
                                ),
                              ] else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ActiveSessionNotesCard(
                                      controller: _notesCtl,
                                      focusNode: _notesFocusNode,
                                      isVisible: _showNotesComposer,
                                      onToggleVisibility: () {
                                        setState(() => _showNotesComposer =
                                            !_showNotesComposer);
                                      },
                                    ),
                                    _AddSessionExerciseButton(
                                      onPressed: addExercise,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 14),
                              for (var index = 0;
                                  index < sessionDetails.length;
                                  index++)
                                ActiveSessionExerciseCard(
                                  key: _cardKeys.putIfAbsent(
                                    sessionDetails[index].exerciseId,
                                    () => GlobalKey<
                                        ActiveSessionExerciseCardState>(),
                                  ),
                                  detail: sessionDetails[index],
                                  exercise: _exerciseMap?[
                                      sessionDetails[index].exerciseId],
                                  planId: widget.plan.id,
                                  exerciseNumber: index + 1,
                                  now: widget.now,
                                  expanded: _expandedExerciseId ==
                                      sessionDetails[index].exerciseId,
                                  logsMap: _sessionLogs,
                                  weightUnit: _weightUnitsByExercise[
                                          sessionDetails[index].exerciseId] ??
                                      WeightDisplayUnit.kg,
                                  initialRestEndsAt: _restEndsAtByExercise[
                                      sessionDetails[index].exerciseId],
                                  onToggle: () {
                                    final exerciseId =
                                        sessionDetails[index].exerciseId;
                                    setState(() {
                                      _expandedExerciseId =
                                          _expandedExerciseId == exerciseId
                                              ? null
                                              : exerciseId;
                                      if (_expandedExerciseId != null) {
                                        _lastFocusedExerciseId = exerciseId;
                                      }
                                      _scheduleDraftPersist();
                                    });
                                    if (_expandedExerciseId != null) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!mounted) return;
                                        _ensureExerciseVisible(exerciseId);
                                      });
                                    }
                                  },
                                  onSetCountChanged: (count) => setState(() {
                                    _setCountsByExercise[sessionDetails[index]
                                        .exerciseId] = count;
                                    _scheduleDraftPersist();
                                  }),
                                  saveDraftLog: _saveDraftLog,
                                  completeLog: _completeLog,
                                  removeLog: _removeLog,
                                  onWeightUnitChanged: (unit) => setState(() {
                                    _weightUnitsByExercise[sessionDetails[index]
                                        .exerciseId] = unit;
                                    _scheduleDraftPersist();
                                  }),
                                  onRestEndsAtChanged: (restEndsAt) =>
                                      _updateRestEndsAt(
                                    sessionDetails[index].exerciseId,
                                    restEndsAt,
                                  ),
                                  onEditSetup: _setupEditableExerciseIds
                                          .contains(
                                    sessionDetails[index].exerciseId,
                                  )
                                      ? () => _editSessionExerciseSetup(
                                            sessionDetails[index].exerciseId,
                                          )
                                      : null,
                                  onSwap: () => swapExercise(index),
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
        ),
        if (_savingSession)
          const Positioned.fill(
              child: Stack(children: [
            ModalBarrier(dismissible: false, color: Colors.black54),
            Center(child: CircularProgressIndicator()),
          ])),
      ]),
    );
  }
}

class _ActiveRestTimerSummary {
  const _ActiveRestTimerSummary({
    required this.exerciseName,
    required this.remaining,
  });

  final String exerciseName;
  final Duration remaining;

  String get remainingLabel {
    final seconds = remaining.inSeconds;
    final minutesPart = seconds ~/ 60;
    final secondsPart = seconds % 60;
    return '${minutesPart.toString().padLeft(2, '0')}:'
        '${secondsPart.toString().padLeft(2, '0')}';
  }
}

class _FloatingRestTimerPill extends StatelessWidget {
  const _FloatingRestTimerPill({required this.summary});

  final _ActiveRestTimerSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('active-session-floating-rest-timer'),
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: KineticNoirPalette.primary.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: KineticNoirPalette.shadow.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: KineticNoirPalette.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 18,
              color: KineticNoirPalette.primary,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Rest ${summary.remainingLabel} - ${summary.exerciseName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionNavigationButton extends StatelessWidget {
  const _SessionNavigationButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: onPressed == null
            ? KineticNoirPalette.surfaceLow
            : KineticNoirPalette.primary.withValues(alpha: 0.12),
        foregroundColor: onPressed == null
            ? KineticNoirPalette.outlineVariant
            : KineticNoirPalette.primary,
        disabledBackgroundColor: KineticNoirPalette.surfaceLow,
        disabledForegroundColor: KineticNoirPalette.outlineVariant,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(10),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: Icon(icon, size: 22),
      tooltip: icon == Icons.keyboard_arrow_up_rounded
          ? 'Open previous exercise'
          : 'Open next exercise',
    );
  }
}

class _ActiveSessionBottomBar extends StatelessWidget {
  const _ActiveSessionBottomBar({
    required this.clockNotifier,
    required this.getRestTimerSummary,
    required this.canNavigateUp,
    required this.canNavigateDown,
    required this.onNavigateUp,
    required this.onNavigateDown,
    required this.onLogSet,
  });

  final ValueNotifier<DateTime> clockNotifier;
  final _ActiveRestTimerSummary? Function(DateTime now) getRestTimerSummary;
  final bool canNavigateUp;
  final bool canNavigateDown;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onLogSet;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: KineticNoirPalette.background,
            border: Border(
              top: BorderSide(
                color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<DateTime>(
                valueListenable: clockNotifier,
                builder: (context, now, _) {
                  final activeRestTimer = getRestTimerSummary(now);
                  if (activeRestTimer == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FloatingRestTimerPill(summary: activeRestTimer),
                  );
                },
              ),
              Row(
                children: [
                  _SessionNavigationButton(
                    buttonKey: const Key('active-session-nav-up'),
                    icon: Icons.keyboard_arrow_up_rounded,
                    onPressed: canNavigateUp ? onNavigateUp : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('active-session-register-set'),
                      onPressed: onLogSet,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('LOG SET'),
                      style: FilledButton.styleFrom(
                        backgroundColor: KineticNoirPalette.primary,
                        foregroundColor: KineticNoirPalette.onPrimary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SessionNavigationButton(
                    buttonKey: const Key('active-session-nav-down'),
                    icon: Icons.keyboard_arrow_down_rounded,
                    onPressed: canNavigateDown ? onNavigateDown : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSessionExerciseButton extends StatelessWidget {
  const _AddSessionExerciseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('active-session-add-exercise'),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: KineticNoirPalette.onSurfaceVariant,
        side: BorderSide(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.35),
          style: BorderStyle.solid,
        ),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
      label: Text(
        'ADD EXERCISE',
        style: KineticNoirTypography.body(
          size: 11,
          weight: FontWeight.w800,
          color: KineticNoirPalette.onSurfaceVariant,
          letterSpacing: 1.1,
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
