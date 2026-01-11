import 'package:flutter/material.dart';

typedef FinishSessionResult = ({
  String energy,
  String mood,
  String notes,
});

class FinishSessionDialog extends StatefulWidget {
  final String? initialEnergy;
  final String? initialMood;
  final String? initialNotes;

  static Future<FinishSessionResult?> show(
    BuildContext context, {
    String? initialEnergy,
    String? initialMood,
    String? initialNotes,
  }) =>
      showDialog<FinishSessionResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => FinishSessionDialog(
          initialEnergy: initialEnergy,
          initialMood: initialMood,
          initialNotes: initialNotes,
        ),
      );

  const FinishSessionDialog({
    super.key,
    required this.initialEnergy,
    required this.initialMood,
    required this.initialNotes,
  });

  @override
  State<FinishSessionDialog> createState() => _FinishSessionDialogState();
}

class _FinishSessionDialogState extends State<FinishSessionDialog> {
  String? _energy;
  String? _mood;
  late final TextEditingController _notesCtl;

  static const List<String> _energyScale = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];
  static const List<String> _moodScale = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    _energy = widget.initialEnergy;
    _mood = widget.initialMood;
    _notesCtl = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canFinish = _energy != null && _mood != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Finalizar sesión'),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Energía (1-10)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            _buildChips(
              values: _energyScale,
              selected: _energy,
              onSelected: (value) => setState(() => _energy = value),
            ),
            const SizedBox(height: 16),
            const Text('Ánimo (1-5)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            _buildChips(
              values: _moodScale,
              selected: _mood,
              onSelected: (value) => setState(() => _mood = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Notas',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                focusedBorder:
                    OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: canFinish
              ? () => Navigator.of(context).pop((
                    energy: _energy!,
                    mood: _mood!,
                    notes: _notesCtl.text,
                  ))
              : null,
          child: const Text('Finalizar'),
        ),
      ],
    );
  }

  Widget _buildChips({
    required List<String> values,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) =>
      Wrap(
        spacing: 8,
        children: values
            .map(
              (value) => ChoiceChip(
                label: Text(value),
                selected: selected == value,
                selectedColor: Colors.amberAccent,
                onSelected: (_) => onSelected(value),
              ),
            )
            .toList(),
      );
}
