import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/usecases/add_exercise_to_plan_usecase.dart';
import '../../domain/usecases/create_exercise_usecase.dart';
import '../../domain/usecases/delete_exercise_from_plan_usecase.dart';
import '../../domain/usecases/update_exercise_in_plan_usecase.dart';
import '../../domain/usecases/update_workout_plan_usecase.dart';
import '../../domain/usecases/create_workout_plan_usecase.dart';
import '../providers/exercises_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import 'select_exercise_screen.dart';
import '../../services/routine_json_codec.dart';
import '../widgets/exercise_json_dialog.dart';

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
  bool _isSavingRoutine = false;
  final _jsonCodec = RoutineJsonCodec();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan.name);
    _frequencyController = TextEditingController(text: widget.plan.frequency);
    _refresh();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (widget.plan.id == 0) {
      _future = Future.value([]);
    } else {
      _future = ref.read(planExerciseDetailsProvider(widget.plan.id).future);
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveRoutineInfo({bool closeOnSave = false}) async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('El nombre no puede estar vacío');
      return;
    }
    setState(() => _isSavingRoutine = true);
    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      if (widget.plan.id == 0) {
        await CreateWorkoutPlanUseCase(repo)(
          _nameController.text.trim(),
          _frequencyController.text.trim(),
        );
        ref.invalidate(workoutPlanProvider);
        if (mounted) {
           _showMessage('Rutina creada exitosamente. Regresa y edita para agregar ejercicios.');
           if (closeOnSave) Navigator.pop(context);
        }
        return;
      }

      await UpdateWorkoutPlanUseCase(repo)(
        widget.plan.id,
        _nameController.text.trim(),
        _frequencyController.text.trim(),
      );
      ref.invalidate(workoutPlanProvider);
      _showMessage('Datos de la rutina guardados');
      if (mounted && closeOnSave) Navigator.pop(context);
    } catch (error) {
      _showMessage('Error al guardar la rutina: $error');
    } finally {
      if (mounted) {
        setState(() => _isSavingRoutine = false);
      }
    }
  }

  Future<void> _addExercise() async {
    if (widget.plan.id == 0) {
        _showMessage('Guarda la rutina primero para poder agregar ejercicios.');
        return;
    }
    final all = await ref.read(allExercisesProvider.future);
    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(
          groups: {for (var e in all) e.mainMuscleGroup},
        ),
      ),
    );

    if (exercise == null || !mounted) return;

    final current = await ref.read(planExerciseDetailsProvider(widget.plan.id).future);

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
      position: current.length,
    );
    await _refresh();
  }

  Future<void> _createExercise() async {
    final jsonTemplate = _jsonCodec.exerciseJson(
      Exercise(
        id: 0,
        name: 'Nuevo Ejercicio',
        description: 'Descripción breve',
        category: 'Fuerza',
        mainMuscleGroup: 'Pecho',
      ),
    );
    if (!mounted) return;
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

  Future<void> _updateDetail(PlanExerciseDetail detail, PlanExerciseDetail newDetail) async {
    final repo = ref.read(workoutPlanRepositoryProvider);
    await UpdateExerciseInPlanUseCase(repo)(widget.plan.id, newDetail);
    // No full refresh to keep UX smooth, provider handles the update when invalidated
  }

  Future<void> _deleteDetail(int exerciseId) async {
    final repo = ref.read(workoutPlanRepositoryProvider);
    await DeleteExerciseFromPlanUseCase(repo)(widget.plan.id, exerciseId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFCC97FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ROUTINE EDITOR',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFFCC97FF),
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: _isSavingRoutine ? null : _saveRoutineInfo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC97FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSavingRoutine
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF47007C)),
                        )
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFF47007C),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<PlanExerciseDetail>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final details = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131314),
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFCC97FF), width: 4),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ROUTINE NAME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Color(0xFFADAAAB),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter routine name...',
                                    hintStyle: TextStyle(color: Color(0xFF484849)),
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF484849))),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF484849))),
                                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCC97FF))),
                                    contentPadding: EdgeInsets.only(bottom: 8),
                                    fillColor: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FREQUENCY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Color(0xFFADAAAB),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _frequencyController,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                        decoration: const InputDecoration(
                                          border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF484849))),
                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF484849))),
                                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCC97FF))),
                                          contentPadding: EdgeInsets.only(bottom: 8),
                                          fillColor: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.event_repeat, color: Color(0xFF767576)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                if (widget.plan.id != 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.format_list_numbered, color: Color(0xFFCC97FF)),
                          SizedBox(width: 8),
                          Text(
                            'EXERCISES',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A191B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${details.length} ITEMS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFFADAAAB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ...details.map((detail) {
                    final setsCtl = TextEditingController(text: '${detail.sets}');
                    final repsCtl = TextEditingController(text: '${detail.reps}');
                    final weightCtl = TextEditingController(text: '${detail.weight}');
                    final restCtl = TextEditingController(text: '${detail.restSeconds}');
                    final rirCtl = TextEditingController(text: '${detail.rir}');
                    final tempoCtl = TextEditingController(text: detail.tempo);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A191B),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.2),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: const Border(
                          left: BorderSide(color: Colors.transparent, width: 2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            padding: const EdgeInsets.only(top: 24),
                            alignment: Alignment.topCenter,
                            decoration: const BoxDecoration(
                              color: Color(0xFF201F21),
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                            ),
                            child: const Icon(Icons.drag_indicator, color: Color(0xFF767576)),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              detail.name,
                                              style: const TextStyle(
                                                fontFamily: 'Space Grotesk',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'EXERCISE',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                                color: Color(0xFFADAAAB),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Color(0xFF767576)),
                                        onPressed: () => _deleteDetail(detail.exerciseId),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(child: _buildParamInput('SETS', setsCtl, isHighlight: true, onChanged: (v) => _updateDetail(detail, detail.copyWith(sets: int.tryParse(v) ?? detail.sets)))),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildParamInput('REPS', repsCtl, isHighlight: true, onChanged: (v) => _updateDetail(detail, detail.copyWith(reps: int.tryParse(v) ?? detail.reps)))),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildParamInput('WEIGHT', weightCtl, isHighlight: true, onChanged: (v) => _updateDetail(detail, detail.copyWith(weight: double.tryParse(v) ?? detail.weight)))),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _buildParamInput('REST(s)', restCtl, isHighlight: false, onChanged: (v) => _updateDetail(detail, detail.copyWith(restSeconds: int.tryParse(v) ?? detail.restSeconds)))),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildParamInput('RIR', rirCtl, isHighlight: false, isTertiary: true, onChanged: (v) => _updateDetail(detail, detail.copyWith(rir: int.tryParse(v) ?? detail.rir)))),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildParamInput('TEMPO', tempoCtl, isHighlight: false, isString: true, onChanged: (v) => _updateDetail(detail, detail.copyWith(tempo: v)))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _addExercise,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF201F21),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCC97FF).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.library_add, color: Color(0xFFCC97FF)),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Add Existing', style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text('SELECT FROM LIBRARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFADAAAB))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _createExercise,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF201F21),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3DD6C6).withValues(alpha: 0.2), // secondary container approx
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_circle, color: Color(0xFF3DD6C6)),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Create New', style: TextStyle(fontFamily: 'Space Grotesk', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text('DEFINE NEW EXERCISE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFADAAAB))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 64),

                  Column(
                    children: [
                      Container(
                        height: 1,
                        width: 96,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFF484849), Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => _saveRoutineInfo(closeOnSave: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFCC97FF), Color(0xFF9C48EA)]),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(132, 44, 211, 0.2), blurRadius: 32, offset: Offset(0, 12))],
                          ),
                          child: const Text('COMPLETE SETUP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF47007C))),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParamInput(String label, TextEditingController controller, {required bool isHighlight, bool isTertiary = false, bool isString = false, required Function(String) onChanged}) {
    Color textColor = Colors.white;
    if (isHighlight) textColor = const Color(0xFFCC97FF);
    if (isTertiary) textColor = const Color(0xFFFF95A0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131314),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF484849))),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: isString ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
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
