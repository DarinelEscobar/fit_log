import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/plan_exercise_detail.dart';

Future<PlanExerciseDetail?> showActiveSessionExerciseSetupSheet(
  BuildContext context, {
  required PlanExerciseDetail detail,
}) {
  return showModalBottomSheet<PlanExerciseDetail>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: KineticNoirPalette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ActiveSessionExerciseSetupSheet(detail: detail),
  );
}

class _ActiveSessionExerciseSetupSheet extends StatefulWidget {
  const _ActiveSessionExerciseSetupSheet({required this.detail});

  final PlanExerciseDetail detail;

  @override
  State<_ActiveSessionExerciseSetupSheet> createState() =>
      _ActiveSessionExerciseSetupSheetState();
}

class _ActiveSessionExerciseSetupSheetState
    extends State<_ActiveSessionExerciseSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _restController;
  late final TextEditingController _rirController;
  late final TextEditingController _tempoController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(text: '${widget.detail.sets}');
    _repsController = TextEditingController(text: '${widget.detail.reps}');
    _restController =
        TextEditingController(text: '${widget.detail.restSeconds}');
    _rirController = TextEditingController(text: '${widget.detail.rir}');
    _tempoController = TextEditingController(text: widget.detail.tempo);
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _rirController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      widget.detail.copyWith(
        sets: int.parse(_setsController.text.trim()),
        reps: int.parse(_repsController.text.trim()),
        restSeconds: int.parse(_restController.text.trim()),
        rir: int.parse(_rirController.text.trim()),
        tempo: _tempoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.detail.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KineticNoirTypography.headline(
                        size: 22,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SetupNumberField(
                      key: const Key('session-setup-sets'),
                      controller: _setsController,
                      label: 'Sets',
                      minValue: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SetupNumberField(
                      key: const Key('session-setup-reps'),
                      controller: _repsController,
                      label: 'Reps',
                      minValue: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SetupNumberField(
                      key: const Key('session-setup-rest'),
                      controller: _restController,
                      label: 'Rest sec',
                      minValue: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SetupNumberField(
                      key: const Key('session-setup-rir'),
                      controller: _rirController,
                      label: 'RIR',
                      minValue: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('session-setup-tempo'),
                controller: _tempoController,
                decoration: _fieldDecoration('Tempo'),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('session-setup-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    'SAVE SETUP',
                    style: KineticNoirTypography.body(
                      size: 12,
                      weight: FontWeight.w800,
                      color: KineticNoirPalette.onPrimary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupNumberField extends StatelessWidget {
  const _SetupNumberField({
    required this.controller,
    required this.label,
    required this.minValue,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final int minValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecoration(label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed < minValue) {
          return 'Min $minValue';
        }
        return null;
      },
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: KineticNoirPalette.surfaceLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.24),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.18),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: KineticNoirPalette.primary),
    ),
  );
}
