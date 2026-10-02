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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 56),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      decoration: BoxDecoration(
                        color: KineticNoirPalette.surfaceLow,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: KineticNoirPalette.outlineVariant
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: KineticNoirPalette.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: KineticNoirPalette.primary
                                    .withValues(alpha: 0.24),
                              ),
                            ),
                            child: const Icon(
                              Icons.celebration_rounded,
                              color: KineticNoirPalette.primary,
                              size: 24,
                            ),
                          ),
                          Text(
                            'Session review',
                            style: KineticNoirTypography.headline(
                              size: 26,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.draft.planName} is ready to save. Review your session and finish cleanly.',
                            style: KineticNoirTypography.body(
                              size: 14,
                              weight: FontWeight.w500,
                              color: KineticNoirPalette.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryMetricCard(
                                  label: 'DURATION',
                                  value: _formatDuration(widget.draft.duration),
                                  suffix: 'MIN',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryMetricCard(
                                  label: 'VOLUME',
                                  value: _formatVolume(widget.draft.volumeKg),
                                  suffix: 'KG',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SummaryProgressChip(
                            completedSets: widget.draft.completedSets,
                            totalSets: widget.draft.totalSets,
                          ),
                          const SizedBox(height: 26),
                          _SectionLabel(
                            label: 'ENERGY LEVEL',
                            trailing: _energy == null ? '--/10' : '$_energy/10',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final value in _energyValues)
                                _SelectableNumberChip(
                                  key: Key('finish-energy-$value'),
                                  value: value,
                                  isSelected: _energy == value,
                                  onTap: () => setState(() => _energy = value),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const _SectionLabel(label: 'MOOD LEVEL'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final mood in _moodValues)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: mood == _moodValues.last ? 0 : 8,
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
                          const SizedBox(height: 24),
                          const _SectionLabel(label: 'SESSION NOTES'),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('finish-session-notes'),
                            controller: _notesController,
                            minLines: 2,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            style: KineticNoirTypography.body(
                              size: 15,
                              weight: FontWeight.w600,
                              height: 1.5,
                              color: KineticNoirPalette.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'How did it feel? Any new PRs?',
                              hintStyle: KineticNoirTypography.body(
                                size: 14,
                                weight: FontWeight.w500,
                                color: KineticNoirPalette.onSurfaceVariant
                                    .withValues(alpha: 0.55),
                              ),
                              filled: true,
                              fillColor: KineticNoirPalette.surfaceBright,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: KineticNoirPalette.outlineVariant
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: KineticNoirPalette.outlineVariant
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: KineticNoirPalette.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
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

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KineticNoirPalette.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KineticNoirTypography.body(
                size: 10,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: [
                Text(
                  value,
                  style: KineticNoirTypography.headline(
                    size: 26,
                    color: KineticNoirPalette.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    suffix,
                    style: KineticNoirTypography.body(
                      size: 11,
                      weight: FontWeight.w700,
                      color: KineticNoirPalette.onSurfaceVariant,
                      letterSpacing: 1.1,
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

class _SummaryProgressChip extends StatelessWidget {
  const _SummaryProgressChip({
    required this.completedSets,
    required this.totalSets,
  });

  final int completedSets;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KineticNoirPalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: KineticNoirPalette.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$completedSets / $totalSets sets completed',
                style: KineticNoirTypography.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: motionDuration,
          width: 38,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? KineticNoirPalette.primary
                : KineticNoirPalette.surface,
            borderRadius: BorderRadius.circular(14),
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: motionDuration,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? KineticNoirPalette.primary.withValues(alpha: 0.16)
                : KineticNoirPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? KineticNoirPalette.primary
                  : KineticNoirPalette.outlineVariant.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            mood.icon,
            size: 24,
            color: isSelected
                ? KineticNoirPalette.primary
                : KineticNoirPalette.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
