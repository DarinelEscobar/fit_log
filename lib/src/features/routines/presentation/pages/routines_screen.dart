import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_plan_provider.dart';

class RoutinesScreen extends ConsumerWidget {
  static const routeName = 'routines';

  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(workoutPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: asyncPlans.when(
        data: (plans) => ListView.builder(
          itemCount: plans.length,
          itemBuilder: (_, i) => ListTile(
            leading: Text(plans[i].id.toString()),
            title: Text(plans[i].name),
            subtitle: Text(plans[i].frequency),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
