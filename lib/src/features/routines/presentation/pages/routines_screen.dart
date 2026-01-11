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
              if (activePlans.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, size: 18, color: Color(0xFF8E8CF8)),
                      const SizedBox(width: 8),
                      const Text(
                        'Rutinas activas',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${activePlans.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: activePlans.isEmpty
                    ? const Center(child: Text('No hay rutinas activas'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: activePlans.length,
                        itemBuilder: (_, i) {
                          final plan = activePlans[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Text(
                                  plan.name.isNotEmpty
                                      ? plan.name.characters.first
                                      : 'R',
                                  style: const TextStyle(
                                    color: Color(0xFF0F0F10),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(plan.name),
                              subtitle: Text(plan.frequency),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditRoutineScreen(
                                            planId: plan.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.pause_circle_outline,
                                    ),
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
                            ),
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
