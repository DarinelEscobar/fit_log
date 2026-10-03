import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../theme/toru_brand.dart';
import '../models/finish_session_summary_draft.dart';

enum FinishSessionSummaryAction {
  save,
  resume,
  discard,
}

@immutable
class FinishSessionSummaryResult {
  const FinishSessionSummaryResult._({
    required this.action,
    this.energy,
    this.mood,
    this.notes = '',
  });

  const FinishSessionSummaryResult.save({
    required String energy,
    required String mood,
    required String notes,
  }) : this._(
          action: FinishSessionSummaryAction.save,
          energy: energy,
          mood: mood,
          notes: notes,
        );

  const FinishSessionSummaryResult.resume({
    String? energy,
    String? mood,
    required String notes,
  }) : this._(
          action: FinishSessionSummaryAction.resume,
          energy: energy,
          mood: mood,
          notes: notes,
        );

  const FinishSessionSummaryResult.discard()
      : this._(action: FinishSessionSummaryAction.discard);

  final FinishSessionSummaryAction action;
  final String? energy;
  final String? mood;
  final String notes;
}

class FinishSessionSummaryScreen extends StatefulWidget {
  const FinishSessionSummaryScreen({
    required this.draft,
    super.key,
  });

  final FinishSessionSummaryDraft draft;

  static Future<FinishSessionSummaryResult?> show(
    BuildContext context, {
    required FinishSessionSummaryDraft draft,
  }) {
    return Navigator.of(context).push<FinishSessionSummaryResult>(
      MaterialPageRoute(
        builder: (_) => FinishSessionSummaryScreen(draft: draft),
      ),
    );
  }

  @override
  State<FinishSessionSummaryScreen> createState() =>
      _FinishSessionSummaryScreenState();
}

class _FinishSessionSummaryScreenState
    extends State<FinishSessionSummaryScreen> {
  late final TextEditingController _notesController;
  String? _energy;
  String? _mood;
  late bool _notesExpanded;

  static const _energyValues = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  static const _moodValues = <({String label, IconData icon})>[
    (label: '1', icon: Icons.sentiment_very_dissatisfied_rounded),
    (label: '2', icon: Icons.sentiment_dissatisfied_rounded),
    (label: '3', icon: Icons.sentiment_neutral_rounded),
    (label: '4', icon: Icons.sentiment_satisfied_rounded),
    (label: '5', icon: Icons.sentiment_very_satisfied_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _energy = widget.draft.energy;
    _mood = widget.draft.mood;
    _notesController = TextEditingController(text: widget.draft.notes);
    _notesExpanded = widget.draft.notes.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _energy != null && _mood != null;
    final isLargeText = MediaQuery.textScalerOf(context).scale(12) > 16 ||
        MediaQuery.sizeOf(context).width < 340;

    return PopScope<FinishSessionSummaryResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(const FinishSessionSummaryResult.discard());
      },
      child: Scaffold(
        backgroundColor: KineticNoirPalette.background,
        appBar: AppBar(
          backgroundColor: KineticNoirPalette.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            color: KineticNoirPalette.onSurfaceVariant,
            tooltip: 'Close',
            onPressed: () => Navigator.of(context)
                .pop(const FinishSessionSummaryResult.discard()),
          ),
          title: const KeyedSubtree(
            key: Key('finish-session-title'),
            child: FitLogWordmark(),
          ),
        ),
        bottomNavigationBar: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: canSave ? kineticPrimaryGradient : null,
                        color: canSave
                            ? null
                            : KineticNoirPalette.surfaceBright
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FilledButton(
                        key: const Key('finish-save-button'),
                        onPressed: canSave
                            ? () => Navigator.of(context)
                                    .pop(FinishSessionSummaryResult.save(
                                  energy: _energy!,
                                  mood: _mood!,
                                  notes: _notesController.text,
                                ))
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: KineticNoirPalette.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'SAVE & FINISH',
                          style: KineticNoirTypography.body(
                            size: 13,
                            weight: FontWeight.w800,
                            color: canSave
                                ? KineticNoirPalette.onPrimary
                                : KineticNoirPalette.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isLargeText) ...[
                    TextButton(
                      key: const Key('finish-resume-button'),
                      onPressed: () => Navigator.of(context)
                          .pop(FinishSessionSummaryResult.resume(
                        energy: _energy,
                        mood: _mood,
                        notes: _notesController.text,
                      )),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: KineticNoirPalette.primary,
                      ),
                      child: const Text('RESUME SESSION'),
                    ),
                    TextButton(
                      key: const Key('finish-discard-button'),
                      onPressed: () => Navigator.of(context)
                          .pop(const FinishSessionSummaryResult.discard()),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: KineticNoirPalette.error,
                      ),
                      child: const Text('DISCARD'),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            key: const Key('finish-resume-button'),
                            onPressed: () => Navigator.of(context)
                                .pop(FinishSessionSummaryResult.resume(
                              energy: _energy,
                              mood: _mood,
                              notes: _notesController.text,
                            )),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              foregroundColor: KineticNoirPalette.primary,
                            ),
                            child: const Text('RESUME SESSION'),
                          ),
                        ),
                        TextButton(
                          key: const Key('finish-discard-button'),
                          onPressed: () => Navigator.of(context)
                              .pop(const FinishSessionSummaryResult.discard()),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: KineticNoirPalette.error,
                          ),
                          child: const Text('DISCARD'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: KineticEntrance(
                  child: Container(
                    decoration: BoxDecoration(
                      color: KineticNoirPalette.surfaceLow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: KineticNoirPalette.outlineVariant
                            .withValues(alpha: 0.22),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KineticNoirPalette.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: KineticNoirPalette.primary
                                      .withValues(alpha: 0.24),
                                ),
                              ),
                              child: const Icon(
                                Icons.celebration_rounded,
                                color: KineticNoirPalette.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Session review',
                                    style: KineticNoirTypography.headline(
                                      size: 20,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.draft.planName} • Ready to save',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: KineticNoirTypography.body(
                                      size: 12,
                                      weight: FontWeight.w600,
                                      color: KineticNoirPalette.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _CompactSummaryBand(
                          duration: _formatDuration(widget.draft.duration),
                          volume: _formatVolume(widget.draft.volumeKg),
                          completedSets: widget.draft.completedSets,
                          totalSets: widget.draft.totalSets,
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel(
                          label: 'ENERGY LEVEL',
                          trailing: _energy == null ? '--/10' : '$_energy/10',
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                              Row(
                                children: [
                                  for (var i = 0; i < 5; i++)
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: i == 4 ? 0 : 6,
                                        ),
                                        child: _SelectableNumberChip(
                                          key: Key(
                                              'finish-energy-${_energyValues[i]}'),
                                          value: _energyValues[i],
                                          isSelected:
                                              _energy == _energyValues[i],
                                          onTap: () => setState(() =>
                                              _energy = _energyValues[i]),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  for (var i = 5; i < 10; i++)
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: i == 9 ? 0 : 6,
                                        ),
                                        child: _SelectableNumberChip(
                                          key: Key(
                                              'finish-energy-${_energyValues[i]}'),
                                          value: _energyValues[i],
                                          isSelected:
                                              _energy == _energyValues[i],
                                          onTap: () => setState(() =>
                                              _energy = _energyValues[i]),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        const _SectionLabel(label: 'MOOD LEVEL'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final mood in _moodValues)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: mood == _moodValues.last ? 0 : 6,
                                  ),
                                  child: _MoodButton(
                                    key: Key('finish-mood-${mood.label}'),
                                    mood: mood,
                                    isSelected: _mood == mood.label,
                                    onTap: () =>
                                        setState(() => _mood = mood.label),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_notesExpanded) ...[
                          Row(
                            children: [
                              const Expanded(
                                child: _SectionLabel(label: 'SESSION NOTES'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _notesExpanded = false),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor:
                                      KineticNoirPalette.onSurfaceVariant,
                                ),
                                child: const Text('COLLAPSE'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('finish-session-notes'),
                            controller: _notesController,
                            minLines: 2,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            style: KineticNoirTypography.body(
                              size: 14,
                              weight: FontWeight.w600,
                              height: 1.4,
                              color: KineticNoirPalette.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'How did it feel? Any new PRs?',
                              hintStyle: KineticNoirTypography.body(
                                size: 13,
                                weight: FontWeight.w500,
                                color: KineticNoirPalette.onSurfaceVariant
                                    .withValues(alpha: 0.55),
                              ),
                              filled: true,
                              fillColor: KineticNoirPalette.surfaceBright,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
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
                            ),
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            key: const Key('finish-expand-notes-button'),
                            onPressed: () =>
                                setState(() => _notesExpanded = true),
                            icon: const Icon(Icons.add_comment_outlined,
                                size: 16),
                            label:
                                const Text('ADD SESSION NOTES (OPTIONAL)'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 42),
                              foregroundColor:
                                  KineticNoirPalette.onSurfaceVariant,
                              side: BorderSide(
                                color: KineticNoirPalette.outlineVariant
                                    .withValues(alpha: 0.22),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    return minutes.toString();
  }

  String _formatVolume(double volumeKg) {
    if (volumeKg >= 1000) {
      return '${(volumeKg / 1000).toStringAsFixed(1)}k';
    }
    return volumeKg.toStringAsFixed(0);
  }
}

class _CompactSummaryBand extends StatelessWidget {
  const _CompactSummaryBand({
    required this.duration,
    required this.volume,
    required this.completedSets,
    required this.totalSets,
  });

  final String duration;
  final String volume;
  final int completedSets;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryBandColumn(
              label: 'DURATION',
              value: duration,
              suffix: 'MIN',
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _SummaryBandColumn(
              label: 'VOLUME',
              value: volume,
              suffix: 'KG',
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _SummaryBandColumn(
              label: 'SETS',
              value: '$completedSets/$totalSets',
              suffix: 'DONE',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBandColumn extends StatelessWidget {
  const _SummaryBandColumn({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: KineticNoirTypography.body(
            size: 9,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: KineticNoirTypography.headline(
                  size: 18,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.primary,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                suffix,
                style: KineticNoirTypography.body(
                  size: 10,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    this.trailing,
  });

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: KineticNoirTypography.body(
              size: 10,
              weight: FontWeight.w800,
              color: KineticNoirPalette.onSurfaceVariant,
              letterSpacing: 1.6,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing!,
            style: KineticNoirTypography.headline(
              size: 20,
              color: KineticNoirPalette.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectableNumberChip extends StatelessWidget {
  const _SelectableNumberChip({
    required this.value,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motionDuration = KineticMotion.duration(context, 180);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: motionDuration,
          height: 48,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          decoration: BoxDecoration(
            color: isSelected
                ? KineticNoirPalette.primary
                : KineticNoirPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? KineticNoirPalette.primary
                  : KineticNoirPalette.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w800,
                color: isSelected
                    ? KineticNoirPalette.onPrimary
                    : KineticNoirPalette.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ({String label, IconData icon}) mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motionDuration = KineticMotion.duration(context, 180);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: motionDuration,
          height: 48,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          decoration: BoxDecoration(
            color: isSelected
                ? KineticNoirPalette.primary.withValues(alpha: 0.16)
                : KineticNoirPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? KineticNoirPalette.primary
                  : KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Icon(
              mood.icon,
              size: 22,
              color: isSelected
                  ? KineticNoirPalette.primary
                  : KineticNoirPalette.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
