import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MiniLineChart extends StatelessWidget {
  final List<double> today;
  final List<double> last;
  final List<double> best;

  const MiniLineChart({
    Key? key,
    required this.today,
    this.last = const [],
    this.best = const [],
  }) : super(key: key);

  List<FlSpot> _spots(List<double> data) =>
      List.generate(data.length, (i) => FlSpot((i + 1).toDouble(), data[i]));

  @override
  Widget build(BuildContext context) {
    final maxX = [today.length, last.length, best.length]
        .fold<double>(0, (p, e) => e > p ? e.toDouble() : p);
    final maxY = [...today, ...last, ...best]
        .fold<double>(0, (p, e) => e > p ? e : p);

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: maxX <= 0 ? 1 : maxX,
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (last.isNotEmpty)
            LineChartBarData(
              spots: _spots(last),
              isCurved: true,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              color: Colors.grey.shade600,
            ),
          if (best.isNotEmpty)
            LineChartBarData(
              spots: _spots(best),
              isCurved: true,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              color: Colors.amber.shade400,
            ),
          LineChartBarData(
            spots: _spots(today),
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            color: Colors.blueAccent.shade200,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.shade200.withOpacity(0.3),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
