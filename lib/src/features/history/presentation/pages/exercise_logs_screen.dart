// lib/src/features/history/presentation/pages/exercise_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_session.dart';
import '../providers/history_providers.dart';

class ExerciseLogsScreen extends ConsumerWidget {
  final int exerciseId;
  final String exerciseName;

  const ExerciseLogsScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogs = ref.watch(logsByExerciseProvider(exerciseId));
    final asyncSessions = ref.watch(workoutSessionsProvider);

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
          exerciseName,
          style: KineticNoirTypography.headline(
            size: 20,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
      ),
      body: asyncLogs.when(
        data: (logs) => asyncSessions.when(
          data: (sessions) {
            final summaries = _summaries(logs, sessions);
            if (summaries.isEmpty) {
              return Center(
                child: Text(
                  'No logs recorded yet for this exercise.',
                  style: KineticNoirTypography.body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ),
              );
            }
            return _Chart(data: summaries);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: KineticNoirPalette.primary),
          ),
          error: (e, __) => Center(
            child: Text(
              'Error: $e',
              style: KineticNoirTypography.body(
                size: 14,
                color: KineticNoirPalette.error,
              ),
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: KineticNoirPalette.primary),
        ),
        error: (e, __) => Center(
          child: Text(
            'Error: $e',
            style: KineticNoirTypography.body(
              size: 14,
              color: KineticNoirPalette.error,
            ),
          ),
        ),
      ),
    );
  }

  List<_WeekSummary> _summaries(
    List<WorkoutLogEntry> logs,
    List<WorkoutSession> sessions,
  ) {
    final sessionMap = <DateTime, WorkoutSession>{};
    for (final s in sessions) {
      final monday = s.date.subtract(Duration(days: s.date.weekday - 1));
      final key = DateTime(monday.year, monday.month, monday.day);
      sessionMap[key] = s;
    }

    final map = <DateTime, List<WorkoutLogEntry>>{};
    for (final l in logs) {
      final monday = l.date.subtract(Duration(days: l.date.weekday - 1));
      final key = DateTime(monday.year, monday.month, monday.day);
      map.putIfAbsent(key, () => []).add(l);
    }
    final sorted = map.keys.toList()..sort();
    final result = <_WeekSummary>[];
    for (final k in sorted) {
      final entries = map[k]!;
      final volume = entries.fold<double>(0, (s, e) => s + e.reps * e.weight);
      entries.sort((a, b) {
        final cw = b.weight.compareTo(a.weight);
        if (cw != 0) return cw;
        return a.rir.compareTo(b.rir);
      });
      result.add(_WeekSummary(k, volume, entries.first, sessionMap[k]));
    }
    return result;
  }
}

class _WeekSummary {
  final DateTime week;
  final double volume;
  final WorkoutLogEntry top;
  final WorkoutSession? session;

  _WeekSummary(this.week, this.volume, this.top, this.session);
}

class _Chart extends StatefulWidget {
  final List<_WeekSummary> data;

  const _Chart({required this.data});

  @override
  State<_Chart> createState() => _ChartState();
}

class _ChartState extends State<_Chart> {
  double _interval(double max) {
    if (max <= 0) return 1;
    return (max / 5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final labels =
            widget.data.map((w) => DateFormat('MM/dd').format(w.week)).toList();

        final weightSpots = List.generate(widget.data.length,
            (i) => FlSpot(i.toDouble(), widget.data[i].top.weight));
        final rawVolumeSpots = List.generate(widget.data.length,
            (i) => FlSpot(i.toDouble(), widget.data[i].volume));

        final maxWeight = widget.data
            .fold<double>(0, (p, e) => e.top.weight > p ? e.top.weight : p);
        final maxVolume =
            widget.data.fold<double>(0, (p, e) => e.volume > p ? e.volume : p);

        final scale = maxWeight > 0 ? maxVolume / maxWeight : 1.0;
        final volumeSpots = rawVolumeSpots
            .map((s) => FlSpot(s.x, s.y / scale))
            .toList();

        final stepWeight = _interval(maxWeight);
        final stepVolume = _interval(maxVolume) / scale;

        final maxY = maxWeight <= 0 ? 100.0 : maxWeight * 1.1;

        final chart = LineChart(
          LineChartData(
            minX: 0,
            maxX: widget.data.length > 1
                ? (widget.data.length - 1).toDouble()
                : 1.0,
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: Text(
                  'Weight (kg)',
                  style: KineticNoirTypography.body(
                    size: 10,
                    weight: FontWeight.w700,
                    color: KineticNoirPalette.primary,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: stepWeight > 0 ? stepWeight : 20,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: KineticNoirTypography.body(
                      size: 10,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                  reservedSize: 36,
                ),
              ),
              rightTitles: AxisTitles(
                axisNameWidget: Text(
                  'Volume (kg·reps)',
                  style: KineticNoirTypography.body(
                    size: 10,
                    weight: FontWeight.w700,
                    color: const Color(0xFF64FFDA),
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: stepVolume > 0 ? stepVolume : 50,
                  getTitlesWidget: (v, _) => Text(
                    (v * scale).toInt().toString(),
                    style: KineticNoirTypography.body(
                      size: 10,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                  reservedSize: 44,
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text(
                  'Week',
                  style: KineticNoirTypography.body(
                    size: 10,
                    weight: FontWeight.w700,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox();
                    final w = widget.data[i];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          labels[i],
                          style: KineticNoirTypography.body(
                            size: 10,
                            weight: FontWeight.w700,
                            color: KineticNoirPalette.onSurface,
                          ),
                        ),
                        Text(
                          'R:${w.top.reps} RIR:${w.top.rir}',
                          style: KineticNoirTypography.body(
                            size: 9,
                            color: KineticNoirPalette.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touched) => touched.map((t) {
                  final w = widget.data[t.spotIndex];
                  final reps = w.top.reps;
                  final rir = w.top.rir;
                  final fatigue = w.session?.fatigueLevel ?? '';
                  final mood = w.session?.mood ?? '';
                  final dur = w.session?.durationMinutes ?? 0;
                  final vol = w.volume.toInt();
                  final wt = w.top.weight.toInt();
                  return LineTooltipItem(
                    'P:$wt kg • V:$vol\nR: $reps • RIR $rir\nFatigue: $fatigue • $dur min\nMood: $mood',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: weightSpots,
                isCurved: false,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                color: KineticNoirPalette.primary,
              ),
              LineChartBarData(
                spots: volumeSpots,
                isCurved: false,
                barWidth: 3,
                dashArray: const [5, 5],
                dotData: const FlDotData(show: false),
                color: const Color(0xFF64FFDA),
              ),
            ],
            extraLinesData: const ExtraLinesData(horizontalLines: []),
          ),
        );

        final chartWidget = orientation == Orientation.portrait
            ? Expanded(child: chart)
            : SizedBox(height: 200, child: chart);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              chartWidget,
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(color: KineticNoirPalette.primary, text: 'Weight'),
                  SizedBox(width: 20),
                  _Legend(color: Color(0xFF64FFDA), text: 'Volume'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: KineticNoirTypography.body(
            size: 12,
            weight: FontWeight.w700,
            color: KineticNoirPalette.onSurface,
          ),
        ),
      ],
    );
  }
}
