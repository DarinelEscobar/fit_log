import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/exercise.dart';
import '../../services/routine_json_codec.dart';
import 'exercise_definition_form_widgets.dart';

class ExerciseDefinitionInput {
  const ExerciseDefinitionInput({
    required this.name,
    required this.category,
    required this.mainMuscleGroup,
    required this.description,
  });

  final String name;
  final String category;
  final String mainMuscleGroup;
  final String description;
}

class ExerciseDefinitionDialog extends StatefulWidget {
  const ExerciseDefinitionDialog({super.key});

  @override
  State<ExerciseDefinitionDialog> createState() =>
      _ExerciseDefinitionDialogState();
}

class _ExerciseDefinitionDialogState extends State<ExerciseDefinitionDialog> {
  final RoutineJsonCodec _jsonCodec = RoutineJsonCodec();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _muscleController;
  late final TextEditingController _descriptionController;
  bool _didCopyPrompt = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _categoryController = TextEditingController();
    _muscleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _muscleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KineticNoirPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CREATE EXERCISE',
              style: KineticNoirTypography.headline(
                size: 24,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a new library exercise using the existing repository flow.',
              style: KineticNoirTypography.body(
                size: 14,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ExerciseDefinitionField(
              fieldKey: const Key('exercise-definition-name'),
              controller: _nameController,
              label: 'Exercise Name',
              hintText: 'Incline Dumbbell Press',
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameController,
              builder: (context, value, _) {
                final exerciseName = value.text.trim();
                final hasName = exerciseName.isNotEmpty;
                return ExerciseDefinitionJsonActions(
                  canCopyPrompt: hasName,
                  canPasteJson: hasName && _didCopyPrompt,
                  onCopyPrompt:
                      hasName ? () => _copyExercisePrompt(exerciseName) : null,
                  onPasteJson:
                      hasName && _didCopyPrompt ? _pasteExerciseJson : null,
                );
              },
            ),
            const SizedBox(height: 14),
            ExerciseDefinitionField(
              fieldKey: const Key('exercise-definition-category'),
              controller: _categoryController,
              label: 'Category',
              hintText: 'Strength',
            ),
            const SizedBox(height: 14),
            ExerciseDefinitionField(
              fieldKey: const Key('exercise-definition-muscle'),
              controller: _muscleController,
              label: 'Primary Muscle',
              hintText: 'Upper Chest',
            ),
            const SizedBox(height: 14),
            ExerciseDefinitionField(
              fieldKey: const Key('exercise-definition-description'),
              controller: _descriptionController,
              label: 'Description',
              hintText: 'Brief movement cues or intent.',
              minLines: 3,
              maxLines: 4,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: KineticNoirTypography.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kineticPrimaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        ExerciseDefinitionInput(
                          name: _nameController.text.trim(),
                          category: _categoryController.text.trim(),
                          mainMuscleGroup: _muscleController.text.trim(),
                          description: _descriptionController.text.trim(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: KineticNoirPalette.onPrimary,
                    ),
                    child: Text(
                      'Create',
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
          ],
        ),
      ),
    );
  }

  Future<void> _copyExercisePrompt(String exerciseName) async {
    await Clipboard.setData(
      ClipboardData(text: _buildExercisePrompt(exerciseName)),
    );

    if (!mounted) {
      return;
    }

    setState(() => _didCopyPrompt = true);
    _showMessage('Prompt copied. Paste the guide JSON when ready.');
  }

  Future<void> _pasteExerciseJson() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) {
      return;
    }

    final source = clipboardData?.text?.trim() ?? '';
    final exercise = _jsonCodec.parseExerciseJson(source);

    if (exercise == null || !_hasCompleteExerciseData(exercise)) {
      _showMessage(
        'Paste a valid exercise JSON with name, category, mainMuscleGroup, and description.',
        isError: true,
      );
      return;
    }

    setState(() {
      _nameController.text = exercise.name;
      _categoryController.text = exercise.category;
      _muscleController.text = exercise.mainMuscleGroup;
      _descriptionController.text = exercise.description;
    });
    _showMessage('Exercise JSON applied.');
  }

  bool _hasCompleteExerciseData(Exercise exercise) {
    return exercise.name.trim().isNotEmpty &&
        exercise.category.trim().isNotEmpty &&
        exercise.mainMuscleGroup.trim().isNotEmpty &&
        exercise.description.trim().isNotEmpty;
  }

  String _buildExercisePrompt(String exerciseName) {
    return '''
Create concise exercise metadata for a fitness tracking app.

Exercise name: "$exerciseName"

Return valid JSON only. Do not include Markdown, code fences, comments, or explanations.
Use English values and fill these exact keys:
{
  "name": "$exerciseName",
  "category": "Strength or another short category",
  "mainMuscleGroup": "Primary muscle group",
  "description": "1-2 short sentences explaining how to perform it with useful cues."
}

Keep the description practical and concise.
'''
        .trim();
  }

  void _showMessage(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? KineticNoirPalette.error
            : KineticNoirPalette.surfaceBright,
        content: Text(message),
      ),
    );
  }
}
