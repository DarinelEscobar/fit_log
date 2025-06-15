import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import '../../domain/entities/body_metric.dart';
import '../../domain/entities/user_profile.dart';
class MetricsChartScreen extends ConsumerStatefulWidget {
  ConsumerState<MetricsChartScreen> createState() => _MetricsChartScreenState();
}

class _MetricsChartScreenState extends ConsumerState<MetricsChartScreen> {
  int? _selectedIndex;

  List<_MetricData> _buildMetricData(BodyMetric current, UserProfile user) {
    return [
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
  }

  int? _hitTestMetric(
      Offset pos, double width, List<_MetricData> metrics) {
    const axisWidth = _ComparisonChartPainter.axisWidth;
    if (pos.dx < axisWidth || pos.dx > width) return null;
    final chartWidth = width - axisWidth;
    final groupWidth = chartWidth / metrics.length;
    final index = ((pos.dx - axisWidth) / groupWidth).floor();
    if (index < 0 || index >= metrics.length) return null;
    return index;
  }

  @override
  Widget build(BuildContext context) {
            data: (user) {
              if (user == null) {
                return const Center(child: Text('Sin perfil'));
              }
              final metricData = _buildMetricData(latest, user);
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    final height =
                        orientation == Orientation.portrait ? 260.0 : 180.0;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (d) {
                            final box = context.findRenderObject() as RenderBox;
                            final local = box.globalToLocal(d.globalPosition);
                            final index = _hitTestMetric(
                                local, constraints.maxWidth, metricData);
                            setState(() => _selectedIndex = index);
                          },
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, height),
                            painter: _ComparisonChartPainter(
                              metricData,
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
  static const double axisWidth = 28.0;

  final List<_MetricData> metrics;
  final int? selectedIndex;
  _ComparisonChartPainter(this.metrics, {this.selectedIndex});
    const top = 20.0;
    const bottom = 28.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - axisWidth;
    final groupWidth = chartWidth / metrics.length;
    final barWidth = groupWidth / 3;
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
    );
    canvas.drawLine(
      Offset(axisWidth, top),
      Offset(axisWidth, top + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(axisWidth, top + chartHeight),
      Offset(size.width, top + chartHeight),
      axisPaint,
    );

    const tickCount = 5;
    for (int i = 0; i <= tickCount; i++) {
      final val = maxVal / tickCount * i;
      final y = top + chartHeight - (chartHeight / tickCount * i);
      textPainter.text = TextSpan(
        text: val.toStringAsFixed(0),
        style: const TextStyle(fontSize: 8, color: Colors.black),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(axisWidth - textPainter.width - 2, y - textPainter.height / 2),
      );
      canvas.drawLine(
        Offset(axisWidth - 3, y),
        Offset(axisWidth, y),
        axisPaint,
      );
    }

      final groupX = axisWidth + i * groupWidth;
        Rect.fromLTWH(groupX, top + chartHeight - currentH, barWidth, currentH),
        Rect.fromLTWH(
            groupX + barWidth * 2, top + chartHeight - targetH, barWidth, targetH),
        Offset(groupX, top + chartHeight + 2),

      if (selectedIndex != null && selectedIndex == i) {
        final label = '${m.current.toStringAsFixed(1)} / ${m.target.toStringAsFixed(1)}';
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, color: Colors.black),
        );
        textPainter.layout();
        final lx = groupX + groupWidth / 2 - textPainter.width / 2;
        final ly = top - textPainter.height - 2;
        final rect = Rect.fromLTWH(lx - 4, ly - 2, textPainter.width + 8, textPainter.height + 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = Colors.white.withOpacity(0.8),
        );
        canvas.drawRect(rect, axisPaint);
        textPainter.paint(canvas, Offset(lx, ly));
      }
  bool shouldRepaint(covariant _ComparisonChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.metrics != metrics;
  }
  final double current;
  final double target;
  const _MetricData(this.label, this.current, this.target);
}

class _ComparisonChartPainter extends CustomPainter {
  final BodyMetric current;
  final UserProfile user;

  _ComparisonChartPainter(this.current, this.user);

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = <_MetricData>[
      _MetricData('W', current.weight, user.targetWeight),
      _MetricData('BF', current.bodyFat, user.targetBodyFat),
      _MetricData('N', current.neck, user.targetNeck),
      _MetricData('Sh', current.shoulders, user.targetShoulders),
      _MetricData('Ch', current.chest, user.targetChest),
      _MetricData('Ab', current.abdomen, user.targetAbdomen),
      _MetricData('Wa', current.waist, user.targetWaist),
      _MetricData('Gl', current.glutes, user.targetGlutes),
      _MetricData('Th', current.thigh, user.targetThigh),
      _MetricData('Ca', current.calf, user.targetCalf),
      _MetricData('Ar', current.arm, user.targetArm),
      _MetricData('Fo', current.forearm, user.targetForearm),
    ];

    double maxVal = 0;
    for (final m in metrics) {
      if (m.current > maxVal) maxVal = m.current;
      if (m.target > maxVal) maxVal = m.target;
    }
    if (maxVal == 0) maxVal = 1;

    const barWidth = 8.0;
    const spacing = 6.0;
    const bottom = 18.0;
    final groupWidth = barWidth * 2 + spacing;
    final chartHeight = size.height - bottom;
    final totalWidth = metrics.length * groupWidth;
    final startX = (size.width - totalWidth) / 2;

    final currentPaint = Paint()..color = Colors.blue;
    final targetPaint = Paint()..color = Colors.red.withOpacity(0.7);
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final x = startX + i * groupWidth;

      final currentH = (m.current / maxVal) * chartHeight;
      final targetH = (m.target / maxVal) * chartHeight;

      canvas.drawRect(
        Rect.fromLTWH(x, chartHeight - currentH, barWidth, currentH),
        currentPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + barWidth, chartHeight - targetH, barWidth, targetH),
        targetPaint,
      );

      textPainter.text = TextSpan(
        text: m.label,
        style: const TextStyle(fontSize: 8, color: Colors.black),
      );
      textPainter.layout(minWidth: groupWidth);
      textPainter.paint(
        canvas,
        Offset(x, chartHeight + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
