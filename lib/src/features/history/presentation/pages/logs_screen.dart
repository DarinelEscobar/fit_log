import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../routines/domain/entities/workout_plan.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import 'plan_logs_screen.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(workoutPlanProvider);

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: KineticNoirPalette.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Workout Logs',
          style: KineticNoirTypography.headline(
            size: 20,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
      ),
      body: asyncPlans.when(
        data: (plans) => _PlansList(plans: plans),
        loading: () => const Center(
          child: CircularProgressIndicator(color: KineticNoirPalette.primary),
        ),
        error: (e, __) => Center(
          child: Text(
            'Error: $e',
            style: KineticNoirTypography.body(
              size: 14,
              color: KineticNoirPalette.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlansList extends ConsumerWidget {
  final List<WorkoutPlan> plans;
  const _PlansList({required this.plans});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) {
      return Center(
        child: Text(
          'No workout plans available',
          style: KineticNoirTypography.body(
            size: 14,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: plans.length,
      itemBuilder: (context, i) {
        final p = plans[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanLogsScreen(planId: p.id, planName: p.name),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: KineticNoirPalette.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: KineticNoirPalette.outlineVariant
                        .withValues(alpha: 0.12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: KineticNoirTypography.body(
                              size: 15,
                              weight: FontWeight.w700,
                              color: KineticNoirPalette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Plan ID ${p.id}',
                            style: KineticNoirTypography.body(
                              size: 12,
                              color: KineticNoirPalette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
