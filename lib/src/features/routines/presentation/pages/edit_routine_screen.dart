import 'dart:convert';
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
  final JsonEncoder _jsonEncoder = const JsonEncoder.withIndent('  ');

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
          tempo: '3-1-1-0',
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

    final jsonCtl = TextEditingController(text: _exerciseJson(ex));

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar ejercicio'),
        content: TextField(
          controller: jsonCtl,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'JSON del ejercicio',
            hintText: '{ "name": "...", "description": "...", "category": "...", "mainMuscle": "..." }',
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
      final data = _parseExerciseJson(jsonCtl.text);
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
              final jsonCtl = TextEditingController(text: _detailJson(d));
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
                            final parsed = _parseDetailJson(d, jsonCtl.text);
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

  String _detailJson(PlanExerciseDetail detail) => _jsonEncoder.convert({
        'sets': detail.sets,
        'reps': detail.reps,
        'kg': detail.weight,
        'rest': detail.restSeconds,
        'rir': detail.rir,
        'tempo': detail.tempo,
      });

  String _exerciseJson(Exercise exercise) => _jsonEncoder.convert({
        'name': exercise.name,
        'description': exercise.description,
        'category': exercise.category,
        'mainMuscle': exercise.mainMuscleGroup,
      });

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  PlanExerciseDetail? _parseDetailJson(
    PlanExerciseDetail base,
    String source,
  ) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      return base.copyWith(
        sets: _asInt(decoded['sets']) ?? base.sets,
        reps: _asInt(decoded['reps']) ?? base.reps,
        weight: _asDouble(decoded['kg']) ?? base.weight,
        restSeconds: _asInt(decoded['rest']) ?? base.restSeconds,
        rir: _asInt(decoded['rir']) ?? base.rir,
        tempo: decoded['tempo']?.toString() ?? base.tempo,
      );
    } on FormatException {
      return null;
    }
  }

  Exercise? _parseExerciseJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      final name = decoded['name']?.toString().trim() ?? '';
      final description = decoded['description']?.toString().trim() ?? '';
      final category = decoded['category']?.toString().trim() ?? '';
      final mainMuscle = decoded['mainMuscle']?.toString().trim() ?? '';
      if (name.isEmpty) return null;
      return Exercise(
        id: 0,
        name: name,
        description: description,
        category: category,
        mainMuscleGroup: mainMuscle,
      );
    } on FormatException {
      return null;
    }
  }

  void _showJsonError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
