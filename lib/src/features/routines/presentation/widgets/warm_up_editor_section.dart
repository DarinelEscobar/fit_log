import 'package:flutter/material.dart';

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
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: KineticNoirPalette.primary),
            const SizedBox(width: 8),
            Text(
              'WARM-UP',
              style: KineticNoirTypography.headline(
                  size: 18, weight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              key: const Key('warmup-add-step'),
              onPressed: () => _editStep(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('ADD STEP'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Timed preparation runs before strength work. Per-side steps alternate left and right without adding rest between sides.',
          style: KineticNoirTypography.body(
            size: 13,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
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
    final sideLabel = step.perSide ? ' PER SIDE' : '';
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(
          backgroundColor: KineticNoirPalette.primary.withValues(alpha: 0.14),
          child: Text('${index + 1}',
              style: const TextStyle(color: KineticNoirPalette.primary)),
        ),
        title: Text(step.name,
            style:
                KineticNoirTypography.body(size: 16, weight: FontWeight.w800)),
        subtitle: Text(
          '${step.sets} sets · ${step.workSeconds}s work$sideLabel · ${step.restSeconds}s rest',
          style: KineticNoirTypography.body(
              size: 12,
              weight: FontWeight.w600,
              color: KineticNoirPalette.onSurfaceVariant),
        ),
        trailing: PopupMenuButton<String>(
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
                child: const Text('Move up')),
            PopupMenuItem(
                value: 'down',
                enabled: onMoveDown != null,
                child: const Text('Move down')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _EmptyWarmUp extends StatelessWidget {
  const _EmptyWarmUp({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD YOUR FIRST WARM-UP STEP'),
      );
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
        ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            widget.step == null ? 'Add warm-up step' : 'Edit warm-up step'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: _notes,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)')),
            TextField(
                controller: _sets,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sets')),
            TextField(
                controller: _work,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: _perSide ? 'Seconds per side' : 'Work seconds')),
            TextField(
                controller: _rest,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rest seconds')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _perSide,
              onChanged: (value) => setState(() => _perSide = value),
              title: const Text('Time is per side'),
              subtitle: const Text('Runs left then right before resting.'),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      );
}
