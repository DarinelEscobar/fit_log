import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../performance/presentation/pages/exercise_progress_detail_screen.dart';
import '../../../routines/presentation/models/exercise_list_view_data.dart';
import '../models/history_models.dart';

class HistorySessionDetailScreen extends StatelessWidget {
  const HistorySessionDetailScreen({
    required this.session,
    super.key,
  });

  final HistorySessionSummary session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: KineticNoirPalette.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SESSION REVIEW',
          key: const Key('history-session-detail-title'),
          style: KineticNoirTypography.headline(
            size: 22,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          cacheExtent: 700,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _SessionHeader(session: session),
              ),
            ),
            if (session.exercises.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exercise = session.exercises[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              index == session.exercises.length - 1 ? 0 : 14,
                        ),
                        child: _ExerciseReviewCard(
                          exercise: exercise,
                          onOpenProgress: () => _openProgress(
                            context,
                            exercise,
                          ),
                        ),
                      );
                    },
                    childCount: session.exercises.length,
                  ),
                ),
              )
            else
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 120),
                sliver: SliverToBoxAdapter(
                  child: _NoExerciseLogsCard(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProgress(
    BuildContext context,
    HistoryExerciseSummary exercise,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExerciseProgressDetailScreen(
          exercise: ExerciseListItemView(
            exerciseId: exercise.exerciseId,
            name: exercise.name,
            description: exercise.description,
            category: exercise.category,
            mainMuscleGroup: exercise.mainMuscleGroup,
            sets: exercise.sets.length,
            reps: exercise.topReps,
            restSeconds: 0,
            weight: exercise.topWeightKg,
          ),
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session});

  final HistorySessionSummary session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          left: BorderSide(
            color: KineticNoirPalette.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d, yyyy').format(session.date).toUpperCase(),
            style: KineticNoirTypography.body(
              size: 11,
              weight: FontWeight.w800,
              color: KineticNoirPalette.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            session.planName,
            style: KineticNoirTypography.headline(
              size: 34,
              weight: FontWeight.w700,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(label: '${session.totalSets} sets'),
              _MetaPill(label: '${session.totalReps} reps'),
              _MetaPill(label: '${_formatKg(session.totalVolumeKg)} kg'),
              if (session.durationMinutes > 0)
                _MetaPill(label: '${session.durationMinutes} min'),
              if (session.energy.isNotEmpty)
                _MetaPill(label: 'Energy ${session.energy}/10'),
              if (session.mood.isNotEmpty)
                _MetaPill(label: 'Mood ${session.mood}/5'),
            ],
          ),
          if (session.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: KineticNoirPalette.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                session.notes.trim(),
                style: KineticNoirTypography.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseReviewCard extends StatelessWidget {
  const _ExerciseReviewCard({
    required this.exercise,
    required this.onOpenProgress,
  });

  final HistoryExerciseSummary exercise;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (exercise.category.isNotEmpty)
                _TagChip(label: exercise.category),
              if (exercise.mainMuscleGroup.isNotEmpty)
                _TagChip(
                  label: exercise.mainMuscleGroup,
                  highlighted: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.name,
            style: KineticNoirTypography.headline(
              size: 25,
              weight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricPanel(
                label: 'SETS',
                value: '${exercise.sets.length}',
              ),
              const SizedBox(width: 10),
              _MetricPanel(
                label: 'VOLUME',
                value: _formatKg(exercise.volumeKg),
              ),
              const SizedBox(width: 10),
              _MetricPanel(
                label: 'TOP SET',
                value:
                    '${_formatKg(exercise.topWeightKg)} x ${exercise.topReps}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SetTable(sets: exercise.sets),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenProgress,
              style: TextButton.styleFrom(
                foregroundColor: KineticNoirPalette.primary,
                backgroundColor:
                    KineticNoirPalette.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.trending_up_rounded, size: 18),
              label: Text(
                'PROGRESS',
                style: KineticNoirTypography.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetTable extends StatelessWidget {
  const _SetTable({required this.sets});

  final List<HistorySetRow> sets;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          const Row(
            children: [
              SizedBox(width: 44, child: _HeaderText('SET')),
              Expanded(child: Center(child: _HeaderText('KG'))),
              Expanded(child: Center(child: _HeaderText('REPS'))),
              Expanded(child: Center(child: _HeaderText('RIR'))),
            ],
          ),
          const SizedBox(height: 8),
          for (final set in sets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${set.setNumber}',
                      style: KineticNoirTypography.body(
                        size: 13,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.primary,
                      ),
                    ),
                  ),
                  Expanded(child: _SetValue(_formatKg(set.weightKg))),
                  Expanded(child: _SetValue('${set.reps}')),
                  Expanded(child: _SetValue('${set.rir}')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KineticNoirPalette.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderText(label),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: KineticNoirTypography.body(
        size: 10,
        weight: FontWeight.w800,
        color: KineticNoirPalette.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SetValue extends StatelessWidget {
  const _SetValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        value,
        style: KineticNoirTypography.body(
          size: 13,
          weight: FontWeight.w700,
          color: KineticNoirPalette.onSurface,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KineticNoirTypography.body(
          size: 10,
          weight: FontWeight.w800,
          color: KineticNoirPalette.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? KineticNoirPalette.primary
        : KineticNoirPalette.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlighted ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: KineticNoirTypography.body(
          size: 9,
          weight: FontWeight.w800,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _NoExerciseLogsCard extends StatelessWidget {
  const _NoExerciseLogsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(24),
      child: Text(
        'This session has a saved summary but no set logs.',
        textAlign: TextAlign.center,
        style: KineticNoirTypography.body(
          size: 14,
          weight: FontWeight.w700,
          color: KineticNoirPalette.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}

String _formatKg(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
