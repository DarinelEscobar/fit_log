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

class ActiveExerciseProgressPanel extends ConsumerStatefulWidget {
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
  ConsumerState<ActiveExerciseProgressPanel> createState() =>
      _ActiveExerciseProgressPanelState();
}

class _ActiveExerciseProgressPanelState
    extends ConsumerState<ActiveExerciseProgressPanel> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final request = ActiveExerciseProgressRequest(
      exerciseId: widget.exerciseId,
      sessionDate: widget.sessionDate,
    );
    final asyncInsight = ref.watch(activeExerciseProgressProvider(request));
    final currentSession = ActiveExerciseProgressCalculator.buildCurrentSession(
      widget.currentLogs,
    );

    return asyncInsight.when(
      loading: () => _ProgressShell(
        key: Key('active-progress-panel-${widget.exerciseId}'),
        exerciseId: widget.exerciseId,
        expanded: _expanded,
        onToggle: _toggleExpanded,
        titleChip: const _StatusChip(
          label: 'LOADING',
          color: KineticNoirPalette.outlineVariant,
        ),
        lastSummary: 'Loading history...',
        todaySummary: _formatCompactToday(
          currentSession,
          widget.weightUnit,
        ),
        child: _ProgressLoadingState(currentSession: currentSession),
      ),
      error: (error, _) => _ProgressShell(
        key: Key('active-progress-panel-${widget.exerciseId}'),
        exerciseId: widget.exerciseId,
        expanded: _expanded,
        onToggle: _toggleExpanded,
        titleChip: const _StatusChip(
          key: Key('active-progress-error-chip'),
          label: 'UNAVAILABLE',
          color: KineticNoirPalette.error,
        ),
        lastSummary: 'Progress unavailable',
        todaySummary: _formatCompactToday(
          currentSession,
          widget.weightUnit,
        ),
        summaryKey: Key('active-progress-error-${widget.exerciseId}'),
        child: _ProgressFallbackState(
          title: 'Progress unavailable',
          detail: 'Logging is still enabled for this exercise.',
          currentSession: currentSession,
          weightUnit: widget.weightUnit,
        ),
      ),
      data: (insight) {
        final delta = ActiveExerciseProgressCalculator.compareCurrentToBaseline(
          currentSession: currentSession,
          baseline: insight.recentBaseline,
        );

        if (!insight.hasHistory) {
          return _ProgressShell(
            key: Key('active-progress-panel-${widget.exerciseId}'),
            exerciseId: widget.exerciseId,
            expanded: _expanded,
            onToggle: _toggleExpanded,
            titleChip: _DeltaChip(
              delta: delta,
              weightUnit: widget.weightUnit,
            ),
            lastSummary: 'No previous session',
            todaySummary: _formatCompactToday(
              currentSession,
              widget.weightUnit,
            ),
            child: _ProgressFallbackState(
              title: 'No previous sessions yet',
              detail: 'Complete sets now to start a baseline.',
              currentSession: currentSession,
              weightUnit: widget.weightUnit,
            ),
          );
        }

        return _ProgressShell(
          key: Key('active-progress-panel-${widget.exerciseId}'),
          exerciseId: widget.exerciseId,
          expanded: _expanded,
          onToggle: _toggleExpanded,
          titleChip: _DeltaChip(
            delta: delta,
            weightUnit: widget.weightUnit,
          ),
          lastSummary: _formatCompactLast(
            insight.lastSession,
            widget.weightUnit,
          ),
          todaySummary: _formatCompactToday(
            currentSession,
            widget.weightUnit,
          ),
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
                        widget.weightUnit,
                      ),
                      detail: _formatSessionDetail(
                        insight.lastSession,
                        widget.weightUnit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProgressMetricTile(
                      label: 'TREND',
                      value: _formatBaseline(
                        insight.recentBaseline,
                        widget.weightUnit,
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
                        widget.weightUnit,
                      ),
                      detail: _formatTodayDetail(
                        currentSession,
                        widget.weightUnit,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SetComparisonChart(
                lastSession: insight.lastSession,
                currentSession: currentSession,
                weightUnit: widget.weightUnit,
              ),
              const SizedBox(height: 10),
              _SetSummaryLine(
                label: 'LAST',
                summary: insight.lastSession,
                weightUnit: widget.weightUnit,
              ),
              const SizedBox(height: 6),
              _SetSummaryLine(
                label: 'TODAY',
                summary: currentSession,
                weightUnit: widget.weightUnit,
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
    required this.exerciseId,
    required this.expanded,
    required this.onToggle,
    required this.titleChip,
    required this.lastSummary,
    required this.todaySummary,
    required this.child,
    this.summaryKey,
    super.key,
  });

  final int exerciseId;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget titleChip;
  final String lastSummary;
  final String todaySummary;
  final Widget child;
  final Key? summaryKey;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
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
            Semantics(
              button: true,
              expanded: expanded,
              label:
                  expanded ? 'Collapse live progress' : 'Expand live progress',
              child: InkWell(
                key: Key('active-progress-toggle-$exerciseId'),
                onTap: onToggle,
                borderRadius: BorderRadius.circular(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                    child: Row(
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
                        const SizedBox(width: 6),
                        Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: KineticNoirPalette.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              key: summaryKey,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _CompactProgressValue(label: 'LAST', value: lastSummary),
                  _CompactProgressValue(label: 'TODAY', value: todaySummary),
                ],
              ),
            ),
            AnimatedSize(
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactProgressValue extends StatelessWidget {
  const _CompactProgressValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: KineticNoirTypography.body(
          size: 11,
          weight: FontWeight.w700,
          color: KineticNoirPalette.onSurfaceVariant,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: KineticNoirTypography.body(
              size: 10,
              weight: FontWeight.w900,
              color: KineticNoirPalette.primary,
              letterSpacing: 0.8,
            ),
          ),
          TextSpan(text: value),
        ],
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

class _SetComparisonChart extends StatelessWidget {
  const _SetComparisonChart({
    required this.lastSession,
    required this.currentSession,
    required this.weightUnit,
  });

  final ActiveExerciseSessionSummary? lastSession;
  final ActiveExerciseSessionSummary? currentSession;
  final WeightDisplayUnit weightUnit;

  @override
  Widget build(BuildContext context) {
    final lastSpots = _setComparisonSpots(lastSession, weightUnit);
    final todaySpots = _setComparisonSpots(currentSession, weightUnit);
    final allSpots = [...lastSpots, ...todaySpots];

    if (allSpots.isEmpty) {
      return const SizedBox.shrink();
    }

    final minValue = allSpots.fold<double>(
      allSpots.first.y,
      (min, spot) => spot.y < min ? spot.y : min,
    );
    final maxValue = allSpots.fold<double>(
      allSpots.first.y,
      (max, spot) => spot.y > max ? spot.y : max,
    );
    final maxSet = allSpots.fold<double>(
      allSpots.first.x,
      (max, spot) => spot.x > max ? spot.x : max,
    );
    final minY = minValue <= 0 ? 0.0 : minValue * 0.92;
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.08;
    final safeMaxY = maxY <= minY ? minY + 1 : maxY;
    final safeMaxX = maxSet <= 1 ? 1.2 : maxSet;

    return Container(
      key: const Key('active-progress-comparison-chart'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'COMPARISON',
                  style: KineticNoirTypography.body(
                    size: 9,
                    weight: FontWeight.w900,
                    color: KineticNoirPalette.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                'EST. 1RM / SET',
                style: KineticNoirTypography.body(
                  size: 9,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurfaceVariant,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: safeMaxX,
                minY: minY,
                maxY: safeMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (safeMaxY - minY) / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: KineticNoirPalette.outlineVariant
                        .withValues(alpha: 0.12),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  if (lastSpots.isNotEmpty)
                    LineChartBarData(
                      spots: lastSpots,
                      isCurved: false,
                      barWidth: 2,
                      color: KineticNoirPalette.onSurfaceVariant
                          .withValues(alpha: 0.76),
                      dotData: FlDotData(show: lastSpots.length <= 4),
                    ),
                  if (todaySpots.isNotEmpty)
                    LineChartBarData(
                      spots: todaySpots,
                      isCurved: false,
                      barWidth: 3,
                      color: KineticNoirPalette.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            KineticNoirPalette.primary.withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (lastSpots.isNotEmpty)
                _ChartLegendItem(
                  key: const Key('active-progress-comparison-last-legend'),
                  label: 'LAST',
                  color: KineticNoirPalette.onSurfaceVariant
                      .withValues(alpha: 0.76),
                ),
              if (todaySpots.isNotEmpty)
                const _ChartLegendItem(
                  key: Key('active-progress-comparison-today-legend'),
                  label: 'TODAY',
                  color: KineticNoirPalette.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: KineticNoirTypography.body(
            size: 9,
            weight: FontWeight.w900,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
      ],
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

String _formatCompactLast(
  ActiveExerciseSessionSummary? summary,
  WeightDisplayUnit unit,
) {
  if (summary == null) {
    return 'No previous session';
  }
  return '${_formatDisplayLoad(summary.topWeightKg, unit)} x ${summary.topReps}';
}

String _formatCompactToday(
  ActiveExerciseSessionSummary? summary,
  WeightDisplayUnit unit,
) {
  if (summary == null || summary.sets.isEmpty) {
    return 'No sets logged';
  }

  final latestSet = summary.sets.reduce(
    (current, candidate) =>
        candidate.setNumber > current.setNumber ? candidate : current,
  );
  return '${_formatDisplayLoad(latestSet.weightKg, unit)} x ${latestSet.reps}';
}

List<FlSpot> _setComparisonSpots(
  ActiveExerciseSessionSummary? summary,
  WeightDisplayUnit unit,
) {
  if (summary == null) {
    return const [];
  }

  final sets = [...summary.sets]
    ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

  return [
    for (final set in sets)
      if (set.estimatedOneRmKg.isFinite)
        FlSpot(
          set.setNumber.toDouble(),
          _kgToDisplayWeight(set.estimatedOneRmKg, unit),
        ),
  ];
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
