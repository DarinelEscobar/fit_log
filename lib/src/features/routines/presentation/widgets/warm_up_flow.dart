import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/warm_up_session_state.dart';
import '../../domain/entities/warm_up_step.dart';

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
    final isRest = state.phase == WarmUpPhase.rest;
    final color =
        isRest ? KineticNoirPalette.error : KineticNoirPalette.primary;
    final phaseLabel = isRest ? 'REST' : 'WORK';
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
            Text('WARM-UP',
                style: KineticNoirTypography.body(
                    size: 12,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.onSurfaceVariant,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(step.name,
                textAlign: TextAlign.center,
                style: KineticNoirTypography.headline(
                    size: 32, weight: FontWeight.w700)),
            if (step.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(step.notes,
                  textAlign: TextAlign.center,
                  style: KineticNoirTypography.body(
                      size: 15,
                      weight: FontWeight.w600,
                      color: KineticNoirPalette.onSurfaceVariant)),
            ],
            const SizedBox(height: 28),
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border:
                    Border.all(color: color.withValues(alpha: 0.8), width: 8),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(phaseLabel,
                        style: KineticNoirTypography.body(
                            size: 14,
                            weight: FontWeight.w900,
                            color: color,
                            letterSpacing: 2)),
                    if (sideLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(sideLabel,
                          style: KineticNoirTypography.body(
                              size: 11,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.onSurfaceVariant,
                              letterSpacing: 1.2)),
                    ],
                    const SizedBox(height: 12),
                    Text('$minutes:${remainder.toString().padLeft(2, '0')}',
                        style: KineticNoirTypography.headline(
                            size: 58, weight: FontWeight.w700, color: color)),
                  ]),
            ),
            const SizedBox(height: 24),
            Text('SET ${state.setNumber} OF ${step.sets}',
                style: KineticNoirTypography.body(
                    size: 13,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.onSurfaceVariant,
                    letterSpacing: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('warmup-pause-resume'),
              onPressed: onPauseResume,
              icon: Icon(state.status == WarmUpSessionStatus.paused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded),
              label: Text(state.status == WarmUpSessionStatus.paused
                  ? 'RESUME TIMER'
                  : 'PAUSE TIMER'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: onSkipStep, child: const Text('SKIP STEP'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextButton(
                      onPressed: onFinish,
                      child: const Text('FINISH WARM-UP'))),
            ]),
          ],
        ),
      ),
    );
  }
}
