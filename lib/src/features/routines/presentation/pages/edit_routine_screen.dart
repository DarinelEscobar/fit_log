import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/usecases/add_exercise_to_plan_usecase.dart';
import '../../domain/usecases/create_exercise_usecase.dart';
import '../../domain/usecases/delete_exercise_from_plan_usecase.dart';
import '../../domain/usecases/update_exercise_in_plan_usecase.dart';
import '../../domain/usecases/update_exercise_usecase.dart';
import '../../domain/usecases/update_workout_plan_usecase.dart';
import '../models/edit_routine_result.dart';
import '../models/routine_editor_draft.dart';
import '../providers/exercises_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import '../widgets/exercise_definition_dialog.dart';
import '../widgets/routine_editor_exercise_card.dart';
import 'select_exercise_screen.dart';

class EditRoutineScreen extends ConsumerStatefulWidget {
  const EditRoutineScreen({required this.plan, super.key});

  final WorkoutPlan plan;

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late Future<_EditorLoadResult> _loadFuture;
  late final TextEditingController _nameController;
  late final TextEditingController _frequencyController;
  late WorkoutPlan _currentPlan;

  List<RoutineEditorDraft>? _drafts;
  List<Exercise> _libraryExercises = const [];
  bool _didChangeMembership = false;
  bool _didCreateExercise = false;
  _EditorSaveState? _saveState;
  EditRoutineResult? _lastSavedResult;

  bool get _isSaving => _saveState != null;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.plan;
    _loadFuture = _loadEditorData();
    _nameController = TextEditingController(text: widget.plan.name);
    _frequencyController = TextEditingController(text: widget.plan.frequency);
  }

  @override
  void dispose() {
    _disposeDrafts();
    _nameController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<_EditorLoadResult> _loadEditorData() async {
    final results = await Future.wait([
      ref.read(planExerciseDetailsProvider(widget.plan.id).future),
      ref.read(allExercisesProvider.future),
    ]);

    return _EditorLoadResult(
      details: results[0] as List<PlanExerciseDetail>,
      exercises: results[1] as List<Exercise>,
    );
  }

  Future<void> _saveAllChanges() async {
    if (_isSaving || _drafts == null) {
      return;
    }

    final drafts = _drafts!;
    final planName = _nameController.text.trim();
    final frequency = _frequencyController.text.trim();
    final didChangePlan =
        planName != _currentPlan.name || frequency != _currentPlan.frequency;
    final exerciseChanges =
        drafts.where((draft) => draft.hasExerciseChanges).toList();
    final detailChanges =
        drafts.where((draft) => draft.hasDetailChanges).toList();
    final totalOperations =
        (didChangePlan ? 1 : 0) + exerciseChanges.length + detailChanges.length;

    if (totalOperations == 0) {
      _showMessage('No changes to save');
      return;
    }

    setState(() {
      _saveState = _EditorSaveState(
        completed: 0,
        total: totalOperations,
        label: 'Preparing changes',
      );
    });

    var completed = 0;

    try {
      final repo = ref.read(workoutPlanRepositoryProvider);

      if (didChangePlan) {
        _updateSaveState(
          completed: completed,
          total: totalOperations,
          label: 'Saving routine metadata',
        );
        await UpdateWorkoutPlanUseCase(repo)(
          _currentPlan.id,
          planName,
          frequency,
        );
        completed++;
        _updateSaveState(
          completed: completed,
          total: totalOperations,
          label: 'Routine metadata saved',
        );
      }

      for (final draft in exerciseChanges) {
        _updateSaveState(
          completed: completed,
          total: totalOperations,
          label: 'Saving ${draft.nameController.text.trim()}',
        );
        final exercise = draft.buildExercise();
        await UpdateExerciseUseCase(repo)(
          exercise.id,
          exercise.name,
          exercise.description,
          exercise.category,
          exercise.mainMuscleGroup,
        );
        completed++;
        _updateSaveState(
          completed: completed,
          total: totalOperations,
          label: '${draft.nameController.text.trim()} saved',
        );
      }

      for (final draft in detailChanges) {
        _updateSaveState(
          completed: completed,
          total: totalOperations,
          label: 'Updating programming',
        );
        await UpdateExerciseInPlanUseCase(repo)(
          _currentPlan.id,
          draft.buildDetail(),
        );
        completed++;
        _updateSaveState(
          completed: completed,
          total: totalOperations,
          label: 'Programming updated',
        );
      }

      _currentPlan = WorkoutPlan(
        id: _currentPlan.id,
        name: planName,
        frequency: frequency,
        isActive: _currentPlan.isActive,
      );
      _lastSavedResult = EditRoutineResult(plan: _currentPlan);

      for (final draft in drafts) {
        draft.commit();
      }

      await ref.read(workoutPlanProvider.notifier).refresh(silent: true);
      if (detailChanges.isNotEmpty || _didChangeMembership) {
        ref.invalidate(planExerciseDetailsProvider(_currentPlan.id));
      }
      if (_didChangeMembership) {
        ref.invalidate(exercisesForPlanProvider(_currentPlan.id));
      }
      if (exerciseChanges.isNotEmpty || _didCreateExercise) {
        ref.invalidate(allExercisesProvider);
      }
      if (exerciseChanges.isNotEmpty || _didChangeMembership) {
        ref.read(routineLibraryMetadataEpochProvider.notifier).state++;
      }

      _didChangeMembership = false;
      _didCreateExercise = false;

      if (!mounted) {
        return;
      }
      _showMessage('Routine changes saved');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to save changes: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saveState = null;
        });
      }
    }
  }

  Future<void> _addExistingExercise() async {
    if (_drafts == null || _isSaving) {
      return;
    }

    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(
          groups: {for (final item in _libraryExercises) item.mainMuscleGroup},
          initialExercises: _libraryExercises,
        ),
      ),
    );
    if (exercise == null || !mounted) {
      return;
    }

    final position = await _pickInsertPosition(_drafts!.length + 1);
    if (position == null) {
      return;
    }

    final detail = PlanExerciseDetail(
      exerciseId: exercise.id,
      name: exercise.name,
      description: exercise.description,
      sets: 3,
      reps: 10,
      weight: 0,
      restSeconds: 90,
      rir: 2,
      tempo: '3-1-1-0',
    );

    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      await AddExerciseToPlanUseCase(repo)(
        _currentPlan.id,
        detail,
        position: (position - 1).clamp(0, _drafts!.length),
      );

      final nextDraft = RoutineEditorDraft(
        originalExercise: exercise,
        originalDetail: detail,
      );

      setState(() {
        final drafts = _drafts!;
        final existingIndex = drafts.indexWhere(
          (draft) => draft.exerciseId == exercise.id,
        );
        var insertIndex = (position - 1).clamp(0, drafts.length);
        if (existingIndex != -1) {
          drafts.removeAt(existingIndex).dispose();
          if (existingIndex < insertIndex) {
            insertIndex--;
          }
        }
        drafts.insert(insertIndex, nextDraft);
        _didChangeMembership = true;
      });

      ref.invalidate(planExerciseDetailsProvider(_currentPlan.id));
      ref.invalidate(exercisesForPlanProvider(_currentPlan.id));
      ref.read(routineLibraryMetadataEpochProvider.notifier).state++;
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to add exercise: $error', isError: true);
    }
  }

  Future<void> _createExercise() async {
    if (_isSaving) {
      return;
    }

    final input = await showDialog<ExerciseDefinitionInput>(
      context: context,
      builder: (_) => const ExerciseDefinitionDialog(),
    );
    if (input == null) {
      return;
    }

    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      await CreateExerciseUseCase(repo)(
        input.name,
        input.description,
        input.category,
        input.mainMuscleGroup,
      );
      ref.invalidate(allExercisesProvider);
      final updatedExercises = await ref.read(allExercisesProvider.future);
      if (!mounted) {
        return;
      }
      setState(() {
        _libraryExercises = updatedExercises;
        _didCreateExercise = true;
      });
      _showMessage('Exercise created. Use Add Existing to include it.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to create exercise: $error', isError: true);
    }
  }

  Future<void> _deleteExercise(int exerciseId) async {
    if (_drafts == null || _isSaving) {
      return;
    }

    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      await DeleteExerciseFromPlanUseCase(repo)(_currentPlan.id, exerciseId);

      setState(() {
        final index = _drafts!.indexWhere(
          (draft) => draft.exerciseId == exerciseId,
        );
        if (index != -1) {
          _drafts!.removeAt(index).dispose();
        }
        _didChangeMembership = true;
      });

      ref.invalidate(planExerciseDetailsProvider(_currentPlan.id));
      ref.invalidate(exercisesForPlanProvider(_currentPlan.id));
      ref.read(routineLibraryMetadataEpochProvider.notifier).state++;
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to delete exercise: $error', isError: true);
    }
  }

  Future<int?> _pickInsertPosition(int suggestedPosition) async {
    final controller = TextEditingController(text: '$suggestedPosition');
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: KineticNoirPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INSERT POSITION',
                style: KineticNoirTypography.headline(
                  size: 24,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose where the exercise should appear inside the routine.',
                style: KineticNoirTypography.body(
                  size: 14,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: KineticNoirTypography.headline(
                  size: 28,
                  weight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'Position',
                  filled: true,
                  fillColor: KineticNoirPalette.surfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      int.tryParse(controller.text.trim()) ?? suggestedPosition,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: KineticNoirPalette.primary,
                    foregroundColor: KineticNoirPalette.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Insert',
                    style: KineticNoirTypography.body(
                      size: 14,
                      weight: FontWeight.w800,
                      color: KineticNoirPalette.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _closeEditor() {
    Navigator.pop(context, _lastSavedResult);
  }

  void _disposeDrafts() {
    final drafts = _drafts;
    if (drafts == null) {
      return;
    }
    for (final draft in drafts) {
      draft.dispose();
    }
  }

  List<RoutineEditorDraft> _buildDrafts(_EditorLoadResult data) {
    final exerciseMap = {
      for (final exercise in data.exercises) exercise.id: exercise,
    };
    return data.details
        .map(
          (detail) => RoutineEditorDraft(
            originalExercise: exerciseMap[detail.exerciseId] ??
                Exercise(
                  id: detail.exerciseId,
                  name: detail.name,
                  description: detail.description,
                  category: '',
                  mainMuscleGroup: '',
                ),
            originalDetail: detail,
          ),
        )
        .toList();
  }

  void _updateSaveState({
    required int completed,
    required int total,
    required String label,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _saveState = _EditorSaveState(
        completed: completed,
        total: total,
        label: label,
      );
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? KineticNoirPalette.error
            : KineticNoirPalette.surfaceBright,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _closeEditor,
          icon: const Icon(Icons.arrow_back_rounded),
          color: KineticNoirPalette.primary,
        ),
        title: Text(
          'ROUTINE EDITOR',
          key: const Key('routine-editor-title'),
          style: KineticNoirTypography.headline(
            size: 22,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: kineticPrimaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: FilledButton(
                onPressed: _isSaving ? null : _saveAllChanges,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: KineticNoirPalette.onPrimary,
                ),
                child: Text(
                  _isSaving
                      ? '${_saveState!.completed}/${_saveState!.total}'
                      : 'Save Changes',
                  style: KineticNoirTypography.body(
                    size: 12,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.onPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_EditorLoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child:
                  CircularProgressIndicator(color: KineticNoirPalette.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load routine editor.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: KineticNoirTypography.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          _drafts ??= _buildDrafts(data);
          if (_libraryExercises.isEmpty) {
            _libraryExercises = List<Exercise>.from(data.exercises);
          }

          final drafts = _drafts!;
          final compactLayout = MediaQuery.sizeOf(context).width > 430;

          return Stack(
            children: [
              AbsorbPointer(
                absorbing: _isSaving,
                child: CustomScrollView(
                  key: const Key('routine-editor-scroll'),
                  cacheExtent: 700,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _MetadataSection(
                          nameController: _nameController,
                          frequencyController: _frequencyController,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.format_list_numbered_rounded,
                              color: KineticNoirPalette.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'EXERCISES',
                              style: KineticNoirTypography.headline(
                                size: 18,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: KineticNoirPalette.surface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${drafts.length} ITEMS',
                                style: KineticNoirTypography.body(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: KineticNoirPalette.onSurfaceVariant,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (drafts.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(child: _EditorEmptyState()),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final draft = drafts[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == drafts.length - 1 ? 0 : 14,
                                ),
                                child: RepaintBoundary(
                                  child: RoutineEditorExerciseCard(
                                    key: ValueKey(draft.exerciseId),
                                    compactLayout: compactLayout,
                                    draft: draft,
                                    onDelete: () =>
                                        _deleteExercise(draft.exerciseId),
                                  ),
                                ),
                              );
                            },
                            childCount: drafts.length,
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _EditorActionCard(
                              icon: Icons.library_add_rounded,
                              title: 'Add Existing',
                              subtitle: 'Select from library',
                              color: KineticNoirPalette.primary,
                              onTap: _addExistingExercise,
                            ),
                            const SizedBox(height: 12),
                            _EditorActionCard(
                              icon: Icons.add_circle_rounded,
                              title: 'Create New',
                              subtitle: 'Define new exercise',
                              color: const Color(0xFFE197FC),
                              onTap: _createExercise,
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: Container(
                                height: 1,
                                width: 96,
                                color: KineticNoirPalette.outlineVariant
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _closeEditor,
                                    child: Text(
                                      'DISCARD DRAFT',
                                      textAlign: TextAlign.center,
                                      style: KineticNoirTypography.body(
                                        size: 12,
                                        weight: FontWeight.w800,
                                        color:
                                            KineticNoirPalette.onSurfaceVariant,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: kineticPrimaryGradient,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: FilledButton(
                                      key: const Key('routine-editor-save'),
                                      onPressed:
                                          _isSaving ? null : _saveAllChanges,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor:
                                            KineticNoirPalette.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      child: Text(
                                        'COMPLETE SETUP',
                                        style: KineticNoirTypography.body(
                                          size: 12,
                                          weight: FontWeight.w800,
                                          color: KineticNoirPalette.onPrimary,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_saveState != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.42),
                    child: Center(
                      child: Container(
                        key: const Key('routine-editor-saving-overlay'),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                        decoration: BoxDecoration(
                          color: KineticNoirPalette.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: KineticNoirPalette.outlineVariant
                                .withValues(alpha: 0.24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: KineticNoirPalette.primary,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '${_saveState!.completed}/${_saveState!.total}',
                              style: KineticNoirTypography.headline(
                                size: 30,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _saveState!.label,
                              textAlign: TextAlign.center,
                              style: KineticNoirTypography.body(
                                size: 14,
                                weight: FontWeight.w600,
                                color: KineticNoirPalette.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({
    required this.nameController,
    required this.frequencyController,
  });

  final TextEditingController nameController;
  final TextEditingController frequencyController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          left: BorderSide(color: KineticNoirPalette.primary, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          _EditorField(
            label: 'Routine Name',
            controller: nameController,
            style: KineticNoirTypography.headline(
              size: 28,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _EditorField(
            label: 'Frequency',
            controller: frequencyController,
            suffix: const Icon(
              Icons.event_repeat_rounded,
              color: KineticNoirPalette.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.label,
    required this.controller,
    this.style,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final TextStyle? style;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: KineticNoirTypography.body(
            size: 10,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: style ??
                    KineticNoirTypography.body(
                      size: 18,
                      weight: FontWeight.w600,
                    ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: KineticNoirPalette.outlineVariant
                          .withValues(alpha: 0.45),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: KineticNoirPalette.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 10),
              suffix!,
            ],
          ],
        ),
      ],
    );
  }
}

class _EditorActionCard extends StatelessWidget {
  const _EditorActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: KineticNoirPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KineticNoirTypography.headline(
                        size: 20,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.toUpperCase(),
                      style: KineticNoirTypography.body(
                        size: 10,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorEmptyState extends StatelessWidget {
  const _EditorEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.playlist_remove_rounded,
            size: 34,
            color: KineticNoirPalette.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No exercises programmed yet',
            style: KineticNoirTypography.headline(
              size: 24,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the actions below to add existing library items or create a new exercise entry.',
            textAlign: TextAlign.center,
            style: KineticNoirTypography.body(
              size: 14,
              weight: FontWeight.w600,
              color: KineticNoirPalette.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorLoadResult {
  const _EditorLoadResult({
    required this.details,
    required this.exercises,
  });

  final List<PlanExerciseDetail> details;
  final List<Exercise> exercises;
}

class _EditorSaveState {
  const _EditorSaveState({
    required this.completed,
    required this.total,
    required this.label,
  });

  final int completed;
  final int total;
  final String label;
}
