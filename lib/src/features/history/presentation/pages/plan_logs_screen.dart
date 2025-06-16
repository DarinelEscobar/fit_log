import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../routines/presentation/providers/exercises_provider.dart';
import '../../../routines/domain/entities/exercise.dart';
import 'exercise_logs_screen.dart';

class PlanLogsScreen extends ConsumerWidget {
  final int planId;
  final String planName;
  const PlanLogsScreen({super.key, required this.planId, required this.planName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExercises = ref.watch(exercisesForPlanProvider(planId));

    return Scaffold(
      appBar: AppBar(title: Text(planName)),
      body: asyncExercises.when(
        data: (exercises) => _buildList(context, exercises),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Exercise> ex) {
    return ListView.builder(
      itemCount: ex.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(ex[i].name),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseLogsScreen(
              exerciseId: ex[i].id,
              exerciseName: ex[i].name,
            ),
          ),
        ),
      ),
    );
  }
}
