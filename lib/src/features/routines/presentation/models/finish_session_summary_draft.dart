import 'package:flutter/foundation.dart';

@immutable
class FinishSessionSummaryDraft {
  const FinishSessionSummaryDraft({
    required this.planName,
    required this.duration,
    required this.volumeKg,
    required this.completedSets,
    required this.totalSets,
    required this.notes,
    required this.energy,
    required this.mood,
  });

  final String planName;
  final Duration duration;
  final double volumeKg;
  final int completedSets;
  final int totalSets;
  final String notes;
  final String? energy;
  final String? mood;
}
