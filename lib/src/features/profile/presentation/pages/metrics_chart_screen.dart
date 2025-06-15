import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';

class MetricsChartScreen extends ConsumerWidget {
  const MetricsChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(bodyMetricsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso corporal')),
      body: metricsAsync.when(
        data: (metrics) => metrics.isEmpty
            ? const Center(child: Text('Sin datos'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _WeightChartPainter(metrics),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<dynamic> metrics;
  _WeightChartPainter(this.metrics);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (metrics.isEmpty) return;
    double minWeight = metrics.first.weight;
    double maxWeight = metrics.first.weight;
    for (final m in metrics) {
      if (m.weight < minWeight) minWeight = m.weight;
      if (m.weight > maxWeight) maxWeight = m.weight;
    }
    final weightRange = maxWeight - minWeight;
    final dxStep = size.width / (metrics.length - 1);

    Path path = Path();
    for (int i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final x = dxStep * i;
      final norm = weightRange == 0 ? 0 : (m.weight - minWeight) / weightRange;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
