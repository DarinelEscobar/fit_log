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
    return Material(
      color: KineticNoirPalette.surfaceLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('routine-card-${plan.id}'),
        onTap: isBusy ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KineticNoirTypography.headline(
                            size: 20, height: 1.2)),
                    const SizedBox(height: 6),
                    Text(_buildSubtitle(),
                        style: KineticNoirTypography.body(
                            size: 12,
                            color: KineticNoirPalette.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(
                      !isMetadataReady
                          ? 'Loading exercise details…'
                          : muscleGroups.isEmpty
                              ? 'No exercises programmed'
                              : muscleGroups.join(' · '),
                      style: KineticNoirTypography.body(
                          size: 11, color: KineticNoirPalette.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Routine actions',
                enabled: !isBusy,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.more_horiz_rounded),
                onSelected: (value) =>
                    value == 'edit' ? onEdit() : onToggleActive(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Edit routine')),
                  PopupMenuItem(
                      value: 'active',
                      child: Text(plan.isActive
                          ? 'Deactivate routine'
                          : 'Activate routine')),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14, right: 6),
                child: Icon(Icons.chevron_right_rounded,
                    size: 20, color: KineticNoirPalette.primary),
              ),
            ],
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
