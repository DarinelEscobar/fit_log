import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/usecases/add_exercise_to_plan_usecase.dart';
import '../../domain/usecases/create_exercise_usecase.dart';
import '../../domain/usecases/delete_exercise_from_plan_usecase.dart';
import '../../domain/usecases/update_exercise_in_plan_usecase.dart';
import '../../domain/usecases/update_exercise_usecase.dart';
import '../../domain/usecases/update_workout_plan_usecase.dart';
import '../../services/routine_json_codec.dart';
import '../providers/exercises_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import '../widgets/exercise_json_dialog.dart';
import 'select_exercise_screen.dart';

class EditRoutineScreen extends ConsumerStatefulWidget {
  final WorkoutPlan plan;

  const EditRoutineScreen({required this.plan, super.key});

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late Future<List<PlanExerciseDetail>> _future;
  late final TextEditingController _nameController;
  late final TextEditingController _frequencyController;
  final RoutineJsonCodec _jsonCodec = RoutineJsonCodec();
  bool _isSavingRoutine = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(planExerciseDetailsProvider(widget.plan.id).future);
    _nameController = TextEditingController(text: widget.plan.name);
    _frequencyController = TextEditingController(text: widget.plan.frequency);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = planExerciseDetailsProvider(widget.plan.id);
    ref.invalidate(provider);
    setState(() {
      _future = ref.read(provider.future);
    });
  }

  Future<void> _saveRoutineInfo() async {
    setState(() => _isSavingRoutine = true);

    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      await UpdateWorkoutPlanUseCase(repo)(
        widget.plan.id,
        _nameController.text.trim(),
        _frequencyController.text.trim(),
      );
      ref.invalidate(workoutPlanProvider);
      _showMessage('Datos de la rutina guardados');
    } catch (error) {
      _showMessage('Error al guardar la rutina: $error');
    } finally {
      if (mounted) {
        setState(() => _isSavingRoutine = false);
      }
    }
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

    if (exercise == null) return;

    final current = await ref.read(planExerciseDetailsProvider(widget.plan.id).future);
    final posCtl = TextEditingController(text: '${current.length + 1}');
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

    final repo = ref.read(workoutPlanRepositoryProvider);
    await AddExerciseToPlanUseCase(repo)(
      widget.plan.id,
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

    if (jsonText == null) return;

    final data = _jsonCodec.parseExerciseJson(jsonText);
    if (data == null) {
      _showMessage('JSON inválido para el ejercicio.');
      return;
    }

    final repo = ref.read(workoutPlanRepositoryProvider);
    await CreateExerciseUseCase(repo)(
      data.name,
      data.description,
      data.category,
      data.mainMuscleGroup,
    );
    ref.invalidate(allExercisesProvider);
  }

  Future<void> _editExercise(int exerciseId) async {
    final all = await ref.read(allExercisesProvider.future);
    final exercise = all.firstWhere(
      (item) => item.id == exerciseId,
      orElse: () => Exercise(
        id: 0,
        name: '',
        description: '',
        category: '',
        mainMuscleGroup: '',
      ),
    );
    if (exercise.id == 0) return;

    final jsonText = await showDialog<String>(
      context: context,
      builder: (_) => ExerciseJsonDialog(
        title: 'Editar ejercicio',
        initialJson: _jsonCodec.exerciseJson(exercise),
      ),
    );

    if (jsonText == null) return;

    final data = _jsonCodec.parseExerciseJson(jsonText);
    if (data == null) {
      _showMessage('JSON inválido para el ejercicio.');
      return;
    }

    final repo = ref.read(workoutPlanRepositoryProvider);
    await UpdateExerciseUseCase(repo)(
      exercise.id,
      data.name,
      data.description,
      data.category,
      data.mainMuscleGroup,
    );
    ref.invalidate(allExercisesProvider);
    await _refresh();
  }

  Future<void> _updateDetail(PlanExerciseDetail detail) async {
    final repo = ref.read(workoutPlanRepositoryProvider);
    await UpdateExerciseInPlanUseCase(repo)(widget.plan.id, detail);
    await _refresh();
  }

  Future<void> _deleteDetail(int exerciseId) async {
    final repo = ref.read(workoutPlanRepositoryProvider);
    await DeleteExerciseFromPlanUseCase(repo)(widget.plan.id, exerciseId);
    await _refresh();
  }

  Widget _buildRoutineInfoSection() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos de la rutina',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de rutina'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _frequencyController,
              decoration: const InputDecoration(labelText: 'Frecuencia'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSavingRoutine ? null : _saveRoutineInfo,
                icon: _isSavingRoutine
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar datos de la rutina'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsList(List<PlanExerciseDetail> details) {
    if (details.isEmpty) {
      return const Center(child: Text('Sin ejercicios'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: details.length,
      itemBuilder: (_, i) {
        final detail = details[i];
        final jsonCtl = TextEditingController(text: _jsonCodec.detailJson(detail));

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editExercise(detail.exerciseId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteDetail(detail.exerciseId),
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
                        detail,
                        jsonCtl.text,
                      );
                      if (parsed == null) {
                        _showMessage('JSON inválido para parámetros.');
                        return;
                      }
                      _updateDetail(parsed);
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      body: Column(
        children: [
          _buildRoutineInfoSection(),
          Expanded(
            child: FutureBuilder<List<PlanExerciseDetail>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return _buildDetailsList(snapshot.data ?? []);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
