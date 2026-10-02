import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/weight_display_unit.dart';

class ActiveSessionExerciseTitle extends StatelessWidget {
  const ActiveSessionExerciseTitle({
    required this.fullName,
    required this.expanded,
    super.key,
  });

  final String fullName;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final parts = _splitExerciseName(fullName);
    return Tooltip(
      message: fullName,
      child: Semantics(
        header: true,
        excludeSemantics: true,
        label: 'Exercise $fullName',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parts.primary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KineticNoirTypography.headline(
                size: expanded ? 19 : 17,
                height: 1.2,
              ),
            ),
            if (parts.variant != null) ...[
              const SizedBox(height: 4),
              Text(
                parts.variant!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KineticNoirTypography.body(
                  size: 11,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({String primary, String? variant}) _splitExerciseName(String value) {
    final name = value.trim();
    final separator = RegExp(r'\s+[—–]\s+').firstMatch(name);
    if (separator == null) {
      return (primary: name, variant: null);
    }

    final primary = name.substring(0, separator.start).trim();
    final variant = name.substring(separator.end).trim();
    if (primary.isEmpty || variant.isEmpty) {
      return (primary: name, variant: null);
    }
    return (primary: primary, variant: variant);
  }
}

class ActiveSessionExecutionSummary extends StatelessWidget {
  const ActiveSessionExecutionSummary({
    required this.currentSet,
    required this.totalSets,
    required this.targetReps,
    required this.rir,
    required this.tempo,
    super.key,
  });

  final int? currentSet;
  final int totalSets;
  final int targetReps;
  final int rir;
  final String tempo;

  @override
  Widget build(BuildContext context) {
    final statusLabel = currentSet == null
        ? 'Exercise complete'
        : 'Current set $currentSet of $totalSets';

    return Semantics(
      excludeSemantics: true,
      label: '$statusLabel. Target $targetReps reps. RIR $rir. Tempo $tempo.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: KineticNoirPalette.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ExecutionMetric(
                label: currentSet == null ? 'STATUS' : 'NEXT SET',
                value: currentSet == null ? 'DONE' : '$currentSet / $totalSets',
                highlighted: true,
              ),
            ),
            Expanded(
              child: _ExecutionMetric(
                label: 'TARGET',
                value: '$targetReps REPS',
              ),
            ),
            Expanded(child: _ExecutionMetric(label: 'RIR', value: '$rir')),
            Expanded(
              child: _ExecutionMetric(label: 'TEMPO', value: tempo),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveSessionDisclosureHeader extends StatelessWidget {
  const ActiveSessionDisclosureHeader({
    required this.semanticKey,
    required this.buttonKey,
    required this.label,
    required this.expanded,
    required this.onTap,
    super.key,
  });

  final Key semanticKey;
  final Key buttonKey;
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: semanticKey,
      button: true,
      expanded: expanded,
      label: expanded ? 'Collapse $label' : 'Expand $label',
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: KineticNoirTypography.body(
                      size: 10,
                      weight: FontWeight.w900,
                      color: KineticNoirPalette.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveSessionPlanDetailsPanel extends StatelessWidget {
  const ActiveSessionPlanDetailsPanel({
    required this.exerciseId,
    required this.description,
    required this.chips,
    required this.mainMuscleGroup,
    required this.totalSets,
    required this.targetReps,
    required this.restSeconds,
    required this.rir,
    required this.tempo,
    required this.oppositeWeightUnit,
    required this.canRemoveSet,
    required this.onEditSetup,
    required this.onAddSet,
    required this.onSwitchWeightUnit,
    required this.onRemoveSet,
    required this.onSwap,
    super.key,
  });

  final int exerciseId;
  final String description;
  final List<String> chips;
  final String? mainMuscleGroup;
  final int totalSets;
  final int targetReps;
  final int restSeconds;
  final int rir;
  final String tempo;
  final WeightDisplayUnit oppositeWeightUnit;
  final bool canRemoveSet;
  final VoidCallback? onEditSetup;
  final VoidCallback onAddSet;
  final VoidCallback onSwitchWeightUnit;
  final VoidCallback? onRemoveSet;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chips.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips)
                  _TagChip(
                    label: chip,
                    isHighlighted: chip == mainMuscleGroup,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (description.trim().isNotEmpty) ...[
            Text(
              description,
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _PlanDetailMetric(
                      label: 'TARGET',
                      value: '$totalSets x $targetReps',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _PlanDetailMetric(
                      label: 'REST',
                      value: '${restSeconds}s',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _PlanDetailMetric(label: 'RIR', value: '$rir'),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _PlanDetailMetric(label: 'TEMPO', value: tempo),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          OverflowBar(
            spacing: 8,
            overflowSpacing: 8,
            alignment: MainAxisAlignment.start,
            overflowAlignment: OverflowBarAlignment.start,
            children: [
              if (onEditSetup != null)
                TextButton.icon(
                  key: Key('active-session-edit-setup-$exerciseId'),
                  onPressed: onEditSetup,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('EDIT SETUP'),
                ),
              TextButton.icon(
                key: Key('active-set-add-$exerciseId'),
                onPressed: onAddSet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('ADD SET'),
              ),
              TextButton.icon(
                key: Key('active-weight-unit-toggle-$exerciseId'),
                onPressed: onSwitchWeightUnit,
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                label: Text('SWITCH TO ${oppositeWeightUnit.label}'),
              ),
              TextButton.icon(
                key: Key('active-set-remove-$exerciseId'),
                onPressed: onRemoveSet,
                icon: const Icon(Icons.remove_rounded, size: 18),
                label: Text(
                  'REMOVE SET',
                  style: TextStyle(
                    color: canRemoveSet
                        ? KineticNoirPalette.onSurfaceVariant
                        : KineticNoirPalette.outlineVariant,
                  ),
                ),
              ),
              if (onSwap != null)
                TextButton.icon(
                  key: Key('active-swap-$exerciseId'),
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('SWAP EXERCISE'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExecutionMetric extends StatelessWidget {
  const _ExecutionMetric({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color =
        highlighted ? KineticNoirPalette.primary : KineticNoirPalette.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KineticNoirTypography.body(
            size: 8,
            weight: FontWeight.w900,
            color: highlighted
                ? KineticNoirPalette.primary
                : KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KineticNoirTypography.body(
            size: 11,
            weight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PlanDetailMetric extends StatelessWidget {
  const _PlanDetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: KineticNoirTypography.body(
                size: 10,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: KineticNoirTypography.body(
              size: 12,
              weight: FontWeight.w900,
              color: KineticNoirPalette.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.isHighlighted});

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
