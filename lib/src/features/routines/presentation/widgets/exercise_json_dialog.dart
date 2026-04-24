import 'package:flutter/material.dart';

class ExerciseJsonDialog extends StatelessWidget {
  final String title;
  final String initialJson;

  const ExerciseJsonDialog({
    super.key,
    required this.title,
    required this.initialJson,
  });

  @override
  Widget build(BuildContext context) {
    final jsonCtl = TextEditingController(text: initialJson);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.code, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: TextField(
        controller: jsonCtl,
        maxLines: 10,
        decoration: const InputDecoration(
          labelText: 'JSON del ejercicio',
          hintText:
              '{ "name": "Press Banca", "description": "Ejercicio compuesto para pecho", "category": "Fuerza", "mainMuscle": "Pecho" }',
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, jsonCtl.text),
          icon: const Icon(Icons.check),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
