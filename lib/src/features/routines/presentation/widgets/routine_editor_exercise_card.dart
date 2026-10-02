import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../models/routine_editor_draft.dart';

class RoutineEditorExerciseCard extends StatefulWidget {
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
  State<RoutineEditorExerciseCard> createState() =>
      _RoutineEditorExerciseCardState();
}

class _RoutineEditorExerciseCardState extends State<RoutineEditorExerciseCard> {
  bool _expanded = false;
  RoutineEditorDraft get draft => widget.draft;
  bool get compactLayout => widget.compactLayout;
  VoidCallback get onDelete => widget.onDelete;

  @override
  Widget build(BuildContext context) {
    final motionDuration = KineticMotion.duration(context, 180);
    final isLargeText = MediaQuery.textScalerOf(context).scale(12) > 16;

    return Material(
      color: KineticNoirPalette.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: motionDuration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _expanded
                ? KineticNoirPalette.primary.withValues(alpha: 0.45)
                : KineticNoirPalette.outlineVariant.withValues(alpha: 0.28),
            width: _expanded ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    draft.nameController,
                    draft.setsController,
                    draft.repsController,
                    draft.weightController,
                  ]),
                  builder: (context, _) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.nameController.text.trim().isEmpty
                                  ? 'Unnamed Exercise'
                                  : draft.nameController.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KineticNoirTypography.headline(
                                size: 17,
                                weight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${draft.setsController.text} sets × ${draft.repsController.text} reps · ${draft.weightController.text} kg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KineticNoirTypography.body(
                                size: 12,
                                weight: FontWeight.w500,
                                color: KineticNoirPalette.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: motionDuration,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: KineticNoirPalette.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: motionDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: KineticNoirPalette.outlineVariant
                              .withValues(alpha: 0.2),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _TextFieldShell(
                                      label: 'Exercise Name',
                                      controller: draft.nameController,
                                      style: KineticNoirTypography.headline(
                                        size: 20,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _DeleteButton(onPressed: onDelete),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (isLargeText) ...[
                                _FilledField(
                                  label: 'Category',
                                  controller: draft.categoryController,
                                ),
                                const SizedBox(height: 12),
                                _FilledField(
                                  label: 'Primary Muscle',
                                  controller: draft.mainMuscleController,
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FilledField(
                                        label: 'Category',
                                        controller: draft.categoryController,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _FilledField(
                                        label: 'Primary Muscle',
                                        controller: draft.mainMuscleController,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),
                              _FilledField(
                                label: 'Description',
                                controller: draft.descriptionController,
                                minLines: 2,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 18),
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
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final useTwoColumns =
                                      availableWidth < 300 || isLargeText;

                                  if (useTwoColumns) {
                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _MetricField(
                                                label: 'Sets',
                                                controller:
                                                    draft.setsController,
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _MetricField(
                                                label: 'Reps',
                                                controller:
                                                    draft.repsController,
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _MetricField(
                                                label: 'Weight',
                                                controller:
                                                    draft.weightController,
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                  decimal: true,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _MetricField(
                                                label: 'Rest',
                                                controller:
                                                    draft.restController,
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _MetricField(
                                                label: 'RIR',
                                                controller: draft.rirController,
                                                keyboardType:
                                                    TextInputType.number,
                                                accentColor:
                                                    KineticNoirPalette.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _MetricField(
                                                label: 'Tempo',
                                                controller:
                                                    draft.tempoController,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _MetricField(
                                              label: 'Sets',
                                              controller: draft.setsController,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _MetricField(
                                              label: 'Reps',
                                              controller: draft.repsController,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _MetricField(
                                              label: 'Weight',
                                              controller:
                                                  draft.weightController,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                decimal: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _MetricField(
                                              label: 'Rest',
                                              controller: draft.restController,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _MetricField(
                                              label: 'RIR',
                                              controller: draft.rirController,
                                              keyboardType:
                                                  TextInputType.number,
                                              accentColor:
                                                  KineticNoirPalette.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _MetricField(
                                              label: 'Tempo',
                                              controller: draft.tempoController,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: style,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.4),
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
            color: KineticNoirPalette.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
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

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.accentColor = KineticNoirPalette.onSurface,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KineticNoirTypography.body(
              size: 9,
              weight: FontWeight.w800,
              color: KineticNoirPalette.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: KineticNoirTypography.headline(
              size: 17,
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
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: KineticNoirPalette.error,
            ),
          ),
        ),
      ),
    );
  }
}
