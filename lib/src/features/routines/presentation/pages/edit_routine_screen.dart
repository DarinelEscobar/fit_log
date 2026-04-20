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
  late Future<_EditorLoadResult> _future;
  late final TextEditingController _nameController;
  late final TextEditingController _frequencyController;
  List<RoutineEditorDraft>? _drafts;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _loadEditorData();
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
    final details =
        await ref.read(planExerciseDetailsProvider(widget.plan.id).future);
    final exercises = await ref.read(allExercisesProvider.future);
    return _EditorLoadResult(details: details, exercises: exercises);
  }

  Future<void> _refresh() async {
    _disposeDrafts();
    ref.invalidate(planExerciseDetailsProvider(widget.plan.id));
    ref.invalidate(exercisesForPlanProvider(widget.plan.id));
    ref.invalidate(allExercisesProvider);
    setState(() {
      _drafts = null;
      _future = _loadEditorData();
    });
  }

  Future<void> _saveAllChanges() async {
    if (_isSaving) return;
    final drafts = _drafts ?? const <RoutineEditorDraft>[];

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      await UpdateWorkoutPlanUseCase(repo)(
        widget.plan.id,
        _nameController.text.trim(),
        _frequencyController.text.trim(),
      );

      for (final draft in drafts) {
        if (draft.hasExerciseChanges) {
          final exercise = draft.buildExercise();
          await UpdateExerciseUseCase(repo)(
            exercise.id,
            exercise.name,
            exercise.description,
            exercise.category,
            exercise.mainMuscleGroup,
          );
        }
        if (draft.hasDetailChanges) {
          await UpdateExerciseInPlanUseCase(repo)(
            widget.plan.id,
            draft.buildDetail(),
          );
        }
      }

      ref.invalidate(workoutPlanProvider);
      await _refresh();
      if (!mounted) return;
      _showMessage('Routine changes saved');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to save changes: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addExistingExercise() async {
    final all = await ref.read(allExercisesProvider.future);
    if (!mounted) return;

    final exercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectExerciseScreen(
          groups: {for (final item in all) item.mainMuscleGroup},
        ),
      ),
    );
    if (exercise == null || !mounted) return;

    final position = await _pickInsertPosition((_drafts?.length ?? 0) + 1);
    if (position == null) return;

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
      position: (position - 1).clamp(0, _drafts?.length ?? 0),
    );

    await _refresh();
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

  Future<void> _createExercise() async {
    final input = await showDialog<ExerciseDefinitionInput>(
      context: context,
      builder: (_) => const ExerciseDefinitionDialog(),
    );
    if (input == null) return;

    final repo = ref.read(workoutPlanRepositoryProvider);
    await CreateExerciseUseCase(repo)(
      input.name,
      input.description,
      input.category,
      input.mainMuscleGroup,
    );
    ref.invalidate(allExercisesProvider);
    if (!mounted) return;
    _showMessage('Exercise created. Use Add Existing to include it.');
  }

  Future<void> _deleteExercise(int exerciseId) async {
    final repo = ref.read(workoutPlanRepositoryProvider);
    await DeleteExerciseFromPlanUseCase(repo)(widget.plan.id, exerciseId);
    await _refresh();
  }

  void _disposeDrafts() {
    final drafts = _drafts;
    if (drafts == null) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
                  _isSaving ? 'Saving...' : 'Save Changes',
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
        future: _future,
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
          final drafts = _drafts!;

          return ListView(
            key: const Key('routine-editor-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _MetadataSection(
                nameController: _nameController,
                frequencyController: _frequencyController,
              ),
              const SizedBox(height: 24),
              Row(
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
              const SizedBox(height: 16),
              if (drafts.isEmpty)
                const _EditorEmptyState()
              else
                for (final draft in drafts) ...[
                  RoutineEditorExerciseCard(
                    draft: draft,
                    onDelete: () => _deleteExercise(draft.exerciseId),
                  ),
                  const SizedBox(height: 14),
                ],
              const SizedBox(height: 14),
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
                  color:
                      KineticNoirPalette.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'DISCARD DRAFT',
                        textAlign: TextAlign.center,
                        style: KineticNoirTypography.body(
                          size: 12,
                          weight: FontWeight.w800,
                          color: KineticNoirPalette.onSurfaceVariant,
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
                        onPressed: _isSaving ? null : _saveAllChanges,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: KineticNoirPalette.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
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
          );
        },
      ),
    );
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
