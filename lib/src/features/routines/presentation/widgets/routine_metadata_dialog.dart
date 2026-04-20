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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KineticNoirPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CREATE ROUTINE',
              style: KineticNoirTypography.headline(
                size: 24,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Define the routine shell without changing storage behavior.',
              style: KineticNoirTypography.body(
                size: 14,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _DialogField(
              controller: _nameController,
              label: 'Routine Name',
              hintText: 'Push / Pull / Legs',
            ),
            const SizedBox(height: 14),
            _DialogField(
              controller: _frequencyController,
              label: 'Frequency',
              hintText: '3 sessions per week',
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: KineticNoirTypography.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: kineticPrimaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        RoutineMetadataInput(
                          name: _nameController.text.trim(),
                          frequency: _frequencyController.text.trim(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: KineticNoirPalette.onPrimary,
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
              ],
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
  });

  final TextEditingController controller;
  final String label;
  final String hintText;

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
          style: KineticNoirTypography.headline(
            size: 20,
            weight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
