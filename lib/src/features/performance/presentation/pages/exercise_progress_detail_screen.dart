import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../routines/presentation/models/exercise_list_view_data.dart';
import '../models/performance_models.dart';
import '../providers/performance_providers.dart';

class ExerciseProgressDetailScreen extends ConsumerWidget {
  const ExerciseProgressDetailScreen({
    required this.exercise,
    super.key,
  });

  final ExerciseListItemView exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData =
        ref.watch(exerciseProgressDetailProvider(exercise.exerciseId));

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: KineticNoirPalette.onSurfaceVariant,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PERFORMANCE',
          style: KineticNoirTypography.headline(
            size: 24,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: KineticNoirPalette.surfaceBright,
              child: Icon(
                Icons.person_rounded,
                color: KineticNoirPalette.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KineticNoirPalette.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Unable to load progress detail.\n$error',
              textAlign: TextAlign.center,
              style: KineticNoirTypography.body(
                size: 15,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ),
        data: (summary) => SafeArea(
          bottom: false,
          child: CustomScrollView(
            cacheExtent: 800,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _ExerciseHeader(exercise: exercise),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _KeyStats(summary: summary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _ProgressChart(summary: summary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _MuscleFocusCard(exercise: exercise),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                sliver: SliverToBoxAdapter(
                  child: _RecentSessions(summary: summary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({required this.exercise});

  final ExerciseListItemView exercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TagChip(label: exercise.category, accent: KineticNoirPalette.primary),
            const SizedBox(width: 8),
            _TagChip(
              label: exercise.mainMuscleGroup,
              accent: KineticNoirPalette.primaryDim,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          exercise.name,
          key: const Key('exercise-progress-title'),
          style: KineticNoirTypography.headline(
            size: 34,
            weight: FontWeight.w700,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          exercise.description,
          style: KineticNoirTypography.body(
            size: 15,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: KineticNoirTypography.body(
          size: 10,
          weight: FontWeight.w800,
          color: accent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _KeyStats extends StatelessWidget {
  const _KeyStats({required this.summary});

  final ExerciseProgressDetailData summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.22,
      children: [
        _StatCard(
          label: 'EST. 1RM',
          value: _formatKg(summary.estimatedOneRmKg),
          suffix: 'kg',
        ),
        _StatCard(
          label: 'LAST SESSION',
          value: _formatKg(summary.lastWeightKg),
          suffix: 'kg × ${summary.lastReps}',
        ),
        _StatCard(
          label: 'TOTAL VOLUME',
          value: _formatKg(summary.totalVolumeKg),
          suffix: 'kg·reps',
        ),
        _StatCard(
          label: 'LAST DATE',
          value: summary.lastSessionDate == null
              ? '--'
              : _formatRelativeDate(summary.lastSessionDate!),
          suffix: '',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(16),
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
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: KineticNoirTypography.headline(
              size: 28,
              weight: FontWeight.w700,
              color: KineticNoirPalette.onSurface,
            ),
          ),
          if (suffix.isNotEmpty)
            Text(
              suffix,
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w700,
                color: KineticNoirPalette.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.summary});

  final ExerciseProgressDetailData summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '1RM Progression',
                style: KineticNoirTypography.headline(
                  size: 19,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz_rounded,
                color: KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _ProgressChartBody(points: summary.trend),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: KineticNoirPalette.primary, text: '1RM'),
              SizedBox(width: 16),
              _Legend(color: KineticNoirPalette.primaryDim, text: 'Volume'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: KineticNoirTypography.body(
            size: 11,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProgressChartBody extends StatelessWidget {
  const _ProgressChartBody({required this.points});

  final List<ExerciseProgressTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text(
          'No progress history yet',
          style: TextStyle(color: KineticNoirPalette.onSurfaceVariant),
        ),
      );
    }

    final weightSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].oneRmKg),
    ];
    final rawVolumeSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].volumeKg),
    ];
    final maxOneRm = points.fold<double>(
      0,
      (peak, point) => point.oneRmKg > peak ? point.oneRmKg : peak,
    );
    final maxVolume = points.fold<double>(
      0,
      (peak, point) => point.volumeKg > peak ? point.volumeKg : peak,
    );
    final scale = maxOneRm > 0 ? maxVolume / maxOneRm : 1.0;
    final volumeSpots = rawVolumeSpots
        .map((spot) => FlSpot(spot.x, spot.y / scale))
        .toList(growable: false);

    final maxY = (maxOneRm <= 0 ? 1.0 : maxOneRm * 1.15).toDouble();
    final maxX = points.length <= 1 ? 1.0 : (points.length - 1).toDouble();
    final interval = points.length <= 4 ? 1.0 : (points.length / 3).ceilToDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 3,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 3,
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                value <= 0 ? '' : _formatCompactKg(value),
                style: KineticNoirTypography.body(
                  size: 9,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                if (points.length > 4 &&
                    index != 0 &&
                    index != points.length - 1 &&
                    index % interval != 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DateFormat('MM/dd').format(points[index].weekStart),
                  style: KineticNoirTypography.body(
                    size: 9,
                    weight: FontWeight.w700,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: weightSpots,
            isCurved: true,
            barWidth: 3,
            color: KineticNoirPalette.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  KineticNoirPalette.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: volumeSpots,
            isCurved: true,
            barWidth: 2.5,
            color: KineticNoirPalette.primaryDim,
            dashArray: const [6, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (items) => [
              for (final item in items)
                LineTooltipItem(
                  item.barIndex == 0
                      ? '${_formatCompactKg(points[item.spotIndex].oneRmKg)} kg\n1RM'
                      : '${_formatCompactKg(points[item.spotIndex].volumeKg)} kg·reps\nVolume',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuscleFocusCard extends StatelessWidget {
  const _MuscleFocusCard({required this.exercise});

  final ExerciseListItemView exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Focus',
            style: KineticNoirTypography.headline(
              size: 19,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _FocusRow(
            label: 'PRIMARY',
            value: exercise.mainMuscleGroup,
            percent: 100,
          ),
          const SizedBox(height: 12),
          _FocusRow(
            label: 'CATEGORY',
            value: exercise.category,
            percent: 72,
            accent: KineticNoirPalette.primaryDim,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: '${exercise.sets} SETS', accent: KineticNoirPalette.primary),
              _TagChip(
                label: '${exercise.reps} REPS',
                accent: KineticNoirPalette.primaryDim,
              ),
              _TagChip(
                label: '${exercise.restSeconds}s REST',
                accent: KineticNoirPalette.primary,
              ),
              if (exercise.weight > 0)
                _TagChip(
                  label: '${_formatCompactKg(exercise.weight)} kg LOAD',
                  accent: KineticNoirPalette.primaryDim,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({
    required this.label,
    required this.value,
    required this.percent,
    this.accent = KineticNoirPalette.primary,
  });

  final String label;
  final String value;
  final int percent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KineticNoirTypography.body(
                size: 10,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 1.3,
              ),
            ),
            Text(
              value,
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 10,
            backgroundColor: KineticNoirPalette.surfaceBright,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.summary});

  final ExerciseProgressDetailData summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sessions',
              style: KineticNoirTypography.headline(
                size: 19,
                weight: FontWeight.w700,
              ),
            ),
            Text(
              'kg only',
              style: KineticNoirTypography.body(
                size: 10,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (summary.recentSessions.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceLow,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Text(
              'No previous sessions recorded for this exercise yet.',
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          )
        else
          Column(
            children: [
              for (final session in summary.recentSessions) ...[
                _SessionCard(session: session),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ExerciseRecentSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceBright,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: KineticNoirPalette.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatRelativeDate(session.date),
                  style: KineticNoirTypography.headline(
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.setCount} sets • ${_formatKg(session.volumeKg)} kg·reps',
                  style: KineticNoirTypography.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatKg(session.topWeightKg)} kg',
                style: KineticNoirTypography.headline(
                  size: 20,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${session.topReps} reps • ${_formatKg(session.topOneRmKg)} kg est. 1RM',
                textAlign: TextAlign.right,
                style: KineticNoirTypography.body(
                  size: 10,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatKg(double value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

String _formatCompactKg(double value) => _formatKg(value);

String _formatRelativeDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  if (normalized == todayDate) {
    return 'Today';
  }
  if (normalized == todayDate.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }
  return DateFormat('MMM d').format(normalized);
}
