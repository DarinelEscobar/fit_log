import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercises_provider.dart';

class SelectExerciseScreen extends ConsumerWidget {
  final Set<String> groups;
  const SelectExerciseScreen({required this.groups, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExercises = ref.watch(allExercisesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir ejercicio')),
      body: asyncExercises.when(
        data: (ex) {
          final filtered = ex.where((e) => groups.contains(e.mainMuscleGroup)).toList();
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final exercise = filtered[i];
              return ListTile(
                title: Text(exercise.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exercise.description.isNotEmpty)
                      Text(exercise.description, style: const TextStyle(fontSize: 12)),
                    Text('${exercise.category} • ${exercise.mainMuscleGroup}',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
                onTap: () => Navigator.pop(context, exercise),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
