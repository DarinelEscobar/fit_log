import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/history_providers.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';

class ExerciseLogsScreen extends ConsumerWidget {
  final int exerciseId;
  final String exerciseName;
  const ExerciseLogsScreen({super.key, required this.exerciseId, required this.exerciseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogs = ref.watch(logsByExerciseProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: asyncLogs.when(
        data: (logs) => _Chart(data: _summaries(logs)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<_WeekSummary> _summaries(List<WorkoutLogEntry> logs) {
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
      result.add(_WeekSummary(k, volume, entries.first));
    }
    return result;
  }
}

class _WeekSummary {
  final DateTime weekStart;
  final double volume;
  final WorkoutLogEntry top;
  _WeekSummary(this.weekStart, this.volume, this.top);
}

class _Chart extends StatelessWidget {
  final List<_WeekSummary> data;
  const _Chart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }
    final spotsWeight = <FlSpot>[];
    final spotsVolume = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < data.length; i++) {
      spotsWeight.add(FlSpot(i.toDouble(), data[i].top.weight));
      spotsVolume.add(FlSpot(i.toDouble(), data[i].volume));
      labels.add('W${i + 1}');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            getTooltipItems: (touched) {
              return touched.map((e) {
                final w = data[e.spotIndex];
                return LineTooltipItem(
                  '${w.top.reps} reps\nRIR ${w.top.rir}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, __) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Text(labels[i]);
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spotsWeight,
              isCurved: false,
              barWidth: 3,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
            LineChartBarData(
              spots: spotsVolume,
              isCurved: false,
              barWidth: 3,
              color: Colors.green,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
              yAxis: 1,
            ),
          ],
          minY: 0,
          extraLinesData: ExtraLinesData(horizontalLines: []),
        ),
      ),
    );
  }
}
