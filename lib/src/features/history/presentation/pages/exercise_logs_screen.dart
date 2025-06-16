import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../providers/history_providers.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_session.dart';
import 'package:intl/intl.dart';

class ExerciseLogsScreen extends ConsumerWidget {
  final int exerciseId;
  final String exerciseName;

  const ExerciseLogsScreen({
    Key? key,
    required this.exerciseId,
    required this.exerciseName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogs = ref.watch(logsByExerciseProvider(exerciseId));
    final asyncSessions = ref.watch(workoutSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: asyncLogs.when(
        data: (logs) => asyncSessions.when(
          data: (sessions) => _Chart(data: _summaries(logs, sessions)),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
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

class _Chart extends StatelessWidget {
  final List<_WeekSummary> data;

  const _Chart({Key? key, required this.data}) : super(key: key);

  double _interval(double max) {
    if (max <= 0) return 1;
    final raw = max / 4; // aim for ~4 intervals
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final residual = raw / magnitude;
    double nice;
    if (residual <= 1) {
      nice = 1;
    } else if (residual <= 2) {
      nice = 2;
    } else if (residual <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final maxWeight = data.map((e) => e.top.weight).fold<double>(0, (p, c) => c > p ? c : p);
    final maxVolume = data.map((e) => e.volume).fold<double>(0, (p, c) => c > p ? c : p);
    final labels = data.map((w) => DateFormat('MM/dd').format(w.week)).toList();
    final spotsWeight = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].top.weight));
    final spotsVolume = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].volume));
    final stepWeight = _interval(maxWeight);
    final stepVolume = _interval(maxVolume);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('Peso (kg)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: stepWeight,
                      getTitlesWidget: (v, meta) => Text(v.toInt().toString()),
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: const Text('Volumen (kg·reps)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: stepVolume,
                      getTitlesWidget: (v, meta) => Text(v.toInt().toString()),
                      reservedSize: 48,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Semana'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        final w = data[i];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(labels[i]),
                            Text('R:${w.top.reps} RIR:${w.top.rir}', style: const TextStyle(fontSize: 10)),
                          ],
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (touched) => touched.map((t) {
                      final w = data[t.spotIndex];
                      final reps = w.top.reps;
                      final rir = w.top.rir;
                      final fatigue = w.session?.fatigueLevel ?? '';
                      final mood = w.session?.mood ?? '';
                      final dur = w.session?.durationMinutes ?? 0;
                      return LineTooltipItem(
                        'R: $reps • RIR $rir\nFatiga: $fatigue • $dur min\nMood: $mood',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsWeight,
                    isCurved: false,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    color: Colors.blue,
                  ),
                  LineChartBarData(
                    spots: spotsVolume,
                    isCurved: false,
                    barWidth: 3,
                    dashArray: [5, 5],
                    dotData: FlDotData(show: false),
                    color: Colors.green,
                  ),
                ],
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

  const _Legend({Key? key, required this.color, required this.text}) : super(key: key);

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
