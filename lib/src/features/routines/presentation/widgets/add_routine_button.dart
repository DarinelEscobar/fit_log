import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/create_workout_plan_usecase.dart';
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
            title: const Text('Nueva Rutina'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre de rutina'),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final repo = WorkoutPlanRepositoryImpl();
                  final usecase = CreateWorkoutPlanUseCase(repo);
                  await usecase(
                    nameController.text.trim(),
                    frequencyController.text.trim(),
                  );
                  ref.invalidate(workoutPlanProvider); // Refrescar lista
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
