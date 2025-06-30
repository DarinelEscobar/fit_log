import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../pages/exercises_screen.dart';
import '../pages/edit_routine_screen.dart';
import '../widgets/add_routine_button.dart';

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
        data: (plans) => ListView.builder(
          itemCount: plans.length,
          itemBuilder: (_, i) {
            final plan = plans[i];
            return ListTile(
              leading: Text(plan.id.toString()),
              title: Text(plan.name),
              subtitle: Text(plan.frequency),
              trailing: IconButton(
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExercisesScreen(planId: plan.id),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
