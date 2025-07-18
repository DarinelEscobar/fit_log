// lib/src/features/history/presentation/pages/exercise_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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

class _Chart extends StatefulWidget {
  final List<_WeekSummary> data;

  const _Chart({Key? key, required this.data}) : super(key: key);

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

        final maxY = maxWeight;

        final chart = LineChart(
          LineChartData(
            minX: 0,
            maxX: (widget.data.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: const Text('Peso (kg)'),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: stepWeight,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString()),
                  reservedSize: 40,
                ),
              ),
              rightTitles: AxisTitles(
                axisNameWidget: const Text('Volumen (kg·reps)'),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: stepVolume,
                  getTitlesWidget: (v, _) => Text((v * scale).toInt().toString()),
                  reservedSize: 48,
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text('Semana'),
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
                        Text(labels[i]),
                        Text('R:${w.top.reps} RIR:${w.top.rir}',
                            style: const TextStyle(fontSize: 10)),
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
                  final w = widget.data[t.spotIndex];
                  final reps = w.top.reps;
                  final rir = w.top.rir;
                  final fatigue = w.session?.fatigueLevel ?? '';
                  final mood = w.session?.mood ?? '';
                  final dur = w.session?.durationMinutes ?? 0;
                  final vol = w.volume.toInt();
                  final wt = w.top.weight.toInt();
                  return LineTooltipItem(
                    'P:$wt • V:$vol\nR: $reps • RIR $rir\nFatiga: $fatigue • $dur min\nMood: $mood',
                    const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: weightSpots,
                isCurved: false,
                barWidth: 3,
                dotData: FlDotData(show: true),
                color: Colors.blue,
              ),
              LineChartBarData(
                spots: volumeSpots,
                isCurved: false,
                barWidth: 3,
                dashArray: const [5, 5],
                dotData: FlDotData(show: false),
                color: Colors.green,
              ),
            ],
            extraLinesData: ExtraLinesData(horizontalLines: []),
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
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({Key? key, required this.color, required this.text})
      : super(key: key);

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

