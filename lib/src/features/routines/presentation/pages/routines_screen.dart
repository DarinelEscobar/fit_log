import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../pages/exercises_screen.dart';
import '../pages/edit_routine_screen.dart';
import '../widgets/add_routine_button.dart';
import '../providers/workout_plan_actions_provider.dart';

class RoutinesScreen extends ConsumerWidget {
  static const routeName = '/routines';

  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(workoutPlanProvider);
    final actions = ref.read(workoutPlanActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      floatingActionButton: const AddRoutineButton(), // <- el botón mágico
      body: asyncPlans.when(
        data: (plans) => ListView.builder(
          itemCount: plans.length,
          itemBuilder: (_, i) {
            final plan = plans[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(plan.id.toString()),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(plan.name)),
                    if (!plan.isActive)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Chip(
                          label: Text('Inactiva'),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.frequency),
                    if (!plan.isActive)
                      const Text(
                        'Activa la rutina para iniciarla',
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        plan.isActive
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                      ),
                      tooltip:
                          plan.isActive ? 'Desactivar' : 'Activar',
                      onPressed: () async {
                        await actions.toggleActive(plan.id, !plan.isActive);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditRoutineScreen(planId: plan.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  if (!plan.isActive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Esta rutina está desactivada. Actívala para iniciarla.'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExercisesScreen(planId: plan.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
