import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercises_provider.dart';
import 'start_routine_screen.dart';

class ExercisesScreen extends ConsumerWidget {
  final int planId;
  const ExercisesScreen({required this.planId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExercises = ref.watch(exercisesForPlanProvider(planId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicios')),
      body: asyncExercises.when(
        data: (exercises) => ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (_, i) {
            final exercise = exercises[i];
            return ListTile(
              title: Text(exercise.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exercise.description.isNotEmpty)
                    Text(
                      exercise.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                  Text(
                    '${exercise.category} • ${exercise.mainMuscleGroup}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.play_arrow),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StartRoutineScreen(planId: planId),
          ),
        ),
      ),
    );
  }
}
