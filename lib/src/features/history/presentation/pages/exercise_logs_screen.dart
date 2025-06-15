import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/history_providers.dart';
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

    final maxWeight =
        data.map((e) => e.top.weight).fold<double>(0, (p, c) => c > p ? c : p);
    final maxVolume =
        data.map((e) => e.volume).fold<double>(0, (p, c) => c > p ? c : p);

      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (touched) {
                      return touched.map((e) {
                        final w = data[e.spotIndex];
                        return LineTooltipItem(
                          'R: ${w.top.reps} • RIR ${w.top.rir}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  verticalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('Peso (kg)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxWeight <= 0 ? 1 : (maxWeight / 4).ceilToDouble(),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: const Text('Volumen (kg·reps)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: maxVolume <= 0 ? 1 : (maxVolume / 4).ceilToDouble(),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Semana'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, __) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return Text(labels[i]);
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Legend(color: Colors.blue, text: 'Peso'),
              SizedBox(width: 16),
              _Legend(color: Colors.green, text: 'Volumen'),
            ],
          ),
        ],

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
              },
            ),
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
            ),
          ],
          minY: 0,
          extraLinesData: ExtraLinesData(horizontalLines: []),
        ),
      ),
    );
  }
}
