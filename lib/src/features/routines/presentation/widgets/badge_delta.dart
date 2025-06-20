import 'package:flutter/material.dart';

class BadgeDelta extends StatelessWidget {
  final int delta;
  const BadgeDelta(this.delta, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final positive = delta >= 0;
    final bg = positive ? Colors.green : Colors.red;
    final icon = positive ? '↑' : '↓';
    final semantics = 'Progreso ${delta > 0 ? '+' : ''}$delta por ciento';
    return Semantics(
      label: semantics,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$icon ${delta.abs()}%',
          style: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
        ),
      ),
    );
  }
}
