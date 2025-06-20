import 'package:flutter/material.dart';

class ExerciseCardHeader extends StatelessWidget {
  final String name;
  final bool showBest;
  final VoidCallback onToggleBest;
  final VoidCallback onExpand;

  const ExerciseCardHeader({
    super.key,
    required this.name,
    required this.showBest,
    required this.onToggleBest,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
        IconButton(
          icon: Icon(showBest ? Icons.star : Icons.star_border),
          onPressed: onToggleBest,
        ),
        IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: onExpand,
        ),
      ],
    );
  }
}
