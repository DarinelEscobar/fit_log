import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../pages/exercises_screen.dart'; // Nueva pantalla
import '../widgets/add_routine_button.dart'; // importar botón

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
