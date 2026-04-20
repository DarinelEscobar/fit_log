import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_plan.dart';
import '../pages/edit_routine_screen.dart';
import '../pages/exercises_screen.dart';
import '../providers/exercises_provider.dart';

class RoutineLibraryCard extends ConsumerWidget {
  const RoutineLibraryCard({
    required this.plan,
    required this.onToggleActive,
    super.key,
  });

  final WorkoutPlan plan;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesForPlanProvider(plan.id));
    final exerciseMeta = exercisesAsync.maybeWhen(
      data: _buildMeta,
      orElse: () => const _RoutineExerciseMeta.empty(),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('routine-card-${plan.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExercisesScreen(planId: plan.id),
            ),
          );
        },
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
                            if (exerciseMeta.groups.isNotEmpty) ...[
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
                          _buildSubtitle(exerciseMeta.exerciseCount),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditRoutineScreen(plan: plan),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _CardActionButton(
                        icon: plan.isActive
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: plan.isActive
                            ? KineticNoirPalette.onSurfaceVariant
                            : KineticNoirPalette.primary,
                        tooltip: plan.isActive
                            ? 'Deactivate routine'
                            : 'Activate routine',
                        onPressed: onToggleActive,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (exerciseMeta.groups.isEmpty)
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
                    for (final group in exerciseMeta.groups)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: KineticNoirPalette.outlineVariant
                              .withValues(alpha: 0.32),
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
    );
  }

  String _buildSubtitle(int exerciseCount) {
    if (exerciseCount <= 0) return plan.frequency;
    final noun = exerciseCount == 1 ? 'exercise' : 'exercises';
    return '${plan.frequency} • $exerciseCount $noun';
  }

  _RoutineExerciseMeta _buildMeta(List<Exercise> exercises) {
    final groups = <String>[];
    for (final exercise in exercises) {
      final group = exercise.mainMuscleGroup.trim();
      if (group.isEmpty || groups.contains(group)) continue;
      groups.add(group);
      if (groups.length == 3) break;
    }
    return _RoutineExerciseMeta(
      exerciseCount: exercises.length,
      groups: groups,
    );
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
  final VoidCallback onPressed;

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
            color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _RoutineExerciseMeta {
  const _RoutineExerciseMeta({
    required this.exerciseCount,
    required this.groups,
  });

  const _RoutineExerciseMeta.empty()
      : exerciseCount = 0,
        groups = const [];

  final int exerciseCount;
  final List<String> groups;
}
