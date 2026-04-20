import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/workout_plan.dart';

class RoutineLibraryCard extends StatelessWidget {
  const RoutineLibraryCard({
    required this.plan,
    required this.exerciseCount,
    required this.muscleGroups,
    required this.isBusy,
    required this.isMetadataReady,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleActive,
    super.key,
  });

  final WorkoutPlan plan;
  final int exerciseCount;
  final List<String> muscleGroups;
  final bool isBusy;
  final bool isMetadataReady;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('routine-card-${plan.id}'),
          borderRadius: BorderRadius.circular(20),
          onTap: isBusy ? null : onOpen,
          child: Ink(
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceLow,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plan.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: KineticNoirTypography.headline(
                                    size: 24,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (muscleGroups.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: KineticNoirPalette.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _buildSubtitle(),
                            style: KineticNoirTypography.body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: KineticNoirPalette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CardActionButton(
                          icon: Icons.edit_rounded,
                          color: KineticNoirPalette.onSurfaceVariant,
                          tooltip: 'Edit routine',
                          onPressed: isBusy ? null : onEdit,
                        ),
                        const SizedBox(width: 8),
                        _CardActionButton(
                          icon: isBusy
                              ? Icons.sync_rounded
                              : plan.isActive
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                          color: isBusy
                              ? KineticNoirPalette.primary
                              : plan.isActive
                                  ? KineticNoirPalette.onSurfaceVariant
                                  : KineticNoirPalette.primary,
                          tooltip: plan.isActive
                              ? 'Deactivate routine'
                              : 'Activate routine',
                          onPressed: isBusy ? null : onToggleActive,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!isMetadataReady)
                  Text(
                    'Routine metadata syncing in background',
                    style: KineticNoirTypography.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: KineticNoirPalette.onSurfaceVariant
                          .withValues(alpha: 0.72),
                      letterSpacing: 1.0,
                    ),
                  )
                else if (muscleGroups.isEmpty)
                  Text(
                    'No programmed muscle groups yet',
                    style: KineticNoirTypography.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: KineticNoirPalette.onSurfaceVariant,
                      letterSpacing: 1.0,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final group in muscleGroups)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: KineticNoirPalette.outlineVariant
                                .withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            group.toUpperCase(),
                            style: KineticNoirTypography.body(
                              size: 10,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.onSurfaceVariant,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (!isMetadataReady || exerciseCount <= 0) {
      return plan.frequency;
    }
    final noun = exerciseCount == 1 ? 'exercise' : 'exercises';
    return '${plan.frequency} • $exerciseCount $noun';
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
