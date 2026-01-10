import 'package:flutter/material.dart';

class ExerciseEditorDialogData {
  final String name;
  final String description;
  final String category;
  final String mainMuscleGroup;

  const ExerciseEditorDialogData({
    required this.name,
    required this.description,
    required this.category,
    required this.mainMuscleGroup,
  });
}

class ExerciseEditorDialog extends StatefulWidget {
  const ExerciseEditorDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.initialData,
  });

  final String title;
  final String actionLabel;
  final ExerciseEditorDialogData? initialData;

  static Future<ExerciseEditorDialogData?> show({
    required BuildContext context,
    required String title,
    required String actionLabel,
    ExerciseEditorDialogData? initialData,
  }) {
    return showDialog<ExerciseEditorDialogData>(
      context: context,
      builder: (_) => ExerciseEditorDialog(
        title: title,
        actionLabel: actionLabel,
        initialData: initialData,
      ),
    );
  }

  @override
  State<ExerciseEditorDialog> createState() => _ExerciseEditorDialogState();
}

class _ExerciseEditorDialogState extends State<ExerciseEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _groupController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialData?.description ?? '');
    _categoryController =
        TextEditingController(text: widget.initialData?.category ?? '');
    _groupController = TextEditingController(
        text: widget.initialData?.mainMuscleGroup ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            TextField(
              controller: _groupController,
              decoration:
                  const InputDecoration(labelText: 'Músculo principal'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              ExerciseEditorDialogData(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                category: _categoryController.text.trim(),
                mainMuscleGroup: _groupController.text.trim(),
              ),
            );
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
