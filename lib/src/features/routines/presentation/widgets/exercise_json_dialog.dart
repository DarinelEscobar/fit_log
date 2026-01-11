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

    return AlertDialog(
      title: Text(title),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, jsonCtl.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
