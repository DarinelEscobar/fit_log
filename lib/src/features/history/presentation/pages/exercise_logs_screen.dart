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

class _Chart extends StatelessWidget {
  final List<_WeekSummary> data;

  const _Chart({Key? key, required this.data}) : super(key: key);

  double _interval(double max) {
    if (max <= 0) return 1;
    return (max / 5).ceilToDouble();
  }

  LineChart _buildLine({
    required List<FlSpot> spots,
    required double max,
    required List<String> labels,
    required String axisLabel,
    required Color color,
    required List<LineTooltipItem> Function(int index) tooltipBuilder,
  }) {
    final step = _interval(max);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (labels.length - 1).toDouble(),
        minY: 0,
        maxY: max,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(axisLabel),
            sideTitles: SideTitles(
              showTitles: true,
              interval: step,
              getTitlesWidget: (v, _) => Text(v.toInt().toString()),
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Semana'),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
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
            getTooltipItems: (touched) => touched
                .map((t) => tooltipBuilder(t.spotIndex).first)
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            dotData: FlDotData(show: true),
            color: color,
          ),
        ],
        extraLinesData: ExtraLinesData(horizontalLines: []),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final labels = data.map((w) => DateFormat('MM/dd').format(w.week)).toList();

        final weightSpots =
            List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].top.weight));
        final volumeSpots =
            List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].volume));

        final maxWeight = data.fold<double>(0, (p, e) => e.top.weight > p ? e.top.weight : p);
        final maxVolume = data.fold<double>(0, (p, e) => e.volume > p ? e.volume : p);

        final weightChart = _buildLine(
          spots: weightSpots,
          max: maxWeight,
          labels: labels,
          axisLabel: 'Peso (kg)',
          color: Colors.blue,
          tooltipBuilder: (index) {
            final w = data[index];
            final reps = w.top.reps;
            final rir = w.top.rir;
            final fatigue = w.session?.fatigueLevel ?? '';
            final mood = w.session?.mood ?? '';
            final dur = w.session?.durationMinutes ?? 0;
            return [
              LineTooltipItem(
                'R: $reps • RIR $rir\nFatiga: $fatigue • $dur min\nMood: $mood',
                const TextStyle(color: Colors.white),
              ),
            ];
          },
        );

        final volumeChart = _buildLine(
          spots: volumeSpots,
          max: maxVolume,
          labels: labels,
          axisLabel: 'Volumen (kg·reps)',
          color: Colors.green,
          tooltipBuilder: (index) {
            final v = data[index].volume.toInt();
            return [
              LineTooltipItem('Volumen: $v', const TextStyle(color: Colors.white)),
            ];
          },
        );

        final isPortrait = orientation == Orientation.portrait;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: isPortrait
              ? Column(
                  children: [
                    Expanded(child: weightChart),
                    const SizedBox(height: 20),
                    Expanded(child: volumeChart),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: weightChart),
                    Expanded(child: volumeChart),
                  ],
                ),
        );
      },
    );
  }
}

