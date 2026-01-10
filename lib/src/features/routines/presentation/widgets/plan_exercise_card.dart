import 'package:flutter/material.dart';
import '../../domain/entities/plan_exercise_detail.dart';

class PlanExerciseCard extends StatefulWidget {
  const PlanExerciseCard({
    super.key,
    required this.detail,
    required this.onEditExercise,
    required this.onDeleteExercise,
    required this.onSave,
  });

  final PlanExerciseDetail detail;
  final VoidCallback onEditExercise;
  final VoidCallback onDeleteExercise;
  final ValueChanged<PlanExerciseDetail> onSave;

  @override
  State<PlanExerciseCard> createState() => _PlanExerciseCardState();
}

class _PlanExerciseCardState extends State<PlanExerciseCard> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _restController;
  late final TextEditingController _rirController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController();
    _repsController = TextEditingController();
    _weightController = TextEditingController();
    _restController = TextEditingController();
    _rirController = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant PlanExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _rirController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _setsController.text = widget.detail.sets.toString();
    _repsController.text = widget.detail.reps.toString();
    _weightController.text = widget.detail.weight.toString();
    _restController.text = widget.detail.restSeconds.toString();
    _rirController.text = widget.detail.rir.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.detail.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: widget.onEditExercise,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onDeleteExercise,
                ),
              ],
            ),
            Row(
              children: [
                _numField('Sets', _setsController),
                const SizedBox(width: 8),
                _numField('Reps', _repsController),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _numField('Kg', _weightController),
                const SizedBox(width: 8),
                _numField('RIR', _rirController),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _numField('Desc (s)', _restController),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  final newDetail = widget.detail.copyWith(
                    sets: int.tryParse(_setsController.text) ?? widget.detail.sets,
                    reps: int.tryParse(_repsController.text) ?? widget.detail.reps,
                    weight: double.tryParse(_weightController.text) ??
                        widget.detail.weight,
                    restSeconds:
                        int.tryParse(_restController.text) ??
                            widget.detail.restSeconds,
                    rir: int.tryParse(_rirController.text) ?? widget.detail.rir,
                  );
                  widget.onSave(newDetail);
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
