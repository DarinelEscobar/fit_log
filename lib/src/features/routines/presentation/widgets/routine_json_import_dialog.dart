import 'package:flutter/material.dart';

class RoutineJsonImportDialog extends StatefulWidget {
  const RoutineJsonImportDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const RoutineJsonImportDialog(),
    );
  }

  @override
  State<RoutineJsonImportDialog> createState() => _RoutineJsonImportDialogState();
}

class _RoutineJsonImportDialogState extends State<RoutineJsonImportDialog> {
  static const _sampleJson = '''{
  "exercises": [
    {"name": "Barbell Overhead Press", "sets": 4, "reps": 8, "rir": 2, "kg": 25, "restSeconds": 150},
    {"name": "Incline Dumbbell Press", "sets": 4, "reps": 10, "rir": 2, "kg": 45}
  ]
}''';

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar ejercicios desde JSON'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText:
                    'Pega tu JSON aquí (solo actualiza ejercicios existentes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Ejemplo rápido:'),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                _sampleJson,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _controller.text = _sampleJson;
                setState(() {});
              },
              icon: const Icon(Icons.copy),
              label: const Text('Usar ejemplo'),
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
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
