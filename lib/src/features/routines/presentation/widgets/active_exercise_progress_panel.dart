import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../performance/domain/models/active_exercise_progress.dart';
import '../../../performance/domain/services/active_exercise_progress_calculator.dart';
import '../../../performance/presentation/providers/active_exercise_progress_provider.dart';
import '../../domain/entities/weight_display_unit.dart';
import '../../domain/entities/workout_log_entry.dart';

const double _kgToLbFactor = 2.2046226218;

class ActiveExerciseProgressPanel extends ConsumerWidget {
  const ActiveExerciseProgressPanel({
    required this.exerciseId,
    required this.sessionDate,
    required this.currentLogs,
    required this.weightUnit,
    super.key,
  });

  final int exerciseId;
  final DateTime sessionDate;
  final List<WorkoutLogEntry> currentLogs;
  final WeightDisplayUnit weightUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ActiveExerciseProgressRequest(
      exerciseId: exerciseId,
      sessionDate: sessionDate,
    );
    final asyncInsight = ref.watch(activeExerciseProgressProvider(request));
    final currentSession =
        ActiveExerciseProgressCalculator.buildCurrentSession(currentLogs);

    return asyncInsight.when(
      loading: () => _ProgressShell(
        key: Key('active-progress-panel-$exerciseId'),
        titleChip: const _StatusChip(
          label: 'LOADING',
          color: KineticNoirPalette.outlineVariant,
        ),
        child: _ProgressLoadingState(currentSession: currentSession),
      ),
      error: (error, _) => _ProgressShell(
        key: Key('active-progress-panel-$exerciseId'),
        titleChip: const _StatusChip(
          key: Key('active-progress-error-chip'),
          label: 'UNAVAILABLE',
          color: KineticNoirPalette.error,
        ),
        child: _ProgressFallbackState(
          key: Key('active-progress-error-$exerciseId'),
          title: 'Progress unavailable',
          detail: 'Logging is still enabled for this exercise.',
          currentSession: currentSession,
          weightUnit: weightUnit,
        ),
      ),
      data: (insight) {
        final delta = ActiveExerciseProgressCalculator.compareCurrentToBaseline(
          currentSession: currentSession,
          baseline: insight.recentBaseline,
        );

        if (!insight.hasHistory) {
          return _ProgressShell(
            key: Key('active-progress-panel-$exerciseId'),
            titleChip: _DeltaChip(delta: delta, weightUnit: weightUnit),
            child: _ProgressFallbackState(
              title: 'No previous sessions yet',
              detail: 'Complete sets now to start a baseline.',
              currentSession: currentSession,
              weightUnit: weightUnit,
            ),
          );
        }

        return _ProgressShell(
          key: Key('active-progress-panel-$exerciseId'),
          titleChip: _DeltaChip(delta: delta, weightUnit: weightUnit),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ProgressMetricTile(
                      label: 'LAST',
                      value: _formatSessionStrength(
                        insight.lastSession,
                        weightUnit,
                      ),
                      detail: _formatSessionDetail(
                        insight.lastSession,
                        weightUnit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProgressMetricTile(
                      label: 'TREND',
                      value: _formatBaseline(
                        insight.recentBaseline,
                        weightUnit,
                      ),
                      detail: insight.recentBaseline == null
                          ? 'Need history'
                          : '${insight.recentBaseline!.sessionCount}-session median',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProgressMetricTile(
                      label: 'TODAY',
                      value: _formatSessionStrength(
                        currentSession,
                        weightUnit,
                      ),
                      detail: _formatTodayDetail(
                        currentSession,
                        weightUnit,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProgressSparkline(
                points: insight.recentTrendPoints,
                weightUnit: weightUnit,
              ),
              const SizedBox(height: 10),
              _SetSummaryLine(
                label: 'LAST',
                summary: insight.lastSession,
                weightUnit: weightUnit,
              ),
              const SizedBox(height: 6),
              _SetSummaryLine(
                label: 'TODAY',
                summary: currentSession,
                weightUnit: weightUnit,
              ),
              const SizedBox(height: 8),
              Text(
                'Comparable strength averages up to 3 top working sets. Volume stays secondary.',
                style: KineticNoirTypography.body(
                  size: 10,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressShell extends StatelessWidget {
  const _ProgressShell({
    required this.titleChip,
    required this.child,
    super.key,
  });

  final Widget titleChip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KineticNoirPalette.surfaceLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'LIVE PROGRESS',
                    style: KineticNoirTypography.body(
                      size: 10,
                      weight: FontWeight.w900,
                      color: KineticNoirPalette.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                titleChip,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProgressLoadingState extends StatelessWidget {
  const _ProgressLoadingState({required this.currentSession});

  final ActiveExerciseSessionSummary? currentSession;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: KineticNoirPalette.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            currentSession == null
                ? 'Loading recent sessions...'
                : 'Loading history while today keeps updating.',
            style: KineticNoirTypography.body(
              size: 12,
              weight: FontWeight.w700,
              color: KineticNoirPalette.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressFallbackState extends StatelessWidget {
  const _ProgressFallbackState({
    required this.title,
    required this.detail,
    required this.currentSession,
    required this.weightUnit,
    super.key,
  });

  final String title;
  final String detail;
  final ActiveExerciseSessionSummary? currentSession;
  final WeightDisplayUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: KineticNoirTypography.headline(
            size: 17,
            weight: FontWeight.w700,
            color: KineticNoirPalette.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: KineticNoirTypography.body(
            size: 12,
            weight: FontWeight.w700,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        _ProgressMetricTile(
          label: 'TODAY',
          value: _formatSessionStrength(currentSession, weightUnit),
          detail: _formatTodayDetail(currentSession, weightUnit),
        ),
      ],
    );
  }
}

class _ProgressMetricTile extends StatelessWidget {
  const _ProgressMetricTile({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: KineticNoirTypography.body(
              size: 9,
              weight: FontWeight.w900,
              color: KineticNoirPalette.onSurfaceVariant,
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KineticNoirTypography.headline(
              size: 18,
              weight: FontWeight.w700,
              color: KineticNoirPalette.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KineticNoirTypography.body(
              size: 10,
              weight: FontWeight.w700,
              color: KineticNoirPalette.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSparkline extends StatelessWidget {
  const _ProgressSparkline({
    required this.points,
    required this.weightUnit,
  });

  final List<ActiveExerciseTrendPoint> points;
  final WeightDisplayUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = [
      for (var index = 0; index < points.length; index++)
        FlSpot(
          index.toDouble(),
          _kgToDisplayWeight(points[index].comparableStrengthKg, weightUnit),
        ),
    ];
    final minValue = spots.fold<double>(
      spots.first.y,
      (min, spot) => spot.y < min ? spot.y : min,
    );
    final maxValue = spots.fold<double>(
      spots.first.y,
      (max, spot) => spot.y > max ? spot.y : max,
    );
    final minY = minValue <= 0 ? 0.0 : minValue * 0.92;
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.08;
    final safeMaxY = maxY <= minY ? minY + 1 : maxY;
    final maxX = points.length <= 1 ? 1.0 : (points.length - 1).toDouble();

    return SizedBox(
      height: 54,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minY,
          maxY: safeMaxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2.5,
              color: KineticNoirPalette.primary,
              dotData: FlDotData(show: points.length <= 3),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    KineticNoirPalette.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetSummaryLine extends StatelessWidget {
  const _SetSummaryLine({
    required this.label,
    required this.summary,
    required this.weightUnit,
  });

  final String label;
  final ActiveExerciseSessionSummary? summary;
  final WeightDisplayUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: KineticNoirTypography.body(
          size: 11,
          weight: FontWeight.w700,
          color: KineticNoirPalette.onSurfaceVariant,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: KineticNoirTypography.body(
              size: 11,
              weight: FontWeight.w900,
              color: KineticNoirPalette.primary,
              letterSpacing: 0.8,
            ),
          ),
          TextSpan(text: _formatWorkingSetSummary(summary, weightUnit)),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.delta,
    required this.weightUnit,
  });

  final ActiveExerciseProgressDelta delta;
  final WeightDisplayUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    final label = switch (delta.status) {
      ActiveExerciseProgressDeltaStatus.ahead =>
        'AHEAD ${_formatSignedLoad(delta.deltaKg, weightUnit)}',
      ActiveExerciseProgressDeltaStatus.holding => 'HOLDING',
      ActiveExerciseProgressDeltaStatus.below =>
        'BELOW ${_formatSignedLoad(delta.deltaKg, weightUnit)}',
      ActiveExerciseProgressDeltaStatus.pending => 'LOG FIRST SET',
      ActiveExerciseProgressDeltaStatus.noBaseline => 'NEW BASELINE',
    };
    final color = switch (delta.status) {
      ActiveExerciseProgressDeltaStatus.ahead => KineticNoirPalette.primary,
      ActiveExerciseProgressDeltaStatus.holding =>
        KineticNoirPalette.onSurfaceVariant,
      ActiveExerciseProgressDeltaStatus.below => KineticNoirPalette.error,
      ActiveExerciseProgressDeltaStatus.pending =>
        KineticNoirPalette.outlineVariant,
      ActiveExerciseProgressDeltaStatus.noBaseline =>
        KineticNoirPalette.primaryDim,
    };

    return _StatusChip(label: label, color: color);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KineticNoirTypography.body(
          size: 9,
          weight: FontWeight.w900,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

String _formatSessionStrength(
  ActiveExerciseSessionSummary? summary,
  WeightDisplayUnit unit,
) {
  if (summary == null) {
    return '--';
  }
  return _formatDisplayLoad(summary.comparableStrengthKg, unit);
}

String _formatBaseline(
  ActiveExerciseProgressBaseline? baseline,
  WeightDisplayUnit unit,
) {
  if (baseline == null) {
    return '--';
  }
  return _formatDisplayLoad(baseline.comparableStrengthKg, unit);
}

String _formatSessionDetail(
  ActiveExerciseSessionSummary? summary,
  WeightDisplayUnit unit,
) {
  if (summary == null) {
    return 'No history';
  }
  return '${DateFormat('MMM d').format(summary.date)} - '
      '${summary.setCount} sets - top ${_formatDisplayLoad(summary.topWeightKg, unit)} x ${summary.topReps}';
}

String _formatTodayDetail(
  ActiveExerciseSessionSummary? summary,
  WeightDisplayUnit unit,
) {
  if (summary == null) {
    return 'No completed sets';
  }
  return '${summary.setCount} completed - ${_formatDisplayLoad(summary.volumeKg, unit, suffix: '${unit.label}-reps')}';
}

String _formatWorkingSetSummary(
  ActiveExerciseSessionSummary? summary,
  WeightDisplayUnit unit,
) {
  if (summary == null) {
    return 'No completed sets';
  }

  final workingSets =
      summary.workingSets.isEmpty ? summary.sets : summary.workingSets;
  return workingSets.take(3).map((set) {
    return '${_formatDisplayLoad(set.weightKg, unit)} x ${set.reps}';
  }).join(' / ');
}

String _formatDisplayLoad(
  double valueKg,
  WeightDisplayUnit unit, {
  String? suffix,
}) {
  final displayValue = _kgToDisplayWeight(valueKg, unit);
  return '${_formatNumber(displayValue)} ${suffix ?? unit.label}';
}

String _formatSignedLoad(double valueKg, WeightDisplayUnit unit) {
  final displayValue = _kgToDisplayWeight(valueKg, unit);
  final sign = displayValue > 0 ? '+' : '';
  return '$sign${_formatNumber(displayValue)} ${unit.label}';
}

double _kgToDisplayWeight(double weightKg, WeightDisplayUnit unit) {
  return unit == WeightDisplayUnit.kg ? weightKg : weightKg * _kgToLbFactor;
}

String _formatNumber(double value) {
  if (!value.isFinite) {
    return '0';
  }

  final absValue = value.abs();
  if (absValue >= 1000) {
    final scaled = value / 1000;
    return '${scaled.toStringAsFixed(absValue >= 10000 ? 0 : 1)}k';
  }

  final decimals = absValue >= 100 ? 0 : 1;
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) {
    return rounded.toStringAsFixed(0);
  }
  return value.toStringAsFixed(decimals);
}
