import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../../../routines/domain/entities/workout_plan.dart';
import 'plan_logs_screen.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(workoutPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: asyncPlans.when(
        data: (plans) => _PlansList(plans: plans),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PlansList extends ConsumerWidget {
  final List<WorkoutPlan> plans;
  const _PlansList({required this.plans});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) return const Center(child: Text('No hay planes'));
    return ListView.builder(
      itemCount: plans.length,
      itemBuilder: (_, i) {
        final p = plans[i];
        return ListTile(
          title: Text(p.name),
          subtitle: Text('Plan ${p.id}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlanLogsScreen(planId: p.id, planName: p.name),
            ),
          ),
        );
      },
    );
  }
}
