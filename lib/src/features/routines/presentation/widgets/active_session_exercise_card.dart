import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../utils/notification_service.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_log_entry.dart';

typedef SessionLogCallback = void Function(WorkoutLogEntry entry);

class ActiveSessionExerciseCard extends StatefulWidget {
  const ActiveSessionExerciseCard({
    required this.detail,
    required this.planId,
    required this.exerciseNumber,
    required this.expanded,
    required this.logsMap,
    required this.onToggle,
    required this.onSetCountChanged,
    required this.saveDraftLog,
    required this.completeLog,
    required this.removeLog,
    this.exercise,
    this.onSwap,
    super.key,
  });

  final PlanExerciseDetail detail;
  final Exercise? exercise;
  final int planId;
  final int exerciseNumber;
  final bool expanded;
  final Map<String, WorkoutLogEntry> logsMap;
  final VoidCallback onToggle;
  final ValueChanged<int> onSetCountChanged;
  final SessionLogCallback saveDraftLog;
  final SessionLogCallback completeLog;
  final SessionLogCallback removeLog;
  final VoidCallback? onSwap;

  @override
  State<ActiveSessionExerciseCard> createState() =>
      ActiveSessionExerciseCardState();
}

class ActiveSessionExerciseCardState extends State<ActiveSessionExerciseCard>
    with AutomaticKeepAliveClientMixin {
  final List<TextEditingController> _kgControllers = [];
  final List<TextEditingController> _repControllers = [];
  final List<TextEditingController> _rirControllers = [];

  int _visibleSets = 0;
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _showAdjustActions = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resetControllers(widget.detail.sets);
  }

  @override
  void didUpdateWidget(covariant ActiveSessionExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.exerciseId != widget.detail.exerciseId) {
      _showAdjustActions = false;
      _resetControllers(widget.detail.sets);
      return;
    }

    if (oldWidget.expanded && !widget.expanded) {
      _showAdjustActions = false;
    }

    if (widget.detail.sets > _visibleSets) {
      _resetControllers(widget.detail.sets);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      ..._kgControllers,
      ..._repControllers,
      ..._rirControllers,
    ]) {
      controller.dispose();
    }
    _restTimer?.cancel();
    NotificationService.cancelRest();
    super.dispose();
  }

  bool logCurrentSet() {
    final nextSet = _nextPendingSetNumber;
    if (nextSet == null) {
      return false;
    }

    widget.completeLog(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: nextSet,
        reps: _parseInt(_repControllers[nextSet - 1].text, widget.detail.reps),
        weight: _parseDouble(
            _kgControllers[nextSet - 1].text, widget.detail.weight),
        rir: _parseInt(_rirControllers[nextSet - 1].text, widget.detail.rir),
        completed: true,
      ),
    );
    _startRestTimer();
    setState(() {});
    return true;
  }

  void _resetControllers(int targetSets) {
    for (final controller in [
      ..._kgControllers,
      ..._repControllers,
      ..._rirControllers,
    ]) {
      controller.dispose();
    }
    _kgControllers.clear();
    _repControllers.clear();
    _rirControllers.clear();
    _visibleSets = targetSets;

    for (var index = 0; index < targetSets; index++) {
      final setNumber = index + 1;
      final existing = _logFor(setNumber);
      _kgControllers.add(
        TextEditingController(
          text: (existing?.weight ?? widget.detail.weight).toStringAsFixed(0),
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
    }
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

  void _saveDraft(int index) {
    final setNumber = index + 1;
    final current = _logFor(setNumber);
    widget.saveDraftLog(
      WorkoutLogEntry(
        date: DateTime.now(),
        planId: widget.planId,
        exerciseId: widget.detail.exerciseId,
        setNumber: setNumber,
        reps: _parseInt(_repControllers[index].text, widget.detail.reps),
        weight: _parseDouble(_kgControllers[index].text, widget.detail.weight),
        rir: _parseInt(_rirControllers[index].text, widget.detail.rir),
        completed: current?.completed ?? false,
      ),
    );
  }

  void _addSet() {
    final lastWeight = _kgControllers.isEmpty
        ? widget.detail.weight
        : _parseDouble(
            _kgControllers.last.text,
            widget.detail.weight,
          );
    final lastReps = _repControllers.isEmpty
        ? widget.detail.reps
        : _parseInt(_repControllers.last.text, widget.detail.reps);
    final lastRir = _rirControllers.isEmpty
        ? widget.detail.rir
        : _parseInt(_rirControllers.last.text, widget.detail.rir);

    setState(() {
      _visibleSets++;
      _kgControllers.add(
        TextEditingController(text: lastWeight.toStringAsFixed(0)),
      );
      _repControllers.add(TextEditingController(text: '$lastReps'));
      _rirControllers.add(TextEditingController(text: '$lastRir'));
    });

    widget.onSetCountChanged(_visibleSets);
    widget.saveDraftLog(
      WorkoutLogEntry(
        date: DateTime.now(),
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
    setState(() {
      _visibleSets--;
      _kgControllers.removeLast().dispose();
      _repControllers.removeLast().dispose();
      _rirControllers.removeLast().dispose();
    });

    widget.onSetCountChanged(_visibleSets);
    widget.removeLog(
      WorkoutLogEntry(
        date: DateTime.now(),
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

  void _startRestTimer() {
    _restTimer?.cancel();
    NotificationService.cancelRest();
    NotificationService.scheduleRestDone(widget.detail.restSeconds);
    setState(() => _restRemaining = widget.detail.restSeconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_restRemaining <= 1) {
        timer.cancel();
        NotificationService.cancelRest();
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 800, amplitude: 180);
        }
        if (mounted) {
          setState(() => _restRemaining = 0);
        }
      } else if (mounted) {
        setState(() => _restRemaining--);
      }
    });
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
                    child: Icon(
                      _isExerciseComplete
                          ? Icons.check_rounded
                          : widget.exerciseNumber == 1
                              ? Icons.play_arrow_rounded
                              : Icons.fitness_center_rounded,
                      color: _isExerciseComplete
                          ? KineticNoirPalette.primary
                          : KineticNoirPalette.onSurfaceVariant,
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 56, child: _HeaderText('SET')),
                  SizedBox(width: 12),
                  Expanded(child: Center(child: _HeaderText('KG'))),
                  SizedBox(width: 12),
                  Expanded(child: Center(child: _HeaderText('REPS'))),
                  SizedBox(width: 12),
                  Expanded(child: Center(child: _HeaderText('RIR'))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  for (var index = 0; index < _visibleSets; index++)
                    Padding(
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
                        kgController: _kgControllers[index],
                        repsController: _repControllers[index],
                        rirController: _rirControllers[index],
                        onChanged: () => _saveDraft(index),
                      ),
                    ),
                ],
              ),
            ),
            if (_restRemaining > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: KineticNoirPalette.surfaceLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: KineticNoirPalette.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: KineticNoirPalette.primary
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_restRemaining',
                            style: KineticNoirTypography.body(
                              size: 12,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rest timer running · ${widget.detail.restSeconds}s target',
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
    required this.kgController,
    required this.repsController,
    required this.rirController,
    required this.onChanged,
    super.key,
  });

  final int exerciseId;
  final int setNumber;
  final bool isActive;
  final bool isCompleted;
  final TextEditingController kgController;
  final TextEditingController repsController;
  final TextEditingController rirController;
  final VoidCallback onChanged;

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
              child: Text(
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
            child: _NumberInput(
              semanticKey: Key('active-set-$exerciseId-$setNumber-kg'),
              controller: kgController,
              enabled: !isCompleted,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NumberInput(
              semanticKey: Key('active-set-$exerciseId-$setNumber-reps'),
              controller: repsController,
              enabled: !isCompleted,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NumberInput(
              semanticKey: Key('active-set-$exerciseId-$setNumber-rir'),
              controller: rirController,
              enabled: !isCompleted,
              onChanged: onChanged,
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
    required this.enabled,
    required this.onChanged,
  });

  final Key semanticKey;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: semanticKey,
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: (_) => onChanged(),
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
