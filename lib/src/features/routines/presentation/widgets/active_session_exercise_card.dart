import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../utils/notification_service.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/weight_display_unit.dart';
import '../../domain/entities/workout_log_entry.dart';
import 'active_exercise_progress_panel.dart';

typedef SessionLogCallback = void Function(WorkoutLogEntry entry);

const double _kgToLbFactor = 2.2046226218;
const _autoAdvanceDelay = Duration(milliseconds: 260);

WeightDisplayUnit _oppositeUnit(WeightDisplayUnit unit) {
  return unit == WeightDisplayUnit.kg
      ? WeightDisplayUnit.lb
      : WeightDisplayUnit.kg;
}

double _kgToDisplayWeight(double weightKg, WeightDisplayUnit unit) {
  return unit == WeightDisplayUnit.kg ? weightKg : weightKg * _kgToLbFactor;
}

double _displayWeightToKg(double weight, WeightDisplayUnit unit) {
  return unit == WeightDisplayUnit.kg ? weight : weight / _kgToLbFactor;
}

String _formatWeight(double weight) {
  if (!weight.isFinite) {
    return '0';
  }

  final rounded = weight.roundToDouble();
  if ((weight - rounded).abs() < 0.05) {
    return rounded.toStringAsFixed(0);
  }
  return weight.toStringAsFixed(1);
}

enum LogCurrentSetResult {
  registered,
  noPendingSet,
  invalidReps,
}

enum _AutoAdvanceField {
  kg,
  reps,
  rir,
}

class ActiveSessionExerciseCard extends StatefulWidget {
  const ActiveSessionExerciseCard({
    required this.detail,
    required this.planId,
    required this.exerciseNumber,
    required this.now,
    required this.expanded,
    required this.logsMap,
    required this.weightUnit,
    required this.onToggle,
    required this.onSetCountChanged,
    required this.saveDraftLog,
    required this.completeLog,
    required this.removeLog,
    required this.onWeightUnitChanged,
    required this.onRestEndsAtChanged,
    this.exercise,
    this.initialRestEndsAt,
    this.onEditSetup,
    this.onSwap,
    super.key,
  });

  final PlanExerciseDetail detail;
  final Exercise? exercise;
  final int planId;
  final int exerciseNumber;
  final DateTime now;
  final bool expanded;
  final Map<String, WorkoutLogEntry> logsMap;
  final WeightDisplayUnit weightUnit;
  final VoidCallback onToggle;
  final ValueChanged<int> onSetCountChanged;
  final SessionLogCallback saveDraftLog;
  final SessionLogCallback completeLog;
  final SessionLogCallback removeLog;
  final ValueChanged<WeightDisplayUnit> onWeightUnitChanged;
  final ValueChanged<DateTime?> onRestEndsAtChanged;
  final VoidCallback? onEditSetup;
  final VoidCallback? onSwap;
  final DateTime? initialRestEndsAt;

  @override
  State<ActiveSessionExerciseCard> createState() =>
      ActiveSessionExerciseCardState();
}

class ActiveSessionExerciseCardState extends State<ActiveSessionExerciseCard>
    with AutomaticKeepAliveClientMixin {
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repControllers = [];
  final List<TextEditingController> _rirControllers = [];
  final List<FocusNode> _weightFocusNodes = [];
  final List<FocusNode> _repFocusNodes = [];
  final List<FocusNode> _rirFocusNodes = [];
  final List<int> _weightAutoAdvanceDigits = [];
  final List<int> _repAutoAdvanceDigits = [];
  final List<int> _rirAutoAdvanceDigits = [];
  final List<GlobalKey> _setRowKeys = [];

  int _visibleSets = 0;
  DateTime? _restEndsAt;
  bool _showAdjustActions = false;
  Timer? _autoAdvanceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _restEndsAt = widget.initialRestEndsAt;
    _resetControllers(widget.detail.sets);
  }

  @override
  void didUpdateWidget(covariant ActiveSessionExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.exerciseId != widget.detail.exerciseId) {
      _showAdjustActions = false;
      _clearRestTimer(cancelNotification: true, notifyParent: false);
      _restEndsAt = widget.initialRestEndsAt;
      _resetControllers(widget.detail.sets);
      return;
    }

    if (oldWidget.initialRestEndsAt != widget.initialRestEndsAt &&
        widget.initialRestEndsAt != _restEndsAt) {
      _restEndsAt = widget.initialRestEndsAt;
    }

    if (oldWidget.expanded && !widget.expanded) {
      _showAdjustActions = false;
    }

    if (oldWidget.weightUnit != widget.weightUnit) {
      _convertWeightControllers(oldWidget.weightUnit, widget.weightUnit);
    }

    final setupChanged = oldWidget.detail.sets != widget.detail.sets ||
        oldWidget.detail.reps != widget.detail.reps ||
        oldWidget.detail.weight != widget.detail.weight ||
        oldWidget.detail.rir != widget.detail.rir;
    if (setupChanged) {
      _resetControllers(widget.detail.sets);
      return;
    }

    if (widget.detail.sets > _visibleSets) {
      _resetControllers(widget.detail.sets);
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _disposeInputState();
    _clearRestTimer(cancelNotification: true, notifyParent: false);
    super.dispose();
  }

  LogCurrentSetResult logCurrentSet() {
    final nextSet = _nextPendingSetNumber;
    if (nextSet == null) {
      return LogCurrentSetResult.noPendingSet;
    }

    final reps = _parsePositiveInt(_repControllers[nextSet - 1].text);
    if (reps == null) {
      return LogCurrentSetResult.invalidReps;
    }

    widget.completeLog(
      WorkoutLogEntry(
        date: widget.now,
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: nextSet,
        reps: reps,
        weight: _weightControllerValueInKg(nextSet - 1),
        rir: _parseInt(_rirControllers[nextSet - 1].text, widget.detail.rir),
        completed: true,
      ),
    );
    _startRestTimer(widget.now);
    setState(() {});
    return LogCurrentSetResult.registered;
  }

  Future<void> ensurePrimarySetVisible() {
    if (_setRowKeys.isEmpty) {
      return Future.value();
    }

    final pendingSetNumber = _nextPendingSetNumber ?? 1;
    final pendingIndex = (pendingSetNumber - 1).clamp(0, _setRowKeys.length - 1);
    final targetContext = _setRowKeys[pendingIndex].currentContext;
    if (targetContext == null) {
      return Future.value();
    }

    return Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  }

  void _resetControllers(int targetSets) {
    _autoAdvanceTimer?.cancel();
    _disposeInputState();
    _visibleSets = targetSets;

    for (var index = 0; index < targetSets; index++) {
      final setNumber = index + 1;
      final existing = _logFor(setNumber);
      _setRowKeys.add(GlobalKey());
      _weightControllers.add(
        TextEditingController(
          text: _formatWeight(
            _kgToDisplayWeight(
              existing?.weight ?? widget.detail.weight,
              widget.weightUnit,
            ),
          ),
        ),
      );
      _repControllers.add(
        TextEditingController(
          text: '${existing?.reps ?? widget.detail.reps}',
        ),
      );
      _rirControllers.add(
        TextEditingController(
          text: '${existing?.rir ?? widget.detail.rir}',
        ),
      );
      _weightFocusNodes.add(FocusNode(debugLabel: 'weight-$setNumber'));
      _repFocusNodes.add(FocusNode(debugLabel: 'reps-$setNumber'));
      _rirFocusNodes.add(FocusNode(debugLabel: 'rir-$setNumber'));
    }

    _syncAutoAdvanceHints();
  }

  void _disposeInputState() {
    for (final controller in [
      ..._weightControllers,
      ..._repControllers,
      ..._rirControllers,
    ]) {
      controller.dispose();
    }
    for (final focusNode in [
      ..._weightFocusNodes,
      ..._repFocusNodes,
      ..._rirFocusNodes,
    ]) {
      focusNode.dispose();
    }
    _weightControllers.clear();
    _repControllers.clear();
    _rirControllers.clear();
    _weightFocusNodes.clear();
    _repFocusNodes.clear();
    _rirFocusNodes.clear();
    _weightAutoAdvanceDigits.clear();
    _repAutoAdvanceDigits.clear();
    _rirAutoAdvanceDigits.clear();
    _setRowKeys.clear();
  }

  void _syncAutoAdvanceHints() {
    _weightAutoAdvanceDigits
      ..clear()
      ..addAll(
        _weightControllers.map(
          (controller) => _expectedWeightDigits(controller.text),
        ),
      );
    _repAutoAdvanceDigits
      ..clear()
      ..addAll(
        _repControllers.map(
          (controller) => _expectedRepDigits(controller.text),
        ),
      );
    _rirAutoAdvanceDigits
      ..clear()
      ..addAll(
        _rirControllers.map(
          (controller) => _expectedRirDigits(controller.text),
        ),
      );
  }

  WorkoutLogEntry? _logFor(int setNumber) {
    return widget.logsMap['${widget.detail.exerciseId}-$setNumber'];
  }

  int? get _nextPendingSetNumber {
    for (var setNumber = 1; setNumber <= _visibleSets; setNumber++) {
      if (!(_logFor(setNumber)?.completed ?? false)) {
        return setNumber;
      }
    }
    return null;
  }

  bool _isSetCompleted(int setNumber) => _logFor(setNumber)?.completed ?? false;

  bool get _isExerciseComplete {
    for (var setNumber = 1; setNumber <= _visibleSets; setNumber++) {
      if (!_isSetCompleted(setNumber)) {
        return false;
      }
    }
    return true;
  }

  List<WorkoutLogEntry> get _completedExerciseLogs {
    final logs = widget.logsMap.values
        .where(
          (entry) =>
              entry.exerciseId == widget.detail.exerciseId && entry.completed,
        )
        .toList(growable: false)
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return logs;
  }

  double _weightControllerValueInKg(int index) {
    final fallbackDisplayWeight = _kgToDisplayWeight(
      widget.detail.weight,
      widget.weightUnit,
    );
    final displayWeight = _parseDouble(
      _weightControllers[index].text,
      fallbackDisplayWeight,
    );
    return _displayWeightToKg(displayWeight, widget.weightUnit);
  }

  void _convertWeightControllers(
    WeightDisplayUnit oldUnit,
    WeightDisplayUnit newUnit,
  ) {
    for (final controller in _weightControllers) {
      final displayWeight = double.tryParse(controller.text.trim());
      if (displayWeight == null) {
        continue;
      }

      final weightKg = _displayWeightToKg(displayWeight, oldUnit);
      controller.text = _formatWeight(_kgToDisplayWeight(weightKg, newUnit));
    }

    _syncAutoAdvanceHints();
  }

  void _switchWeightUnit() {
    final nextUnit = _oppositeUnit(widget.weightUnit);
    setState(() => _showAdjustActions = false);
    widget.onWeightUnitChanged(nextUnit);
  }

  void _saveDraft(int index) {
    final setNumber = index + 1;
    final current = _logFor(setNumber);
    widget.saveDraftLog(
      WorkoutLogEntry(
        date: widget.now,
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: setNumber,
        reps: _parseInt(_repControllers[index].text, widget.detail.reps),
        weight: _weightControllerValueInKg(index),
        rir: _parseInt(_rirControllers[index].text, widget.detail.rir),
        completed: current?.completed ?? false,
      ),
    );
  }

  void _handleFieldChanged(int index, _AutoAdvanceField field) {
    _saveDraft(index);
    _scheduleAutoAdvance(index, field);
  }

  void _scheduleAutoAdvance(int index, _AutoAdvanceField field) {
    _autoAdvanceTimer?.cancel();

    final controller = _controllerForField(index, field);
    final focusNode = _focusNodeForField(index, field);
    final value = controller.text.trim();
    if (!focusNode.hasFocus || !_shouldAutoAdvance(value, index, field)) {
      return;
    }

    _autoAdvanceTimer = Timer(_autoAdvanceDelay, () {
      if (!mounted || !focusNode.hasFocus) {
        return;
      }
      if (controller.text.trim() != value) {
        return;
      }
      _moveFocusToNextField(index, field);
    });
  }

  bool _shouldAutoAdvance(String value, int index, _AutoAdvanceField field) {
    if (value.isEmpty || value.contains('.')) {
      return false;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      return false;
    }

    return value.length >= _expectedDigitsForField(index, field);
  }

  int _expectedDigitsForField(int index, _AutoAdvanceField field) {
    return switch (field) {
      _AutoAdvanceField.kg => _weightAutoAdvanceDigits[index],
      _AutoAdvanceField.reps => _repAutoAdvanceDigits[index],
      _AutoAdvanceField.rir => _rirAutoAdvanceDigits[index],
    };
  }

  int _expectedWeightDigits(String prefilledText) {
    return _expectedIntegerDigits(prefilledText, fallback: 2);
  }

  int _expectedRepDigits(String prefilledText) {
    final inferred = _expectedIntegerDigits(prefilledText, fallback: 2);
    return inferred < 2 ? 2 : inferred;
  }

  int _expectedRirDigits(String prefilledText) {
    return _expectedIntegerDigits(prefilledText, fallback: 1) <= 1 ? 1 : 2;
  }

  int _expectedIntegerDigits(String text, {required int fallback}) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null || !parsed.isFinite) {
      return fallback;
    }

    final rounded = parsed.abs().round();
    return rounded == 0 ? 1 : rounded.toString().length;
  }

  TextEditingController _controllerForField(int index, _AutoAdvanceField field) {
    return switch (field) {
      _AutoAdvanceField.kg => _weightControllers[index],
      _AutoAdvanceField.reps => _repControllers[index],
      _AutoAdvanceField.rir => _rirControllers[index],
    };
  }

  FocusNode _focusNodeForField(int index, _AutoAdvanceField field) {
    return switch (field) {
      _AutoAdvanceField.kg => _weightFocusNodes[index],
      _AutoAdvanceField.reps => _repFocusNodes[index],
      _AutoAdvanceField.rir => _rirFocusNodes[index],
    };
  }

  void _moveFocusToNextField(int index, _AutoAdvanceField field) {
    switch (field) {
      case _AutoAdvanceField.kg:
        _focusAndSelect(_repFocusNodes[index], _repControllers[index]);
        return;
      case _AutoAdvanceField.reps:
        _focusAndSelect(_rirFocusNodes[index], _rirControllers[index]);
        return;
      case _AutoAdvanceField.rir:
        final nextIndex = index + 1;
        if (nextIndex >= _visibleSets || _isSetCompleted(nextIndex + 1)) {
          return;
        }
        _focusAndSelect(
          _weightFocusNodes[nextIndex],
          _weightControllers[nextIndex],
        );
        return;
    }
  }

  void _focusAndSelect(FocusNode focusNode, TextEditingController controller) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !focusNode.hasFocus) {
        return;
      }
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  void _addSet() {
    _autoAdvanceTimer?.cancel();
    final fallbackDisplayWeight = _kgToDisplayWeight(
      widget.detail.weight,
      widget.weightUnit,
    );
    final lastDisplayWeight = _weightControllers.isEmpty
        ? fallbackDisplayWeight
        : _parseDouble(_weightControllers.last.text, fallbackDisplayWeight);
    final lastWeight = _displayWeightToKg(lastDisplayWeight, widget.weightUnit);
    final lastReps = _repControllers.isEmpty
        ? widget.detail.reps
        : _parseInt(_repControllers.last.text, widget.detail.reps);
    final lastRir = _rirControllers.isEmpty
        ? widget.detail.rir
        : _parseInt(_rirControllers.last.text, widget.detail.rir);

    setState(() {
      _visibleSets++;
      _setRowKeys.add(GlobalKey());
      _weightControllers.add(
        TextEditingController(text: _formatWeight(lastDisplayWeight)),
      );
      _repControllers.add(TextEditingController(text: '$lastReps'));
      _rirControllers.add(TextEditingController(text: '$lastRir'));
      _weightFocusNodes.add(FocusNode(debugLabel: 'weight-$_visibleSets'));
      _repFocusNodes.add(FocusNode(debugLabel: 'reps-$_visibleSets'));
      _rirFocusNodes.add(FocusNode(debugLabel: 'rir-$_visibleSets'));
    });

    _syncAutoAdvanceHints();
    widget.onSetCountChanged(_visibleSets);
    widget.saveDraftLog(
      WorkoutLogEntry(
        date: widget.now,
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: _visibleSets,
        reps: lastReps,
        weight: lastWeight,
        rir: lastRir,
        completed: false,
      ),
    );
  }

  void _removeSet() {
    if (_visibleSets <= 1) {
      return;
    }

    final removedSet = _visibleSets;
    _autoAdvanceTimer?.cancel();
    setState(() {
      _visibleSets--;
      _setRowKeys.removeLast();
      _weightControllers.removeLast().dispose();
      _repControllers.removeLast().dispose();
      _rirControllers.removeLast().dispose();
      _weightFocusNodes.removeLast().dispose();
      _repFocusNodes.removeLast().dispose();
      _rirFocusNodes.removeLast().dispose();
      _weightAutoAdvanceDigits.removeLast();
      _repAutoAdvanceDigits.removeLast();
      _rirAutoAdvanceDigits.removeLast();
    });

    widget.onSetCountChanged(_visibleSets);
    widget.removeLog(
      WorkoutLogEntry(
        date: widget.now,
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: removedSet,
        reps: 0,
        weight: 0,
        rir: 0,
        completed: false,
      ),
    );
  }

  Future<void> syncRestTimer(
    DateTime now, {
    required bool vibrateOnCompletion,
  }) async {
    final restEndsAt = _restEndsAt;
    if (restEndsAt == null) {
      return;
    }

    if (now.isBefore(restEndsAt)) {
      return;
    }

    _clearRestTimer(cancelNotification: true);
    if (mounted) {
      setState(() {});
    }

    if (vibrateOnCompletion && await Vibration.hasVibrator()) {
      await Vibration.vibrate(preset: VibrationPreset.countdownTimerAlert);
    }
  }

  void _startRestTimer(DateTime now) {
    final notificationId = _notificationId;
    unawaited(
      NotificationService.scheduleRestDone(
        widget.detail.restSeconds,
        notificationId: notificationId,
        scheduledAt: now,
      ),
    );
    setState(() {
      _restEndsAt = now.add(Duration(seconds: widget.detail.restSeconds));
    });
    widget.onRestEndsAtChanged(_restEndsAt);
  }

  void _clearRestTimer({
    required bool cancelNotification,
    bool notifyParent = true,
  }) {
    _restEndsAt = null;
    if (notifyParent) {
      widget.onRestEndsAtChanged(null);
    }
    if (cancelNotification) {
      unawaited(
          NotificationService.cancelRest(notificationId: _notificationId));
    }
  }

  int get _notificationId => widget.planId * 1000 + widget.exerciseNumber;

  int get restRemainingSeconds {
    final restEndsAt = _restEndsAt;
    if (restEndsAt == null) {
      return 0;
    }
    final remaining = restEndsAt.difference(widget.now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentSet = _nextPendingSetNumber;
    final chips = <String>[
      if ((widget.exercise?.mainMuscleGroup ?? '').trim().isNotEmpty)
        widget.exercise!.mainMuscleGroup,
      if ((widget.exercise?.category ?? '').trim().isNotEmpty)
        widget.exercise!.category,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.expanded
            ? KineticNoirPalette.surface
            : KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.expanded
              ? KineticNoirPalette.primary.withValues(alpha: 0.28)
              : KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
        ),
        boxShadow: widget.expanded
            ? [
                BoxShadow(
                  color: KineticNoirPalette.shadow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ]
            : const [],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isExerciseComplete
                          ? KineticNoirPalette.primary.withValues(alpha: 0.16)
                          : KineticNoirPalette.surfaceBright,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _isExerciseComplete
                          ? const Icon(
                              Icons.check_rounded,
                              color: KineticNoirPalette.primary,
                            )
                          : Text(
                              '${widget.exerciseNumber}',
                              style: KineticNoirTypography.headline(
                                size: 18,
                                weight: FontWeight.w700,
                                color: KineticNoirPalette.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.detail.name,
                          style: KineticNoirTypography.headline(
                            size: widget.expanded ? 26 : 22,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (chips.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final chip in chips)
                                _TagChip(
                                  label: chip,
                                  isHighlighted:
                                      chip == widget.exercise?.mainMuscleGroup,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (widget.expanded) ...[
            if (widget.detail.description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  widget.detail.description,
                  style: KineticNoirTypography.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'TARGET',
                          style: KineticNoirTypography.body(
                            size: 10,
                            weight: FontWeight.w800,
                            color: KineticNoirPalette.onSurfaceVariant,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_visibleSets x ${widget.detail.reps}',
                            style: KineticNoirTypography.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: KineticNoirPalette.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onEditSetup != null)
                    Tooltip(
                      message: 'Edit setup',
                      child: IconButton(
                        key: Key(
                          'active-session-edit-setup-${widget.detail.exerciseId}',
                        ),
                        onPressed: widget.onEditSetup,
                        color: KineticNoirPalette.primary,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    key: Key(
                      'active-set-options-toggle-${widget.detail.exerciseId}',
                    ),
                    onPressed: () {
                      setState(() => _showAdjustActions = !_showAdjustActions);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: KineticNoirPalette.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _showAdjustActions
                          ? Icons.tune_rounded
                          : Icons.more_horiz_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _showAdjustActions ? 'HIDE' : 'MODIFY',
                      style: KineticNoirTypography.body(
                        size: 10,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricPanel(
                      label: 'REST',
                      value: '${widget.detail.restSeconds}s',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricPanel(
                      label: 'RIR',
                      value: '${widget.detail.rir}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricPanel(
                      label: 'TEMPO',
                      value: widget.detail.tempo,
                    ),
                  ),
                ],
              ),
            ),
            ActiveExerciseProgressPanel(
              exerciseId: widget.detail.exerciseId,
              sessionDate: widget.now,
              currentLogs: _completedExerciseLogs,
              weightUnit: widget.weightUnit,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 56, child: _HeaderText('SET')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(child: _HeaderText(widget.weightUnit.label)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Center(child: _HeaderText('REPS'))),
                  const SizedBox(width: 12),
                  const Expanded(child: Center(child: _HeaderText('RIR'))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  for (var index = 0; index < _visibleSets; index++)
                    Padding(
                      key: _setRowKeys[index],
                      padding: EdgeInsets.only(
                        bottom: index == _visibleSets - 1 ? 0 : 10,
                      ),
                      child: _SetRow(
                        key: Key(
                          'active-set-row-${widget.detail.exerciseId}-${index + 1}',
                        ),
                        exerciseId: widget.detail.exerciseId,
                        setNumber: index + 1,
                        isActive: currentSet == index + 1,
                        isCompleted: _isSetCompleted(index + 1),
                        weightController: _weightControllers[index],
                        weightFocusNode: _weightFocusNodes[index],
                        weightUnit: widget.weightUnit,
                        repsController: _repControllers[index],
                        repsFocusNode: _repFocusNodes[index],
                        rirController: _rirControllers[index],
                        rirFocusNode: _rirFocusNodes[index],
                        onWeightChanged: (_) =>
                            _handleFieldChanged(index, _AutoAdvanceField.kg),
                        onRepsChanged: (_) =>
                            _handleFieldChanged(index, _AutoAdvanceField.reps),
                        onRirChanged: (_) =>
                            _handleFieldChanged(index, _AutoAdvanceField.rir),
                      ),
                    ),
                ],
              ),
            ),
            if (_showAdjustActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KineticNoirPalette.surfaceLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: KineticNoirPalette.outlineVariant
                          .withValues(alpha: 0.16),
                    ),
                  ),
                  child: OverflowBar(
                    spacing: 8,
                    overflowSpacing: 8,
                    alignment: MainAxisAlignment.start,
                    overflowAlignment: OverflowBarAlignment.start,
                    children: [
                      TextButton.icon(
                        key: Key('active-set-add-${widget.detail.exerciseId}'),
                        onPressed: _addSet,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'ADD SET',
                          style: KineticNoirTypography.body(
                            size: 11,
                            weight: FontWeight.w800,
                            color: KineticNoirPalette.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: Key(
                          'active-weight-unit-toggle-${widget.detail.exerciseId}',
                        ),
                        onPressed: _switchWeightUnit,
                        icon: const Icon(Icons.swap_vert_rounded, size: 18),
                        label: Text(
                          'SWITCH TO ${_oppositeUnit(widget.weightUnit).label}',
                          style: KineticNoirTypography.body(
                            size: 11,
                            weight: FontWeight.w800,
                            color: KineticNoirPalette.onSurfaceVariant,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: Key(
                            'active-set-remove-${widget.detail.exerciseId}'),
                        onPressed: _visibleSets > 1 ? _removeSet : null,
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        label: Text(
                          'REMOVE SET',
                          style: KineticNoirTypography.body(
                            size: 11,
                            weight: FontWeight.w800,
                            color: _visibleSets > 1
                                ? KineticNoirPalette.onSurfaceVariant
                                : KineticNoirPalette.outlineVariant,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      if (widget.onSwap != null)
                        TextButton.icon(
                          key: Key('active-swap-${widget.detail.exerciseId}'),
                          onPressed: widget.onSwap,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: Text(
                            'SWAP EXERCISE',
                            style: KineticNoirTypography.body(
                              size: 11,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.onSurfaceVariant,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  int _parseInt(String value, int fallback) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  int? _parsePositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double _parseDouble(String value, double fallback) {
    return double.tryParse(value.trim()) ?? fallback;
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderText(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: KineticNoirTypography.body(
              size: 14,
              weight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: KineticNoirTypography.body(
        size: 10,
        weight: FontWeight.w800,
        color: KineticNoirPalette.onSurfaceVariant,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.exerciseId,
    required this.setNumber,
    required this.isActive,
    required this.isCompleted,
    required this.weightController,
    required this.weightFocusNode,
    required this.weightUnit,
    required this.repsController,
    required this.repsFocusNode,
    required this.rirController,
    required this.rirFocusNode,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRirChanged,
    super.key,
  });

  final int exerciseId;
  final int setNumber;
  final bool isActive;
  final bool isCompleted;
  final TextEditingController weightController;
  final FocusNode weightFocusNode;
  final WeightDisplayUnit weightUnit;
  final TextEditingController repsController;
  final FocusNode repsFocusNode;
  final TextEditingController rirController;
  final FocusNode rirFocusNode;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;
  final ValueChanged<String> onRirChanged;

  @override
  Widget build(BuildContext context) {
    final accentColor = isActive
        ? KineticNoirPalette.primary
        : KineticNoirPalette.surfaceBright;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted
            ? KineticNoirPalette.surfaceLow.withValues(alpha: 0.6)
            : KineticNoirPalette.surfaceBright.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? KineticNoirPalette.primary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isActive ? 0.16 : 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: KineticNoirPalette.primary,
                    )
                  : Text(
                      '$setNumber',
                      style: KineticNoirTypography.headline(
                        size: 18,
                        color: isActive
                            ? KineticNoirPalette.primary
                            : KineticNoirPalette.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _WeightInput(
              semanticKey: Key('active-set-$exerciseId-$setNumber-kg'),
              controller: weightController,
              focusNode: weightFocusNode,
              unit: weightUnit,
              enabled: !isCompleted,
              onChanged: onWeightChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NumberInputSlot(
              semanticKey: Key('active-set-$exerciseId-$setNumber-reps'),
              controller: repsController,
              focusNode: repsFocusNode,
              enabled: !isCompleted,
              onChanged: onRepsChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NumberInputSlot(
              semanticKey: Key('active-set-$exerciseId-$setNumber-rir'),
              controller: rirController,
              focusNode: rirFocusNode,
              enabled: !isCompleted,
              onChanged: onRirChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.semanticKey,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final Key semanticKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: semanticKey,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: onChanged,
      onTap: () {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      },
      style: KineticNoirTypography.headline(
        size: 22,
        weight: FontWeight.w700,
        color: enabled
            ? KineticNoirPalette.onSurface
            : KineticNoirPalette.outlineVariant,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: KineticNoirPalette.surfaceLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _NumberInputSlot extends StatelessWidget {
  const _NumberInputSlot({
    required this.semanticKey,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final Key semanticKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 19),
        _NumberInput(
          semanticKey: semanticKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _WeightInput extends StatelessWidget {
  const _WeightInput({
    required this.semanticKey,
    required this.controller,
    required this.focusNode,
    required this.unit,
    required this.enabled,
    required this.onChanged,
  });

  final Key semanticKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final WeightDisplayUnit unit;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final secondaryLabel = _secondaryWeightLabel(value.text);
              if (secondaryLabel.isEmpty) {
                return const SizedBox.shrink();
              }

              return Align(
                alignment: Alignment.center,
                child: Text(
                  secondaryLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KineticNoirTypography.body(
                    size: 9,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.primary.withValues(alpha: 0.82),
                    letterSpacing: 0.8,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 3),
        _NumberInput(
          semanticKey: semanticKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _secondaryWeightLabel(String text) {
    final displayWeight = double.tryParse(text.trim());
    if (displayWeight == null) {
      return '';
    }

    final secondaryUnit = _oppositeUnit(unit);
    final weightKg = _displayWeightToKg(displayWeight, unit);
    final secondaryWeight = _kgToDisplayWeight(weightKg, secondaryUnit);
    return '${_formatWeight(secondaryWeight)} ${secondaryUnit.label}';
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.isHighlighted,
  });

  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlighted
            ? KineticNoirPalette.primary.withValues(alpha: 0.12)
            : KineticNoirPalette.surfaceBright,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: KineticNoirTypography.body(
          size: 9,
          weight: FontWeight.w800,
          color: isHighlighted
              ? KineticNoirPalette.primary
              : KineticNoirPalette.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
