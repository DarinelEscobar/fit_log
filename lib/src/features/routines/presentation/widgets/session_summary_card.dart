import 'package:flutter/material.dart';

class SessionSummaryCard extends StatelessWidget {
  final String duration;
  final String completion;
  final bool showBest;
  final VoidCallback onToggleBest;

  const SessionSummaryCard({
    super.key,
    required this.duration,
    required this.completion,
    required this.showBest,
    required this.onToggleBest,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          _buildMetric(
            icon: Icons.timer_outlined,
            label: 'Tiempo',
            value: duration,
          ),
          const SizedBox(width: 12),
          _buildMetric(
            icon: Icons.check_circle_outline,
            label: 'Completado',
            value: completion,
          ),
          const Spacer(),
          IconButton(
            onPressed: onToggleBest,
            icon: Icon(
              showBest ? Icons.star : Icons.star_border,
              color: colorScheme.primary,
            ),
            tooltip: showBest ? 'Ocultar mejores' : 'Ver mejores',
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF8E8CF8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
