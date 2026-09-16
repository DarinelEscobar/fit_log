import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/warm_up_session_state.dart';
import '../../domain/entities/warm_up_step.dart';

class WarmUpPreview extends StatelessWidget {
  const WarmUpPreview({
    required this.steps,
    required this.getReadySeconds,
    required this.onGetReadySecondsChanged,
    required this.onStart,
    required this.onSkip,
    super.key,
  });

  final List<WarmUpStep> steps;
  final int getReadySeconds;
  final ValueChanged<int> onGetReadySecondsChanged;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = steps.fold<int>(
      0,
      (total, step) => total + _stepDurationSeconds(step),
    );
    return ListView(
      key: const Key('warmup-preview'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        Text(
          'YOUR WARM-UP',
          style:
              KineticNoirTypography.headline(size: 30, weight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '${steps.length} exercises - about ${_formatDuration(totalSeconds)}',
          style: KineticNoirTypography.body(
            size: 15,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'GET READY TIME',
          style: KineticNoirTypography.body(
            size: 12,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [5, 10, 15]
              .map(
                (seconds) => ChoiceChip(
                  key: Key('warmup-get-ready-$seconds'),
                  label: Text('$seconds SEC'),
                  selected: getReadySeconds == seconds,
                  onSelected: (_) => onGetReadySecondsChanged(seconds),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 28),
        Text(
          'WARM-UP LIST',
          style: KineticNoirTypography.body(
            size: 12,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < steps.length; index++)
          _WarmUpPreviewStep(number: index + 1, step: steps[index]),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('warmup-start'),
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('START WARM-UP'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('warmup-skip-preview'),
          onPressed: onSkip,
          child: const Text('SKIP WARM-UP'),
        ),
      ],
    );
  }
}

class WarmUpFlow extends StatelessWidget {
  const WarmUpFlow({
    required this.steps,
    required this.state,
    required this.now,
    required this.onPauseResume,
    required this.onSkipStep,
    required this.onFinish,
    super.key,
  });

  final List<WarmUpStep> steps;
  final WarmUpSessionState state;
  final DateTime now;
  final VoidCallback onPauseResume;
  final VoidCallback onSkipStep;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final step = steps[state.stepIndex.clamp(0, steps.length - 1).toInt()];
    final seconds = state.status == WarmUpSessionStatus.paused
        ? state.pausedRemainingSeconds
        : (state.phaseEndsAt?.difference(now).inSeconds ?? 0)
            .clamp(0, 86400)
            .toInt();
    final isGetReady = state.phase == WarmUpPhase.getReady;
    final isRest = state.phase == WarmUpPhase.rest;
    final color =
        isRest ? KineticNoirPalette.error : KineticNoirPalette.primary;
    final phaseLabel = isGetReady ? 'GET READY' : (isRest ? 'REST' : 'WORK');
    final sideLabel = switch (state.side) {
      WarmUpSide.left => 'LEFT SIDE',
      WarmUpSide.right => 'RIGHT SIDE',
      WarmUpSide.none => '',
    };
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isGetReady ? 'UP NEXT' : 'CURRENT WARM-UP EXERCISE',
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              step.name,
              key: const Key('warmup-current-exercise'),
              textAlign: TextAlign.center,
              style: KineticNoirTypography.headline(
                  size: 44, weight: FontWeight.w800),
            ),
            if (step.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                step.notes,
                textAlign: TextAlign.center,
                style: KineticNoirTypography.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border:
                    Border.all(color: color.withValues(alpha: 0.8), width: 8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    phaseLabel,
                    style: KineticNoirTypography.body(
                      size: 14,
                      weight: FontWeight.w900,
                      color: color,
                      letterSpacing: 2,
                    ),
                  ),
                  if (!isGetReady && sideLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      sideLabel,
                      style: KineticNoirTypography.body(
                        size: 11,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '$minutes:${remainder.toString().padLeft(2, '0')}',
                    style: KineticNoirTypography.headline(
                      size: 58,
                      weight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (!isGetReady) ...[
              const SizedBox(height: 16),
              Text(
                'SET ${state.setNumber} OF ${step.sets}',
                style: KineticNoirTypography.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              _nextInstruction(step),
              textAlign: TextAlign.center,
              style: KineticNoirTypography.body(
                size: 13,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('warmup-pause-resume'),
              onPressed: onPauseResume,
              icon: Icon(
                state.status == WarmUpSessionStatus.paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
              label: Text(
                state.status == WarmUpSessionStatus.paused
                    ? 'RESUME TIMER'
                    : 'PAUSE TIMER',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('warmup-skip-step'),
                    onPressed: onSkipStep,
                    child: const Text('SKIP STEP'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    key: const Key('warmup-finish'),
                    onPressed: onFinish,
                    child: const Text('FINISH WARM-UP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _nextInstruction(WarmUpStep step) {
    if (state.phase == WarmUpPhase.getReady) {
      return 'STARTING SET 1 OF ${step.sets}';
    }
    if (state.phase == WarmUpPhase.work &&
        step.perSide &&
        state.side == WarmUpSide.left) {
      return 'NEXT: RIGHT SIDE';
    }
    if (state.phase == WarmUpPhase.work &&
        step.restSeconds > 0 &&
        state.setNumber < step.sets) {
      return 'NEXT: REST';
    }
    if (state.phase == WarmUpPhase.rest || state.setNumber < step.sets) {
      return 'NEXT: SET ${state.setNumber + 1} OF ${step.sets}';
    }
    var nextIndex = state.stepIndex + 1;
    while (state.skippedStepIndexes.contains(nextIndex)) {
      nextIndex++;
    }
    final nextStep = nextIndex < steps.length ? steps[nextIndex] : null;
    return nextStep == null
        ? 'NEXT: STRENGTH SESSION'
        : 'NEXT: ${nextStep.name}';
  }
}

class _WarmUpPreviewStep extends StatelessWidget {
  const _WarmUpPreviewStep({required this.number, required this.step});

  final int number;
  final WarmUpStep step;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KineticNoirPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  KineticNoirPalette.primary.withValues(alpha: 0.14),
              child: Text(
                '$number',
                style: KineticNoirTypography.body(
                  size: 12,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.name,
                    style: KineticNoirTypography.body(
                        size: 16, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${step.sets} sets - ${step.workSeconds}s work${step.perSide ? ' per side' : ''}${step.restSeconds > 0 ? ' - ${step.restSeconds}s rest' : ''}',
                    style: KineticNoirTypography.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                  if (step.notes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.notes,
                      style: KineticNoirTypography.body(
                        size: 12,
                        weight: FontWeight.w500,
                        color: KineticNoirPalette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

int _stepDurationSeconds(WarmUpStep step) {
  final workIntervals = step.sets * (step.perSide ? 2 : 1);
  return (workIntervals * step.workSeconds) +
      ((step.sets - 1).clamp(0, step.sets).toInt() * step.restSeconds);
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return minutes == 0
      ? '${remainder}s'
      : (remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s');
}
