import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/workout_plan.dart';

class DeactivatedRoutinesDropdown extends StatefulWidget {
  const DeactivatedRoutinesDropdown({
    required this.plans,
    required this.onActivate,
    super.key,
  });

  final List<WorkoutPlan> plans;
  final ValueChanged<int> onActivate;

  @override
  State<DeactivatedRoutinesDropdown> createState() =>
      _DeactivatedRoutinesDropdownState();
}

class _DeactivatedRoutinesDropdownState
    extends State<DeactivatedRoutinesDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('inactive-routines-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const Key('inactive-routines-toggle'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: KineticNoirPalette.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'INACTIVE ROUTINES',
                  style: KineticNoirTypography.body(
                    size: 12,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.onSurfaceVariant,
                    letterSpacing: 2.0,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (widget.plans.isEmpty) ...[
          const SizedBox(height: 10),
          _EmptyInactiveRoutinesState(),
        ] else if (_isExpanded) ...[
          const SizedBox(height: 10),
          for (final plan in widget.plans) ...[
            _InactiveRoutineCard(
              plan: plan,
              onActivate: () => widget.onActivate(plan.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _EmptyInactiveRoutinesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inactive-routines-empty'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Text(
        'No inactive routines',
        style: KineticNoirTypography.body(
          size: 13,
          weight: FontWeight.w700,
          color: KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

class _InactiveRoutineCard extends StatelessWidget {
  const _InactiveRoutineCard({
    required this.plan,
    required this.onActivate,
  });

  final WorkoutPlan plan;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('inactive-routine-${plan.id}'),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KineticNoirTypography.headline(
                    size: 18,
                    weight: FontWeight.w700,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'LAST SAVED AS INACTIVE',
                  style: KineticNoirTypography.body(
                    size: 10,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.onSurfaceVariant
                        .withValues(alpha: 0.72),
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            key: Key('inactive-routine-activate-${plan.id}'),
            onPressed: onActivate,
            style: FilledButton.styleFrom(
              backgroundColor: KineticNoirPalette.primary.withValues(
                alpha: 0.12,
              ),
              foregroundColor: KineticNoirPalette.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: Text(
              'Activate',
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w800,
                color: KineticNoirPalette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
