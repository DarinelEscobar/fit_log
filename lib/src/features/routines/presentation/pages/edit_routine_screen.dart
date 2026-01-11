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
import '../widgets/exercise_json_dialog.dart';
import '../../services/routine_json_codec.dart';

class EditRoutineScreen extends ConsumerStatefulWidget {
  final int planId;
  const EditRoutineScreen({required this.planId, super.key});

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late Future<List<PlanExerciseDetail>> _future;
  final RoutineJsonCodec _jsonCodec = RoutineJsonCodec();

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
          title: Row(
            children: const [
              Icon(Icons.format_list_numbered, size: 20),
              SizedBox(width: 8),
              Text('Posición del ejercicio'),
            ],
          ),
          content: TextField(
            controller: posCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '1 = inicio'),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(
                context,
                int.tryParse(posCtl.text) ?? current.length + 1,
              ),
              icon: const Icon(Icons.check),
              label: const Text('OK'),
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
          rir: 2,
          tempo: '3-1-1-0',
        ),
        position: ((index ?? (current.length + 1)) - 1).clamp(0, current.length),
      );
      await _refresh();
    }
  }

  Future<void> _createExercise() async {
    final jsonTemplate = _jsonCodec.exerciseJson(
      Exercise(
        id: 0,
        name: 'Press Banca',
        description: 'Ejercicio compuesto para pecho',
        category: 'Fuerza',
        mainMuscleGroup: 'Pecho',
      ),
    );
    final jsonText = await showDialog<String>(
      context: context,
      builder: (_) => ExerciseJsonDialog(
        title: 'Nuevo ejercicio',
        initialJson: jsonTemplate,
      ),
    );

    if (jsonText != null) {
      final data = _jsonCodec.parseExerciseJson(jsonText);
      if (data == null) {
        _showJsonError('JSON inválido para el ejercicio.');
        return;
      }
      final repo = WorkoutPlanRepositoryImpl();
      await CreateExerciseUseCase(repo)(
        data.name,
        data.description,
        data.category,
        data.mainMuscleGroup,
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

    final jsonText = await showDialog<String>(
      context: context,
      builder: (_) => ExerciseJsonDialog(
        title: 'Editar ejercicio',
        initialJson: _jsonCodec.exerciseJson(ex),
      ),
    );

    if (jsonText != null) {
      final data = _jsonCodec.parseExerciseJson(jsonText);
      if (data == null) {
        _showJsonError('JSON inválido para el ejercicio.');
        return;
      }
      final repo = WorkoutPlanRepositoryImpl();
      await UpdateExerciseUseCase(repo)(
        ex.id,
        data.name,
        data.description,
        data.category,
        data.mainMuscleGroup,
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
              final jsonCtl = TextEditingController(
                text: _jsonCodec.detailJson(d),
              );
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
                      TextField(
                        controller: jsonCtl,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Parámetros JSON',
                          hintText:
                              '{ "sets": 3, "reps": 12, "kg": 12.5, "rest": 120, "rir": 2, "tempo": "3-1-1-0" }',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final parsed = _jsonCodec.parseDetailJson(
                              d,
                              jsonCtl.text,
                            );
                            if (parsed == null) {
                              _showJsonError('JSON inválido para parámetros.');
                              return;
                            }
                            _updateDetail(parsed);
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

  void _showJsonError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
