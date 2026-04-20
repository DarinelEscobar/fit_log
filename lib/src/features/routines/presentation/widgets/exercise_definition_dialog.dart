import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';

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
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _muscleController;
  late final TextEditingController _descriptionController;

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
            _ExerciseField(
              controller: _nameController,
              label: 'Exercise Name',
              hintText: 'Incline Dumbbell Press',
            ),
            const SizedBox(height: 14),
            _ExerciseField(
              controller: _categoryController,
              label: 'Category',
              hintText: 'Strength',
            ),
            const SizedBox(height: 14),
            _ExerciseField(
              controller: _muscleController,
              label: 'Primary Muscle',
              hintText: 'Upper Chest',
            ),
            const SizedBox(height: 14),
            _ExerciseField(
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
}

class _ExerciseField extends StatelessWidget {
  const _ExerciseField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final int maxLines;

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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          style: KineticNoirTypography.body(size: 15, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
