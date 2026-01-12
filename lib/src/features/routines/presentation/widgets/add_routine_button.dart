import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/create_workout_plan_usecase.dart';
import '../providers/workout_plan_repository_provider.dart';
import '../providers/workout_plan_provider.dart';

class AddRoutineButton extends ConsumerWidget {
  const AddRoutineButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () async {
        final nameController = TextEditingController();
        final frequencyController = TextEditingController();

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.playlist_add, size: 20),
                SizedBox(width: 8),
                Text('Nueva Rutina'),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre de rutina'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final repo = ref.read(workoutPlanRepositoryProvider);
                  final usecase = CreateWorkoutPlanUseCase(repo);
                  await usecase(
                    nameController.text.trim(),
                    frequencyController.text.trim(),
                  );
                  ref.invalidate(workoutPlanProvider); // Refrescar lista
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
