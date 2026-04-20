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
    if (widget.plans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
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
        if (_isExpanded) ...[
          const SizedBox(height: 10),
          for (final plan in widget.plans) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      KineticNoirPalette.outlineVariant.withValues(alpha: 0.18),
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
                    onPressed: () => widget.onActivate(plan.id),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          KineticNoirPalette.primary.withValues(alpha: 0.12),
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
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
