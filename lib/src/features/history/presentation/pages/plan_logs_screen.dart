import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../routines/domain/entities/exercise.dart';
import '../../../routines/presentation/providers/exercises_provider.dart';
import 'exercise_logs_screen.dart';

class PlanLogsScreen extends ConsumerWidget {
  final int planId;
  final String planName;

  const PlanLogsScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExercises = ref.watch(exercisesForPlanProvider(planId));

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
          planName,
          style: KineticNoirTypography.headline(
            size: 20,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
      ),
      body: asyncExercises.when(
        data: (exercises) => _buildList(context, exercises),
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

  Widget _buildList(BuildContext context, List<Exercise> ex) {
    if (ex.isEmpty) {
      return Center(
        child: Text(
          'No exercises in this plan',
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
      itemCount: ex.length,
      itemBuilder: (context, i) {
        final exercise = ex[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseLogsScreen(
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                  ),
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
                      child: Text(
                        exercise.name,
                        style: KineticNoirTypography.body(
                          size: 15,
                          weight: FontWeight.w700,
                          color: KineticNoirPalette.onSurface,
                        ),
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
