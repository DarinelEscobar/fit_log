import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/history_providers.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import 'package:intl/intl.dart';

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

// Summarizes a week's top lift and total volume
class _WeekSummary {
  final DateTime week;
  final double volume;
  final WorkoutLogEntry top;
  _WeekSummary(this.week, this.volume, this.top);
}

class _Chart extends StatelessWidget {
  final List<_WeekSummary> data;
  const _Chart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxWeight = data.map((e) => e.top.weight).fold<double>(0, (p, c) => c > p ? c : p);
    final maxVolume = data.map((e) => e.volume).fold<double>(0, (p, c) => c > p ? c : p);
    final labels = data.map((w) => DateFormat('MM/dd').format(w.week)).toList();
    final spotsWeight = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].top.weight));
    final spotsVolume = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].volume));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
  double _upperBound(double max, double step) {
    if (max <= 0) return step;
    return ((max / step).ceil() * step).toDouble();
  }

    final stepWeight = _interval(maxWeight);
    final stepVolume = _interval(maxVolume);
              LineChartData(
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                      final item = touched.firstWhere(
                        (e) => e.barIndex == 0,
                        orElse: () => touched.first,
                      );
                      final w = data[item.spotIndex];
                      final reps = w.top?.reps ?? 0;
                      final rir = w.top?.rir ?? 0;
                      final fatigue = w.session?.fatigueLevel ?? '';
                      final mood = w.session?.mood ?? '';
                      final dur = w.session?.durationMinutes ?? 0;
                      final text =
                          'R: $reps • RIR $rir\nFatiga: $fatigue • $dur min\nMood: $mood';
                      return [
                        LineTooltipItem(
                        )
                      ];
                    axisNameWidget: const Text('Peso (kg)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: stepWeight,
                      getTitlesWidget: (v, __) => Text(v.toInt().toString()),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: const Text('Volumen (kg·reps)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: stepVolume,
                      getTitlesWidget: (v, __) => Text(v.toInt().toString()),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Semana'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                        if (w.top == null) {
                          return _LabelDotPainter(
                            label: '💤',
                            color: Colors.grey,
                          );
                        }
                        final label = 'R:${w.top!.reps}\nRIR:${w.top!.rir}';
                        final i = value.toInt();
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
                  ),
                ],
                minY: 0,
                extraLinesData: ExtraLinesData(horizontalLines: []),
              ),
            ),
          ),
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
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({super.key, required this.color, required this.text});

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