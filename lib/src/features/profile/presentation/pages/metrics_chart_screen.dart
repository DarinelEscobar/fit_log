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
                final height = orientation == Orientation.portrait ? 260.0 : 180.0;
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
  static const double axisWidth = 28;

  final List<_MetricData> metrics;
  final int? selectedIndex;

  _ComparisonChartPainter(this.metrics, {this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    const top = 20.0, bottom = 28.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - axisWidth;
    final groupWidth = chartWidth / metrics.length;
    const spacing = 4.0;
    final barWidth = (groupWidth - spacing) / 2;

    final axisPaint = Paint()..color = Colors.white..strokeWidth = 1;
    final currentPaint = Paint()..color = Colors.blue;
    final targetPaint = Paint()..color = Colors.red.withOpacity(.7);

    canvas
      ..drawLine(Offset(axisWidth, top), Offset(axisWidth, top + chartHeight), axisPaint)
      ..drawLine(Offset(axisWidth, top + chartHeight), Offset(size.width, top + chartHeight), axisPaint);

    final maxVal = metrics.fold<double>(
      1,
      (prev, e) => math.max(prev, math.max(e.current, e.target)),
    );

    final tp = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    const ticks = 5;
    for (var i = 0; i <= ticks; i++) {
      final val = maxVal / ticks * i;
      final y = top + chartHeight - chartHeight / ticks * i;
      tp.text = TextSpan(text: val.toStringAsFixed(0), style: const TextStyle(fontSize: 8, color: Colors.white));
      tp.layout();
      tp.paint(canvas, Offset(axisWidth - tp.width - 4, y - tp.height / 2));
      canvas.drawLine(Offset(axisWidth - 4, y), Offset(axisWidth, y), axisPaint);
    }

    for (var i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final x0 = axisWidth + i * groupWidth;

      final h1 = (m.current / maxVal) * chartHeight;
      final h2 = (m.target  / maxVal) * chartHeight;

      canvas
        ..drawRect(Rect.fromLTWH(x0, top + chartHeight - h1, barWidth, h1), currentPaint)
        ..drawRect(Rect.fromLTWH(x0 + barWidth + spacing, top + chartHeight - h2, barWidth, h2), targetPaint);

      tp.text = TextSpan(text: m.label, style: const TextStyle(fontSize: 8, color: Colors.white));
      tp.layout(minWidth: groupWidth);
      tp.paint(canvas, Offset(x0, top + chartHeight + 4));

      if (selectedIndex == i) {
        final label = '${m.current.toStringAsFixed(1)} / ${m.target.toStringAsFixed(1)}';
        tp.text = TextSpan(text: label, style: const TextStyle(fontSize: 10, color: Colors.white));
        tp.layout();
        final lx = x0 + groupWidth / 2 - tp.width / 2;
        final ly = top - tp.height - 4;
        final rect = Rect.fromLTWH(lx - 4, ly - 2, tp.width + 8, tp.height + 4);
        canvas
          ..drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = Colors.white.withOpacity(.2))
          ..drawRect(rect, axisPaint);
        tp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ComparisonChartPainter old) =>
      old.selectedIndex != selectedIndex || old.metrics != metrics;
}
