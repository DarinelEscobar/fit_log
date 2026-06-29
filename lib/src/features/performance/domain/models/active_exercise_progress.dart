import '../../../routines/domain/entities/workout_log_entry.dart';

enum ActiveExerciseProgressConfidence { none, low, medium, high }

enum ActiveExerciseProgressDeltaStatus {
  ahead,
  holding,
  below,
  pending,
  noBaseline,
}

final class ActiveExerciseProgressRequest {
  ActiveExerciseProgressRequest({
    required this.exerciseId,
    required DateTime sessionDate,
  }) : sessionDate = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
        );

  final int exerciseId;
  final DateTime sessionDate;

  @override
  bool operator ==(Object other) {
    return other is ActiveExerciseProgressRequest &&
        other.exerciseId == exerciseId &&
        other.sessionDate == sessionDate;
  }

  @override
  int get hashCode => Object.hash(exerciseId, sessionDate);
}

final class ActiveExerciseProgressInsight {
  const ActiveExerciseProgressInsight({
    required this.lastSession,
    required this.recentBaseline,
    required this.recentTrendPoints,
    required this.confidence,
  });

  final ActiveExerciseSessionSummary? lastSession;
  final ActiveExerciseProgressBaseline? recentBaseline;
  final List<ActiveExerciseTrendPoint> recentTrendPoints;
  final ActiveExerciseProgressConfidence confidence;

  bool get hasHistory => lastSession != null;

  factory ActiveExerciseProgressInsight.empty() {
    return const ActiveExerciseProgressInsight(
      lastSession: null,
      recentBaseline: null,
      recentTrendPoints: [],
      confidence: ActiveExerciseProgressConfidence.none,
    );
  }
}

final class ActiveExerciseProgressBaseline {
  const ActiveExerciseProgressBaseline({
    required this.comparableStrengthKg,
    required this.sessionCount,
  });

  final double comparableStrengthKg;
  final int sessionCount;
}

final class ActiveExerciseProgressDelta {
  const ActiveExerciseProgressDelta({
    required this.status,
    required this.currentComparableStrengthKg,
    required this.baselineComparableStrengthKg,
    required this.deltaKg,
    required this.deltaPercent,
  });

  final ActiveExerciseProgressDeltaStatus status;
  final double currentComparableStrengthKg;
  final double baselineComparableStrengthKg;
  final double deltaKg;
  final double deltaPercent;
}

final class ActiveExerciseTrendPoint {
  const ActiveExerciseTrendPoint({
    required this.date,
    required this.comparableStrengthKg,
  });

  final DateTime date;
  final double comparableStrengthKg;
}

final class ActiveExerciseSessionSummary {
  const ActiveExerciseSessionSummary({
    required this.date,
    required this.planId,
    required this.setCount,
    required this.volumeKg,
    required this.comparableStrengthKg,
    required this.topWeightKg,
    required this.topReps,
    required this.topEstimatedOneRmKg,
    required this.sets,
  });

  final DateTime date;
  final int planId;
  final int setCount;
  final double volumeKg;
  final double comparableStrengthKg;
  final double topWeightKg;
  final int topReps;
  final double topEstimatedOneRmKg;
  final List<ActiveExerciseSetSummary> sets;

  List<ActiveExerciseSetSummary> get workingSets {
    return sets.where((set) => set.isWorkingSet).toList(growable: false);
  }
}

final class ActiveExerciseSetSummary {
  const ActiveExerciseSetSummary({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    required this.estimatedOneRmKg,
    required this.isWorkingSet,
  });

  final int setNumber;
  final int reps;
  final double weightKg;
  final double estimatedOneRmKg;
  final bool isWorkingSet;

  ActiveExerciseSetSummary copyWith({
    bool? isWorkingSet,
  }) {
    return ActiveExerciseSetSummary(
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      estimatedOneRmKg: estimatedOneRmKg,
      isWorkingSet: isWorkingSet ?? this.isWorkingSet,
    );
  }
}

extension ActiveExerciseProgressConfidenceX
    on ActiveExerciseProgressConfidence {
  String get label => switch (this) {
        ActiveExerciseProgressConfidence.none => 'No history',
        ActiveExerciseProgressConfidence.low => 'Low confidence',
        ActiveExerciseProgressConfidence.medium => 'Medium confidence',
        ActiveExerciseProgressConfidence.high => 'High confidence',
      };
}

extension WorkoutLogEntryActiveProgressX on WorkoutLogEntry {
  DateTime get activeProgressDay => DateTime(date.year, date.month, date.day);
}
