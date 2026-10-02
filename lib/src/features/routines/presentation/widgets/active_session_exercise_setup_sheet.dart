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

    return Material(
      color: KineticNoirPalette.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXERCISE SETUP',
                            style: KineticNoirTypography.body(
                              size: 10,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.primary,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.detail.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: KineticNoirTypography.headline(
                              size: 22,
                              weight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: KineticNoirPalette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SetupNumberField(
                        key: const Key('session-setup-sets'),
                        controller: _setsController,
                        label: 'Sets',
                        minValue: 1,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SetupNumberField(
                        key: const Key('session-setup-reps'),
                        controller: _repsController,
                        label: 'Reps',
                        minValue: 1,
                        textInputAction: TextInputAction.next,
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
                        label: 'Rest (seconds)',
                        minValue: 0,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SetupNumberField(
                        key: const Key('session-setup-rir'),
                        controller: _rirController,
                        label: 'RIR',
                        minValue: 0,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEMPO',
                      style: KineticNoirTypography.body(
                        size: 10,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('session-setup-tempo'),
                      controller: _tempoController,
                      textInputAction: TextInputAction.done,
                      style: KineticNoirTypography.body(
                        size: 15,
                        weight: FontWeight.w600,
                        color: KineticNoirPalette.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 3-0-1-0',
                        hintStyle: KineticNoirTypography.body(
                          size: 14,
                          weight: FontWeight.w500,
                          color: KineticNoirPalette.onSurfaceVariant
                              .withValues(alpha: 0.55),
                        ),
                        filled: true,
                        fillColor: KineticNoirPalette.surfaceLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: KineticNoirPalette.outlineVariant
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: KineticNoirPalette.outlineVariant
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: KineticNoirPalette.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: KineticNoirPalette.error,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: kineticPrimaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('session-setup-save'),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: KineticNoirPalette.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        label: Text(
                          'SAVE SETUP',
                          style: KineticNoirTypography.body(
                            size: 13,
                            weight: FontWeight.w800,
                            color: KineticNoirPalette.onPrimary,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final int minValue;
  final TextInputAction? textInputAction;

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
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: KineticNoirTypography.headline(
            size: 18,
            weight: FontWeight.w700,
            color: KineticNoirPalette.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: KineticNoirPalette.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: KineticNoirPalette.error,
              ),
            ),
          ),
          validator: (value) {
            final parsed = int.tryParse(value?.trim() ?? '');
            if (parsed == null || parsed < minValue) {
              return 'Min $minValue';
            }
            return null;
          },
        ),
      ],
    );
  }
}
