import 'package:flutter/material.dart';

class SessionSummaryCard extends StatelessWidget {
  final String duration;
  final String completion;
  final bool showBest;
  final VoidCallback onToggleBest;
  final double volume;

  const SessionSummaryCard({
    super.key,
    required this.duration,
    required this.completion,
    required this.showBest,
    required this.onToggleBest,
    this.volume = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // Assuming completion format is "done/total", parse out the percentage.
    final parts = completion.split('/');
    double progress = 0.0;
    if (parts.length == 2) {
      final done = int.tryParse(parts[0]) ?? 0;
      final total = int.tryParse(parts[1]) ?? 1;
      progress = total > 0 ? done / total : 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'PROGRESS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xFFADAAAB),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCC97FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A191B),
            borderRadius: BorderRadius.circular(999),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCC97FF), Color(0xFF842CD3)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(204, 151, 255, 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMetricCard('VOLUME', '${volume.toStringAsFixed(0)} LBS'),
              const SizedBox(width: 16),
              _buildMetricCard('SETS', completion),
              const SizedBox(width: 16),
              _buildMetricCard('INTENSITY', '85%'), // Mock intensity
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131314),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Color(0xFFADAAAB),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
