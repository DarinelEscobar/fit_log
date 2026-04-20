import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../models/routine_editor_draft.dart';

class RoutineEditorExerciseCard extends StatelessWidget {
  const RoutineEditorExerciseCard({
    required this.compactLayout,
    required this.draft,
    required this.onDelete,
    super.key,
  });

  final bool compactLayout;
  final RoutineEditorDraft draft;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.24),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: KineticNoirPalette.onSurfaceVariant.withValues(
                    alpha: 0.65,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: KineticNoirPalette.surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: KineticNoirPalette.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TextFieldShell(
                            label: 'Exercise Name',
                            controller: draft.nameController,
                            style: KineticNoirTypography.headline(
                              size: 22,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: compactLayout ? 220 : 180,
                                child: _FilledField(
                                  label: 'Category',
                                  controller: draft.categoryController,
                                ),
                              ),
                              SizedBox(
                                width: compactLayout ? 220 : 180,
                                child: _FilledField(
                                  label: 'Primary Muscle',
                                  controller: draft.mainMuscleController,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _DeleteButton(onPressed: onDelete),
                  ],
                ),
                const SizedBox(height: 18),
                _FilledField(
                  label: 'Description',
                  controller: draft.descriptionController,
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'PROGRAMMING',
                  style: KineticNoirTypography.body(
                    size: 10,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.primary,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricField(
                      width: compactLayout ? 112 : 96,
                      label: 'Sets',
                      controller: draft.setsController,
                      keyboardType: TextInputType.number,
                    ),
                    _MetricField(
                      width: compactLayout ? 112 : 96,
                      label: 'Reps',
                      controller: draft.repsController,
                      keyboardType: TextInputType.number,
                    ),
                    _MetricField(
                      width: compactLayout ? 112 : 96,
                      label: 'Weight',
                      controller: draft.weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _MetricField(
                      width: compactLayout ? 112 : 96,
                      label: 'Rest',
                      controller: draft.restController,
                      keyboardType: TextInputType.number,
                    ),
                    _MetricField(
                      width: compactLayout ? 112 : 96,
                      label: 'RIR',
                      controller: draft.rirController,
                      keyboardType: TextInputType.number,
                      accentColor: KineticNoirPalette.error,
                    ),
                    _MetricField(
                      width: compactLayout ? 112 : 96,
                      label: 'Tempo',
                      controller: draft.tempoController,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextFieldShell extends StatelessWidget {
  const _TextFieldShell({
    required this.label,
    required this.controller,
    required this.style,
  });

  final String label;
  final TextEditingController controller;
  final TextStyle style;

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
        TextField(
          controller: controller,
          style: style,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: KineticNoirPalette.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilledField extends StatelessWidget {
  const _FilledField({
    required this.label,
    required this.controller,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
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
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          style: KineticNoirTypography.body(
            size: 14,
            weight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.width,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.accentColor = KineticNoirPalette.primary,
  });

  final double width;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: KineticNoirPalette.surfaceLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: KineticNoirTypography.body(
                size: 9,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: KineticNoirTypography.headline(
                size: 20,
                weight: FontWeight.w700,
                color: accentColor,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_rounded,
          size: 18,
          color: KineticNoirPalette.onSurfaceVariant,
        ),
      ),
    );
  }
}
