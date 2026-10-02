import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/warm_up_step.dart';

class WarmUpEditorSection extends StatelessWidget {
  const WarmUpEditorSection({
    required this.steps,
    required this.onChanged,
    super.key,
  });

  final List<WarmUpStep> steps;
  final ValueChanged<List<WarmUpStep>> onChanged;

  Future<void> _editStep(BuildContext context, {int? index}) async {
    final existing = index == null ? null : steps[index];
    final result = await showDialog<WarmUpStep>(
      context: context,
      builder: (_) => _WarmUpStepDialog(step: existing),
    );
    if (result == null) return;
    final next = List<WarmUpStep>.from(steps);
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: KineticNoirPalette.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'WARM-UP',
                  style: KineticNoirTypography.headline(
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              key: const Key('warmup-add-step'),
              onPressed: () => _editStep(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: KineticNoirPalette.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'ADD STEP',
                style: KineticNoirTypography.body(
                  size: 12,
                  weight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Timed preparation runs before strength work. Per-side steps alternate left and right without adding rest between sides.',
          style: KineticNoirTypography.body(
            size: 13,
            weight: FontWeight.w500,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        if (steps.isEmpty)
          _EmptyWarmUp(onAdd: () => _editStep(context))
        else
          for (var index = 0; index < steps.length; index++)
            Padding(
              padding:
                  EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 10),
              child: _WarmUpStepTile(
                index: index,
                step: steps[index],
                onEdit: () => _editStep(context, index: index),
                onDelete: () {
                  final next = List<WarmUpStep>.from(steps)..removeAt(index);
                  onChanged(next);
                },
                onMoveUp: index == 0
                    ? null
                    : () {
                        final next = List<WarmUpStep>.from(steps);
                        final item = next.removeAt(index);
                        next.insert(index - 1, item);
                        onChanged(next);
                      },
                onMoveDown: index == steps.length - 1
                    ? null
                    : () {
                        final next = List<WarmUpStep>.from(steps);
                        final item = next.removeAt(index);
                        next.insert(index + 1, item);
                        onChanged(next);
                      },
              ),
            ),
      ],
    );
  }
}

class _WarmUpStepTile extends StatelessWidget {
  const _WarmUpStepTile({
    required this.index,
    required this.step,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int index;
  final WarmUpStep step;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final sideLabel = step.perSide ? ' per side' : '';
    return Material(
      color: KineticNoirPalette.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: KineticNoirPalette.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: KineticNoirTypography.headline(
                        size: 15,
                        weight: FontWeight.w700,
                        color: KineticNoirPalette.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KineticNoirTypography.body(
                          size: 15,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${step.sets} sets · ${step.workSeconds}s work$sideLabel · ${step.restSeconds}s rest',
                        style: KineticNoirTypography.body(
                          size: 12,
                          weight: FontWeight.w500,
                          color: KineticNoirPalette.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Step options',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: KineticNoirPalette.onSurfaceVariant,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: KineticNoirPalette.outlineVariant
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  color: KineticNoirPalette.surfaceBright,
                  onSelected: (value) {
                    switch (value) {
                      case 'up':
                        onMoveUp?.call();
                        break;
                      case 'down':
                        onMoveDown?.call();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'up',
                      enabled: onMoveUp != null,
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Move up'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'down',
                      enabled: onMoveDown != null,
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Move down'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: KineticNoirPalette.error,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(color: KineticNoirPalette.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWarmUp extends StatelessWidget {
  const _EmptyWarmUp({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onAdd,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: KineticNoirPalette.primary,
          side: BorderSide(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.35),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          'ADD YOUR FIRST WARM-UP STEP',
          style: KineticNoirTypography.body(
            size: 12,
            weight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _WarmUpStepDialog extends StatefulWidget {
  const _WarmUpStepDialog({this.step});
  final WarmUpStep? step;

  @override
  State<_WarmUpStepDialog> createState() => _WarmUpStepDialogState();
}

class _WarmUpStepDialogState extends State<_WarmUpStepDialog> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _sets;
  late final TextEditingController _work;
  late final TextEditingController _rest;
  late bool _perSide;

  @override
  void initState() {
    super.initState();
    final step = widget.step;
    _name = TextEditingController(text: step?.name ?? '');
    _notes = TextEditingController(text: step?.notes ?? '');
    _sets = TextEditingController(text: '${step?.sets ?? 3}');
    _work = TextEditingController(text: '${step?.workSeconds ?? 30}');
    _rest = TextEditingController(text: '${step?.restSeconds ?? 0}');
    _perSide = step?.perSide ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _sets.dispose();
    _work.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _save() {
    final sets = int.tryParse(_sets.text.trim()) ?? 0;
    final work = int.tryParse(_work.text.trim()) ?? 0;
    final rest = int.tryParse(_rest.text.trim()) ?? -1;
    if (_name.text.trim().isEmpty || sets <= 0 || work <= 0 || rest < 0) return;
    Navigator.pop(
      context,
      WarmUpStep(
        id: widget.step?.id ?? 0,
        name: _name.text.trim(),
        notes: _notes.text.trim(),
        sets: sets,
        workSeconds: work,
        restSeconds: rest,
        perSide: _perSide,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
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
                          'WARM-UP STEP',
                          style: KineticNoirTypography.body(
                            size: 10,
                            weight: FontWeight.w800,
                            color: KineticNoirPalette.primary,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.step == null
                              ? 'Add warm-up step'
                              : 'Edit warm-up step',
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StepTextField(
                controller: _name,
                label: 'Step Name',
                hintText: 'e.g. Arm Swings or Hip Openers',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _StepTextField(
                controller: _notes,
                label: 'Notes (Optional)',
                hintText: 'Focus on full range of motion',
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StepNumberField(
                      controller: _sets,
                      label: 'Sets',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StepNumberField(
                      controller: _work,
                      label: _perSide ? 'Sec / side' : 'Work sec',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StepNumberField(
                      controller: _rest,
                      label: 'Rest sec',
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: KineticNoirPalette.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: KineticNoirPalette.outlineVariant
                          .withValues(alpha: 0.22),
                    ),
                  ),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    activeThumbColor: KineticNoirPalette.primary,
                    value: _perSide,
                    onChanged: (value) => setState(() => _perSide = value),
                    title: Text(
                      'Time is per side',
                      style: KineticNoirTypography.body(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Runs left then right before resting.',
                      style: KineticNoirTypography.body(
                        size: 12,
                        weight: FontWeight.w500,
                        color: KineticNoirPalette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
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
                        onPressed: _save,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTextField extends StatelessWidget {
  const _StepTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final int maxLines;
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
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          textInputAction: textInputAction,
          style: KineticNoirTypography.body(
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
          ),
        ),
      ],
    );
  }
}

class _StepNumberField extends StatelessWidget {
  const _StepNumberField({
    required this.controller,
    required this.label,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
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
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: KineticNoirTypography.headline(
            size: 17,
            weight: FontWeight.w700,
            color: KineticNoirPalette.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
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
          ),
        ),
      ],
    );
  }
}
