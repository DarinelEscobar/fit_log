import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../routines/domain/entities/workout_session.dart';
    final asyncSessions = ref.watch(workoutSessionsProvider);
        data: (logs) => asyncSessions.when(
          data: (sessions) => _Chart(data: _summaries(logs, sessions)),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
  List<_WeekSummary> _summaries(
    List<WorkoutLogEntry> logs,
    List<WorkoutSession> sessions,
  ) {
    if (logs.isEmpty) return [];

    DateTime start = map.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime end = map.keys.reduce((a, b) => a.isAfter(b) ? a : b);

    for (DateTime week = start;
        !week.isAfter(end);
        week = week.add(const Duration(days: 7))) {
      final entries = map[week] ?? [];
      if (entries.isEmpty) {
        result.add(_WeekSummary(week, 0, null, null));
        continue;
      }
      final top = entries.first;
      final session = sessions.firstWhere(
        (s) =>
            s.planId == top.planId &&
            s.date.year == top.date.year &&
            s.date.month == top.date.month &&
            s.date.day == top.date.day,
        orElse: () => WorkoutSession(
            planId: top.planId,
            date: top.date,
            fatigueLevel: '',
            durationMinutes: 0,
            mood: '',
            notes: ''),
      );
      result.add(_WeekSummary(week, volume, top, session));
  final WorkoutLogEntry? top;
  final WorkoutSession? session;
  _WeekSummary(this.weekStart, this.volume, this.top, this.session);
  double _interval(double max) {
    if (max <= 0) return 5;
    final raw = max / 5;
    final rounded = ((raw / 5).ceil() * 5).toDouble();
    return rounded < 5 ? 5 : rounded;
  }

      spotsWeight.add(FlSpot(i.toDouble(), data[i].top?.weight ?? 0));

    final maxWeight = data
        .map((e) => e.top?.weight ?? 0)
        .fold<double>(0, (p, c) => c > p ? c : p);
    final avgVolume = data.isEmpty
        ? 0
        : data.map((e) => e.volume).reduce((a, b) => a + b) / data.length;
                        final reps = w.top?.reps ?? 0;
                        final rir = w.top?.rir ?? 0;
                        final fatigue = w.session?.fatigueLevel ?? '';
                        final mood = w.session?.mood ?? '';
                        final dur = w.session?.durationMinutes ?? 0;
                        final text = 'R: $reps • RIR $rir\n'
                            'Fatiga: $fatigue • $dur min\nMood: $mood';
                          text,
                          const TextStyle(color: Colors.white, fontSize: 12),
                      interval: _interval(maxWeight),
                      interval: _interval(maxVolume),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, bar, i) {
                        final w = data[i];
                        final label = 'R:${w.top?.reps ?? 0}\nRIR:${w.top?.rir ?? 0}';
                        return _LabelDotPainter(label: label, color: Colors.blue);
                      },
                    ),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: avgVolume,
                    color: Colors.green.withOpacity(0.3),
                    dashArray: [4, 4],
                    yAxis: 1,
                  ),
                ]),
class _LabelDotPainter extends FlDotPainter {
  final String label;
  final Color color;
  _LabelDotPainter({required this.label, required this.color});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas, Color barColor,
      {required CanvasHolder holder}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      offsetInCanvas - Offset(textPainter.width / 2, textPainter.height + 4),
    );
    final circle = FlDotCirclePainter(
      radius: 3,
      color: color,
      strokeWidth: 1,
      strokeColor: Colors.black,
    );
    circle.draw(canvas, spot, offsetInCanvas, barColor, holder: holder);
  }

  @override
  Size getSize(FlSpot spot) => const Size(6, 6);
}

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
              LineChartData(
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((e) {
                      final w = data[e.spotIndex];
                      return LineTooltipItem(
                        'R: ${w.top.reps} • RIR ${w.top.rir}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
                gridData: FlGridData(drawVerticalLine: false, verticalInterval: 1),
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
                      getTitlesWidget: (value, _) {
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
