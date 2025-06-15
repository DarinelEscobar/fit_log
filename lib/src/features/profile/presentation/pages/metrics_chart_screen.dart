import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import '../../domain/entities/body_metric.dart';
import '../../domain/entities/user_profile.dart';

class MetricsChartScreen extends ConsumerWidget {
  const MetricsChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(bodyMetricsProvider);
    final userAsync = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Comparación de medidas')),
      body: metricsAsync.when(
        data: (metrics) {
          if (metrics.isEmpty) {
            return const Center(child: Text('Sin datos'));
          }
          metrics.sort((a, b) => a.date.compareTo(b.date));
          final latest = metrics.last;
          return userAsync.when(
            data: (user) => user == null
                ? const Center(child: Text('Sin perfil'))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CustomPaint(
                      size: const Size(double.infinity, 220),
                      painter: _ComparisonChartPainter(latest, user),
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
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
