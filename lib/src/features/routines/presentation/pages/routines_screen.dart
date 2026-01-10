import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../pages/exercises_screen.dart';
import '../pages/edit_routine_screen.dart';
import '../widgets/add_routine_button.dart';
import '../widgets/deactivated_routines_dropdown.dart';

class RoutinesScreen extends ConsumerWidget {
  static const routeName = '/routines';

  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(workoutPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      floatingActionButton: const AddRoutineButton(), // <- el botón mágico
      body: asyncPlans.when(
        data: (plans) {
          final activePlans = plans.where((plan) => plan.isActive).toList();
          final inactivePlans = plans.where((plan) => !plan.isActive).toList();
          return Column(
            children: [
              if (inactivePlans.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: DeactivatedRoutinesDropdown(
                    plans: inactivePlans,
                    onActivate: (planId) => ref
                        .read(workoutPlanProvider.notifier)
                        .setPlanActive(planId, true),
                  ),
                ),
              Expanded(
                child: activePlans.isEmpty
                    ? const Center(child: Text('No hay rutinas activas'))
                    : ListView.builder(
                        itemCount: activePlans.length,
                        itemBuilder: (_, i) {
                          final plan = activePlans[i];
                          return ListTile(
                            leading: Text(plan.id.toString()),
                            title: Text(plan.name),
                            subtitle: Text(plan.frequency),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditRoutineScreen(planId: plan.id),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.pause_circle_outline),
                                  tooltip: 'Desactivar rutina',
                                  onPressed: () => ref
                                      .read(workoutPlanProvider.notifier)
                                      .setPlanActive(plan.id, false),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExercisesScreen(planId: plan.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
