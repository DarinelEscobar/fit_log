import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';

class ExerciseDefinitionJsonActions extends StatelessWidget {
  const ExerciseDefinitionJsonActions({
    required this.canCopyPrompt,
    required this.canPasteJson,
    required this.onCopyPrompt,
    required this.onPasteJson,
    super.key,
  });

  final bool canCopyPrompt;
  final bool canPasteJson;
  final VoidCallback? onCopyPrompt;
  final VoidCallback? onPasteJson;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          key: const Key('exercise-definition-copy-prompt'),
          onPressed: canCopyPrompt ? onCopyPrompt : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: KineticNoirPalette.primary,
            disabledForegroundColor:
                KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.5),
            side: BorderSide(
              color: canCopyPrompt
                  ? KineticNoirPalette.primary.withValues(alpha: 0.72)
                  : KineticNoirPalette.outlineVariant.withValues(alpha: 0.32),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.content_copy_rounded, size: 18),
          label: Text(
            'COPY PROMPT',
            style: KineticNoirTypography.body(
              size: 12,
              weight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        if (canPasteJson)
          OutlinedButton.icon(
            key: const Key('exercise-definition-paste-json'),
            onPressed: onPasteJson,
            style: OutlinedButton.styleFrom(
              foregroundColor: KineticNoirPalette.onSurface,
              side: BorderSide(
                color: KineticNoirPalette.outlineVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: Text(
              'PASTE JSON',
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class ExerciseDefinitionField extends StatelessWidget {
  const ExerciseDefinitionField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    super.key,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String hintText;
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
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          style: KineticNoirTypography.body(size: 15, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
