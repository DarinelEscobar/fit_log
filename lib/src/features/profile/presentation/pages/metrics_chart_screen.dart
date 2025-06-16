import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import '../../domain/entities/body_metric.dart';
import '../../domain/entities/user_profile.dart';

class MetricsChartScreen extends ConsumerStatefulWidget {
  const MetricsChartScreen({super.key});
  @override
  ConsumerState<MetricsChartScreen> createState() => _MetricsChartScreenState();
}

class _MetricsChartScreenState extends ConsumerState<MetricsChartScreen> {
  int? _selectedIndex;

  List<_MetricData> _buildMetricData(BodyMetric current, UserProfile user) {
    final raw = [
      _MetricData('Weight', current.weight, user.targetWeight),
      _MetricData('BF', current.bodyFat, user.targetBodyFat),
      _MetricData('Neck', current.neck, user.targetNeck),
      _MetricData('Shoulders', current.shoulders, user.targetShoulders),
      _MetricData('Chest', current.chest, user.targetChest),
      _MetricData('Abdomen', current.abdomen, user.targetAbdomen),
      _MetricData('Waist', current.waist, user.targetWaist),
      _MetricData('Glutes', current.glutes, user.targetGlutes),
      _MetricData('Thigh', current.thigh, user.targetThigh),
      _MetricData('Calf', current.calf, user.targetCalf),
      _MetricData('Arm', current.arm, user.targetArm),
      _MetricData('Forearm', current.forearm, user.targetForearm),
    ];
    return raw.where((m) => m.current > 0 && m.target > 0).toList();
  }

  int? _hitTestMetric(Offset pos, double width, List<_MetricData> metrics) {
    const axis = _ComparisonChartPainter.axisWidth;
    if (pos.dx < axis || pos.dx > width) return null;
    final group = (width - axis) / metrics.length;
    final i = ((pos.dx - axis) / group).floor();
    return (i < 0 || i >= metrics.length) ? null : i;
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(bodyMetricsProvider);
    final userAsync = ref.watch(userProfileProvider);

    return metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (metricsList) => userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Sin perfil'));
          if (metricsList.isEmpty) return const Center(child: Text('Sin métricas'));
          final latest = metricsList.last;
          final metrics = _buildMetricData(latest, user);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: OrientationBuilder(
              builder: (context, orientation) {
                final height = orientation == Orientation.portrait ? 300.0 : 200.0;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) {
                        final local = (context.findRenderObject() as RenderBox)
                            .globalToLocal(details.globalPosition);
                        setState(() {
                          _selectedIndex =
                              _hitTestMetric(local, constraints.maxWidth, metrics);
                        });
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, height),
                        painter: _ComparisonChartPainter(
                          metrics,
                          selectedIndex: _selectedIndex,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MetricData {
  final String label;
  final double current;
  final double target;
  const _MetricData(this.label, this.current, this.target);
}

class _ComparisonChartPainter extends CustomPainter {
  static const double axisWidth = 40;

  final List<_MetricData> metrics;
  final int? selectedIndex;

  _ComparisonChartPainter(this.metrics, {this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    const top = 30.0, bottom = 40.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - axisWidth;
    final groupWidth = chartWidth / metrics.length;
    const spacing = 4.0;
    final barWidth = (groupWidth - spacing) / 2;

    final gridPaint = Paint()..color = Colors.white24..strokeWidth = 0.5;
    final axisPaint = Paint()..color = Colors.white70..strokeWidth = 1.5;
    final currentPaint = Paint()..color = Colors.blueAccent;
    final targetPaint = Paint()..color = Colors.deepOrangeAccent;

    final tp = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);

    // Grid & Y axis
    final maxVal = metrics.fold<double>(
      1, (prev, e) => math.max(prev, math.max(e.current, e.target)),
    );
    const ticks = 5;
    for (var i = 0; i <= ticks; i++) {
      final y = top + chartHeight - chartHeight / ticks * i;
      canvas.drawLine(Offset(axisWidth, y), Offset(size.width, y), gridPaint);
      tp.text = TextSpan(
        text: (maxVal / ticks * i).toStringAsFixed(0),
        style: const TextStyle(fontSize: 10, color: Colors.white70),
      );
      tp.layout(maxWidth: axisWidth - 8);
      tp.paint(canvas, Offset(axisWidth - tp.width - 4, y - tp.height / 2));
    }
    canvas.drawLine(Offset(axisWidth, top), Offset(axisWidth, top + chartHeight), axisPaint);

    // Legend
    const legendSize = 12.0;
    final legendX = size.width - 160;
    final legendY = top - 20;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(legendX, legendY, 156, 24), const Radius.circular(4)),
      Paint()..color = Colors.white10,
    );
    canvas.drawRect(Rect.fromLTWH(legendX + 8, legendY + 6, legendSize, legendSize), currentPaint);
    tp.text = const TextSpan(text: 'Actual', style: TextStyle(fontSize: 12, color: Colors.white));
    tp.layout(); tp.paint(canvas, Offset(legendX + 8 + legendSize + 4, legendY + 6));
    canvas.drawRect(Rect.fromLTWH(legendX + 80, legendY + 6, legendSize, legendSize), targetPaint);
    tp.text = const TextSpan(text: 'Objetivo', style: TextStyle(fontSize: 12, color: Colors.white));
    tp.layout(); tp.paint(canvas, Offset(legendX + 80 + legendSize + 4, legendY + 6));

    // Bars, labels & differences
    for (var i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final x0 = axisWidth + i * groupWidth;
      final h1 = (m.current / maxVal) * chartHeight;
      final h2 = (m.target / maxVal) * chartHeight;

      // Bars
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x0, top + chartHeight - h1, barWidth, h1), const Radius.circular(4)),
        currentPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x0 + barWidth + spacing, top + chartHeight - h2, barWidth, h2), const Radius.circular(4)),
        targetPaint,
      );

      // X-axis label
      tp.text = TextSpan(text: m.label, style: const TextStyle(fontSize: 10, color: Colors.white));
      tp.layout(minWidth: groupWidth);
      tp.paint(canvas, Offset(x0, top + chartHeight + 8));

      // Difference text
      final diff = m.target - m.current;
      final diffText = (diff >= 0 ? '+' : '') + diff.toStringAsFixed(1);
      tp.text = TextSpan(
        text: diffText,
        style: TextStyle(
          fontSize: 10,
          color: diff >= 0
              ? const Color.fromARGB(255, 56, 224, 22)
              : const Color.fromARGB(255, 212, 8, 8),
        ),
      );
      tp.layout();
      final dy = top + chartHeight - math.max(h1, h2) - tp.height - 4;
      final dx = x0 + groupWidth / 2 - tp.width / 2;
      tp.paint(canvas, Offset(dx, dy));


      // Selection tooltip
      if (selectedIndex == i) {
        tp.text = TextSpan(
          text: '${m.current.toStringAsFixed(1)} / ${m.target.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12, color: Colors.white),
        );
        tp.layout();
        final lx = x0 + groupWidth / 2 - tp.width / 2;
        final ly = top - tp.height - 12;
        final rect = Rect.fromLTWH(lx - 6, ly - 4, tp.width + 12, tp.height + 8);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = Colors.black87);
        tp.paint(canvas, Offset(lx, ly));
      }
    }

    // X-axis line
    canvas.drawLine(Offset(axisWidth, top + chartHeight), Offset(size.width, top + chartHeight), axisPaint);
  }

  @override
  bool shouldRepaint(covariant _ComparisonChartPainter old) =>
      old.selectedIndex != selectedIndex || old.metrics != metrics;
}
