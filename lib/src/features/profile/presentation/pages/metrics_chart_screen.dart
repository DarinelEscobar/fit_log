import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import '../../domain/entities/body_metric.dart';
import '../widgets/comparison_chart_painter.dart';
import '../../domain/entities/user_profile.dart';

class MetricsChartScreen extends ConsumerStatefulWidget {
  const MetricsChartScreen({super.key});
  @override
  ConsumerState<MetricsChartScreen> createState() => _MetricsChartScreenState();
}

class _MetricsChartScreenState extends ConsumerState<MetricsChartScreen> {
  int? _selectedIndex;

  List<MetricData> _buildMetricData(BodyMetric current, UserProfile user) {
    final raw = [
      MetricData('Weight', current.weight, user.targetWeight),
      MetricData('BF', current.bodyFat, user.targetBodyFat),
      MetricData('Neck', current.neck, user.targetNeck),
      MetricData('Shoulders', current.shoulders, user.targetShoulders),
      MetricData('Chest', current.chest, user.targetChest),
      MetricData('Abdomen', current.abdomen, user.targetAbdomen),
      MetricData('Waist', current.waist, user.targetWaist),
      MetricData('Glutes', current.glutes, user.targetGlutes),
      MetricData('Thigh', current.thigh, user.targetThigh),
      MetricData('Calf', current.calf, user.targetCalf),
      MetricData('Arm', current.arm, user.targetArm),
      MetricData('Forearm', current.forearm, user.targetForearm),
    ];
    return raw.where((m) => m.current > 0 && m.target > 0).toList();
  }

  int? _hitTestMetric(Offset pos, double width, List<MetricData> metrics) {
    const axis = ComparisonChartPainter.axisWidth;
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
                        painter: ComparisonChartPainter(
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

