import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MiniSparkline extends StatelessWidget {
  final List<double> data;
  const MiniSparkline({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 40);
    final spots = List.generate(
        data.length, (i) => FlSpot(i.toDouble(), data[i]));
    return SizedBox(
      height: 40,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
