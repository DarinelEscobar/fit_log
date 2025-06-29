import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/add_plan_exercise_usecase.dart';
import '../../domain/usecases/update_plan_exercise_usecase.dart';
import '../../domain/usecases/remove_plan_exercise_usecase.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/exercise.dart';
import '../pages/select_exercise_screen.dart';
import 'start_routine_screen.dart';

class ExercisesScreen extends ConsumerWidget {
  final int planId;
  const ExercisesScreen({required this.planId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetails = ref.watch(planExerciseDetailsProvider(planId));
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicios')),
      body: asyncDetails.when(
        data: (details) => ListView.builder(
          itemCount: details.length,
          itemBuilder: (_, i) {
            final d = details[i];
            return ListTile(
              title: Text(d.name),
              subtitle: Text(
                  '${d.sets}x${d.reps} @${d.weight.toStringAsFixed(0)}kg • ${d.restSeconds}s'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newDet = await _showEditDialog(context, d);
                      if (newDet != null) {
                        final repo = WorkoutPlanRepositoryImpl();
                        await UpdatePlanExerciseUseCase(repo)(
                          planId: planId,
                          exerciseId: d.exerciseId,
                          sets: newDet.sets,
                          reps: newDet.reps,
                          weight: newDet.weight,
                          restSeconds: newDet.restSeconds,
                        );
                        ref.invalidate(planExerciseDetailsProvider(planId));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar ejercicio?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final repo = WorkoutPlanRepositoryImpl();
                        await RemovePlanExerciseUseCase(repo)(planId, d.exerciseId);
                        ref.invalidate(planExerciseDetailsProvider(planId));
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            child: const Icon(Icons.add),
            onPressed: () async {
              final exercise = await Navigator.push<Exercise>(
                context,
                MaterialPageRoute(
                  builder: (_) => const SelectExerciseScreen(groups: {}),
                ),
              );
              if (exercise == null) return;
              final detail = await _showEditDialog(context, null, name: exercise.name);
              if (detail != null) {
                final repo = WorkoutPlanRepositoryImpl();
                await AddPlanExerciseUseCase(repo)(
                  planId: planId,
                  exerciseId: exercise.id,
                  sets: detail.sets,
                  reps: detail.reps,
                  weight: detail.weight,
                  restSeconds: detail.restSeconds,
                );
                ref.invalidate(planExerciseDetailsProvider(planId));
              }
            },
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'start',
            child: const Icon(Icons.play_arrow),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StartRoutineScreen(planId: planId),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<PlanExerciseDetail?> _showEditDialog(
    BuildContext ctx,
    PlanExerciseDetail? detail, {
    String? name,
  }) async {
    final setsCtl = TextEditingController(text: detail?.sets.toString() ?? '3');
    final repsCtl = TextEditingController(text: detail?.reps.toString() ?? '10');
    final weightCtl = TextEditingController(
        text: detail?.weight.toStringAsFixed(0) ?? '0');
    final restCtl = TextEditingController(text: detail?.restSeconds.toString() ?? '90');
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(name ?? detail!.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsCtl,
              decoration: const InputDecoration(labelText: 'Series'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsCtl,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightCtl,
              decoration: const InputDecoration(labelText: 'Peso kg'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: restCtl,
              decoration: const InputDecoration(labelText: 'Descanso seg'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      return PlanExerciseDetail(
        exerciseId: detail?.exerciseId ?? 0,
        name: name ?? detail!.name,
        description: detail?.description ?? '',
        sets: int.tryParse(setsCtl.text) ?? 0,
        reps: int.tryParse(repsCtl.text) ?? 0,
        weight: double.tryParse(weightCtl.text) ?? 0,
        restSeconds: int.tryParse(restCtl.text) ?? 0,
      );
    }
    return null;
  }
}
