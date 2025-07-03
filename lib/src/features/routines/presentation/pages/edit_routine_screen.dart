import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/exercises_provider.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/usecases/add_exercise_to_plan_usecase.dart';
import '../../domain/usecases/update_exercise_in_plan_usecase.dart';
import '../../domain/usecases/delete_exercise_from_plan_usecase.dart';
import '../../domain/usecases/create_exercise_usecase.dart';
import '../../domain/usecases/update_exercise_usecase.dart';
import 'select_exercise_screen.dart';

class EditRoutineScreen extends ConsumerStatefulWidget {
  final int planId;
  const EditRoutineScreen({required this.planId, super.key});

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late Future<List<PlanExerciseDetail>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(planExerciseDetailsProvider(widget.planId).future);
  }

  Future<void> _refresh() async {
    final provider = planExerciseDetailsProvider(widget.planId);
    ref.invalidate(provider);
    setState(() {
      _future = ref.read(provider.future);
    });
  }

  Future<void> _addExercise() async {
    final all = await ref.read(allExercisesProvider.future);
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(
          groups: {for (var e in all) e.mainMuscleGroup},
        ),
      ),
    );
    if (exercise != null) {
      final current = await ref.read(
        planExerciseDetailsProvider(widget.planId).future,
      );
      final posCtl = TextEditingController(
        text: '${current.length + 1}',
      );
      final index = await showDialog<int>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Posición del ejercicio'),
          content: TextField(
            controller: posCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '1 = inicio'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                int.tryParse(posCtl.text) ?? current.length + 1,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      final repo = WorkoutPlanRepositoryImpl();
      await AddExerciseToPlanUseCase(repo)(
        widget.planId,
        PlanExerciseDetail(
          exerciseId: exercise.id,
          name: exercise.name,
          description: exercise.description,
          sets: 3,
          reps: 10,
          weight: 0,
          restSeconds: 90,
        ),
        position: ((index ?? (current.length + 1)) - 1).clamp(0, current.length),
      );
      await _refresh();
    }
  }

  Future<void> _createExercise() async {
    final nameCtl = TextEditingController();
    final descCtl = TextEditingController();
    final catCtl = TextEditingController();
    final groupCtl = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo ejercicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: descCtl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: catCtl,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextField(
                controller: groupCtl,
                decoration:
                    const InputDecoration(labelText: 'Músculo principal'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (save == true) {
      final repo = WorkoutPlanRepositoryImpl();
      await CreateExerciseUseCase(repo)(
        nameCtl.text.trim(),
        descCtl.text.trim(),
        catCtl.text.trim(),
        groupCtl.text.trim(),
      );
      ref.invalidate(allExercisesProvider);
    }
  }

  Future<void> _editExercise(int exerciseId) async {
    final all = await ref.read(allExercisesProvider.future);
    final ex = all.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise(
        id: 0,
        name: '',
        description: '',
        category: '',
        mainMuscleGroup: '',
      ),
    );
    if (ex.id == 0) return;

    final nameCtl = TextEditingController(text: ex.name);
    final descCtl = TextEditingController(text: ex.description);
    final catCtl = TextEditingController(text: ex.category);
    final groupCtl = TextEditingController(text: ex.mainMuscleGroup);

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar ejercicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: descCtl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: catCtl,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextField(
                controller: groupCtl,
                decoration:
                    const InputDecoration(labelText: 'Músculo principal'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (save == true) {
      final repo = WorkoutPlanRepositoryImpl();
      await UpdateExerciseUseCase(repo)(
        ex.id,
        nameCtl.text.trim(),
        descCtl.text.trim(),
        catCtl.text.trim(),
        groupCtl.text.trim(),
      );
      ref.invalidate(allExercisesProvider);
      await _refresh();
    }
  }

  Future<void> _updateDetail(PlanExerciseDetail detail) async {
    final repo = WorkoutPlanRepositoryImpl();
    await UpdateExerciseInPlanUseCase(repo)(widget.planId, detail);
    await _refresh();
  }

  Future<void> _deleteDetail(int exerciseId) async {
    final repo = WorkoutPlanRepositoryImpl();
    await DeleteExerciseFromPlanUseCase(repo)(widget.planId, exerciseId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar rutina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: _createExercise,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<PlanExerciseDetail>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final details = snapshot.data ?? [];
          if (details.isEmpty) {
            return const Center(child: Text('Sin ejercicios'));
          }
          return ListView.builder(
            itemCount: details.length,
            itemBuilder: (_, i) {
              final d = details[i];
              final setsCtl = TextEditingController(text: d.sets.toString());
              final repsCtl = TextEditingController(text: d.reps.toString());
              final weightCtl = TextEditingController(text: d.weight.toString());
              final restCtl = TextEditingController(text: d.restSeconds.toString());
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editExercise(d.exerciseId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteDetail(d.exerciseId),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _numField('Sets', setsCtl),
                          const SizedBox(width: 8),
                          _numField('Reps', repsCtl),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _numField('Kg', weightCtl),
                          const SizedBox(width: 8),
                          _numField('Desc (s)', restCtl),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final newDetail = d.copyWith(
                              sets: int.tryParse(setsCtl.text) ?? d.sets,
                              reps: int.tryParse(repsCtl.text) ?? d.reps,
                              weight: double.tryParse(weightCtl.text) ?? d.weight,
                              restSeconds: int.tryParse(restCtl.text) ?? d.restSeconds,
                            );
                            _updateDetail(newDetail);
                          },
                          child: const Text('Guardar'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctl) {
    return Expanded(
      child: TextField(
        controller: ctl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
