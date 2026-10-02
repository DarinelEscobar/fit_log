import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';

class RoutineMetadataInput {
  const RoutineMetadataInput({
    required this.name,
    required this.frequency,
  });

  final String name;
  final String frequency;
}

class RoutineMetadataDialog extends StatefulWidget {
  const RoutineMetadataDialog({super.key});

  @override
  State<RoutineMetadataDialog> createState() => _RoutineMetadataDialogState();
}

class _RoutineMetadataDialogState extends State<RoutineMetadataDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _frequencyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _frequencyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      RoutineMetadataInput(
        name: _nameController.text.trim(),
        frequency: _frequencyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KineticNoirPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: KineticNoirPalette.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
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
                                'Create routine',
                                style: KineticNoirTypography.headline(
                                  size: 22,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Give your routine a name and a weekly schedule.',
                                style: KineticNoirTypography.body(
                                  size: 13,
                                  color: KineticNoirPalette.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: KineticNoirPalette.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DialogField(
                      controller: _nameController,
                      label: 'Routine Name',
                      hintText: 'Push / Pull / Legs',
                      textInputAction: TextInputAction.next,
                      style: KineticNoirTypography.headline(
                        size: 20,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DialogField(
                      controller: _frequencyController,
                      label: 'Frequency',
                      hintText: '3 sessions per week',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffixIcon: const Icon(
                        Icons.event_repeat_rounded,
                        color: KineticNoirPalette.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: KineticNoirPalette.surface,
                border: Border(
                  top: BorderSide(
                    color: KineticNoirPalette.outlineVariant
                        .withValues(alpha: 0.16),
                  ),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: KineticNoirTypography.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: KineticNoirPalette.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: kineticPrimaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(100, 48),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: KineticNoirPalette.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: KineticNoirTypography.body(
                            size: 14,
                            weight: FontWeight.w800,
                            color: KineticNoirPalette.onPrimary,
                          ),
                        ),
                      ),
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

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.textInputAction,
    this.onSubmitted,
    this.style,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final Widget? suffixIcon;

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
          controller: controller,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: style ??
              KineticNoirTypography.body(
                size: 15,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurface,
              ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: KineticNoirTypography.body(
              size: 14,
              weight: FontWeight.w500,
              color:
                  KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
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
          ),
        ),
      ],
    );
  }
}
