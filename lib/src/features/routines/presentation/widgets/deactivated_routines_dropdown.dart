import 'package:flutter/material.dart';
import '../../domain/entities/workout_plan.dart';

class DeactivatedRoutinesDropdown extends StatefulWidget {
  final List<WorkoutPlan> plans;
  final ValueChanged<int> onActivate;

  const DeactivatedRoutinesDropdown({
    required this.plans,
    required this.onActivate,
    super.key,
  });

  @override
  State<DeactivatedRoutinesDropdown> createState() =>
      _DeactivatedRoutinesDropdownState();
}

class _DeactivatedRoutinesDropdownState
    extends State<DeactivatedRoutinesDropdown> {
  int? _selectedPlanId;

  @override
  Widget build(BuildContext context) {
    if (widget.plans.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text('Rutinas desactivadas'),
      subtitle: Text('${widget.plans.length} disponibles'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        DropdownButtonFormField<int>(
          value: _selectedPlanId,
          decoration: const InputDecoration(
            labelText: 'Selecciona una rutina para activar',
            border: OutlineInputBorder(),
          ),
          items: widget.plans
              .map(
                (plan) => DropdownMenuItem<int>(
                  value: plan.id,
                  child: Text(plan.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            widget.onActivate(value);
            setState(() => _selectedPlanId = null);
          },
        ),
      ],
    );
  }
}
