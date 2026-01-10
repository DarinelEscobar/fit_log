import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/routine_json_parser.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/exercises_provider.dart';
import '../providers/workout_plan_provider.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/usecases/add_exercise_to_plan_usecase.dart';
import '../../domain/usecases/update_exercise_in_plan_usecase.dart';
import '../../domain/usecases/delete_exercise_from_plan_usecase.dart';
import '../../domain/usecases/create_exercise_usecase.dart';
import '../../domain/usecases/update_exercise_usecase.dart';
import '../../domain/usecases/update_workout_plan_name_usecase.dart';
import '../widgets/exercise_editor_dialog.dart';
import '../widgets/plan_exercise_card.dart';
import '../widgets/routine_json_import_dialog.dart';
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
          rir: 2,
        ),
        position: ((index ?? (current.length + 1)) - 1).clamp(0, current.length),
      );
      await _refresh();
    }
  }
  Future<void> _createExercise() async {
    final data = await ExerciseEditorDialog.show(
      context: context,
      title: 'Nuevo ejercicio',
      actionLabel: 'Guardar',
    );
    if (data == null) return;
    final repo = WorkoutPlanRepositoryImpl();
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
    final data = await ExerciseEditorDialog.show(
      context: context,
      title: 'Editar ejercicio',
      actionLabel: 'Guardar',
      initialData: ExerciseEditorDialogData(
        name: ex.name,
        description: ex.description,
        category: ex.category,
        mainMuscleGroup: ex.mainMuscleGroup,
      ),
    );
    if (data == null) return;
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
  Future<void> _importFromJson() async {
    final jsonText = await RoutineJsonImportDialog.show(context);
    if (jsonText == null || jsonText.trim().isEmpty) return;
    RoutineJsonPayload payload;
    try {
      payload = RoutineJsonParser.parse(jsonText);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON inválido: ${error.message}')),
      );
      return;
    }
    final allExercises = await ref.read(allExercisesProvider.future);
    final exerciseByName = {
      for (final e in allExercises) e.name.toLowerCase(): e,
    };
    final currentDetails =
        await ref.read(planExerciseDetailsProvider(widget.planId).future);
    final currentById = {
      for (final d in currentDetails) d.exerciseId: d,
    };
    final missing = <String>[];
    final newDetails = <PlanExerciseDetail>[];
    for (final item in payload.exercises) {
      final exercise = exerciseByName[item.name.toLowerCase()];
      if (exercise == null) {
        missing.add(item.name);
        continue;
      }
      final existing = currentById[exercise.id];
      newDetails.add(
        PlanExerciseDetail(
          exerciseId: exercise.id,
          name: exercise.name,
          description: exercise.description,
          sets: item.sets ?? existing?.sets ?? 3,
          reps: item.reps ?? existing?.reps ?? 10,
          weight: item.weight ?? existing?.weight ?? 0,
          restSeconds: item.restSeconds ?? existing?.restSeconds ?? 90,
          rir: item.rir ?? existing?.rir ?? 2,
        ),
      );
    }
    if (missing.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ejercicios no encontrados: ${missing.join(', ')}'),
        ),
      );
      return;
    }
    final repo = WorkoutPlanRepositoryImpl();
    if (payload.name != null && payload.name!.trim().isNotEmpty) {
      await UpdateWorkoutPlanNameUseCase(repo)(
        widget.planId,
        payload.name!.trim(),
      );
      ref.invalidate(workoutPlanProvider);
    }
    final newIds = newDetails.map((d) => d.exerciseId).toSet();
    final deleteUseCase = DeleteExerciseFromPlanUseCase(repo);
    for (final detail in currentDetails) {
      if (!newIds.contains(detail.exerciseId)) {
        await deleteUseCase(widget.planId, detail.exerciseId);
      }
    }
    final addUseCase = AddExerciseToPlanUseCase(repo);
    for (var i = 0; i < newDetails.length; i++) {
      await addUseCase(widget.planId, newDetails[i], position: i);
    }
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rutina actualizada desde JSON.')),
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
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _importFromJson,
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
              return PlanExerciseCard(
                detail: d,
                onEditExercise: () => _editExercise(d.exerciseId),
                onDeleteExercise: () => _deleteDetail(d.exerciseId),
                onSave: _updateDetail,
              );
            },
          );
        },
      ),
    );
  }
}
