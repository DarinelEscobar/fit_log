import 'package:flutter/foundation.dart';

enum PerformancePeriod { oneWeek, fourWeeks, twelveWeeks, yearToDate }

final class PerformanceDashboardRequest {
  const PerformanceDashboardRequest({
    required this.period,
    required this.activePlanIds,
  });

  final PerformancePeriod period;
  final List<int> activePlanIds;

  @override
  bool operator ==(Object other) {
    return other is PerformanceDashboardRequest &&
        other.period == period &&
        listEquals(other.activePlanIds, activePlanIds);
  }

  @override
  int get hashCode => Object.hash(period, Object.hashAll(activePlanIds));
}

final class PerformancePeriodRange {
  const PerformancePeriodRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

extension PerformancePeriodX on PerformancePeriod {
  String get label => switch (this) {
        PerformancePeriod.oneWeek => '1W',
        PerformancePeriod.fourWeeks => '4W',
        PerformancePeriod.twelveWeeks => '12W',
        PerformancePeriod.yearToDate => 'YTD',
      };

  int get windowDays => switch (this) {
        PerformancePeriod.oneWeek => 7,
        PerformancePeriod.fourWeeks => 28,
        PerformancePeriod.twelveWeeks => 84,
        PerformancePeriod.yearToDate => 0,
      };

  PerformancePeriodRange resolve(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      PerformancePeriod.oneWeek => PerformancePeriodRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      PerformancePeriod.fourWeeks => PerformancePeriodRange(
          start: today.subtract(const Duration(days: 27)),
          end: today,
        ),
      PerformancePeriod.twelveWeeks => PerformancePeriodRange(
          start: today.subtract(const Duration(days: 83)),
          end: today,
        ),
      PerformancePeriod.yearToDate => PerformancePeriodRange(
          start: DateTime(today.year, 1, 1),
          end: today,
        ),
    };
  }
}

final class PerformanceDashboardSummary {
  const PerformanceDashboardSummary({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalVolumeKg,
    required this.totalReps,
    required this.consistencyPercent,
    required this.trainingDays,
    required this.trend,
    required this.muscleFocus,
    required this.recentPrs,
  });

  final PerformancePeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double totalVolumeKg;
  final int totalReps;
  final int consistencyPercent;
  final int trainingDays;
  final List<PerformanceTrendPoint> trend;
  final List<PerformanceMuscleFocus> muscleFocus;
  final List<PerformancePrCard> recentPrs;

  bool get hasData =>
      trainingDays > 0 ||
      totalReps > 0 ||
      totalVolumeKg > 0 ||
      trend.isNotEmpty;

  factory PerformanceDashboardSummary.empty(PerformancePeriod period) {
    final now = DateTime.now();
    final range = period.resolve(now);
    return PerformanceDashboardSummary(
      period: period,
      startDate: range.start,
      endDate: range.end,
      totalVolumeKg: 0,
      totalReps: 0,
      consistencyPercent: 0,
      trainingDays: 0,
      trend: const [],
      muscleFocus: const [],
      recentPrs: const [],
    );
  }
}

final class PerformanceTrendPoint {
  const PerformanceTrendPoint({
    required this.weekStart,
    required this.volumeKg,
    required this.topSetKg,
  });

  final DateTime weekStart;
  final double volumeKg;
  final double topSetKg;
}

final class PerformanceMuscleFocus {
  const PerformanceMuscleFocus({
    required this.label,
    required this.volumeKg,
    required this.percent,
  });

  final String label;
  final double volumeKg;
  final int percent;
}

final class PerformancePrCard {
  const PerformancePrCard({
    required this.label,
    required this.exerciseName,
    required this.detail,
    required this.valueKg,
    required this.deltaLabel,
    required this.date,
  });

  final String label;
  final String exerciseName;
  final String detail;
  final double valueKg;
  final String deltaLabel;
  final DateTime date;
}

final class ExerciseProgressDetailData {
  const ExerciseProgressDetailData({
    required this.estimatedOneRmKg,
    required this.totalVolumeKg,
    required this.lastSessionDate,
    required this.lastWeightKg,
    required this.lastReps,
    required this.trend,
    required this.recentSessions,
  });

  final double estimatedOneRmKg;
  final double totalVolumeKg;
  final DateTime? lastSessionDate;
  final double lastWeightKg;
  final int lastReps;
  final List<ExerciseProgressTrendPoint> trend;
  final List<ExerciseRecentSession> recentSessions;

  factory ExerciseProgressDetailData.empty() {
    return const ExerciseProgressDetailData(
      estimatedOneRmKg: 0,
      totalVolumeKg: 0,
      lastSessionDate: null,
      lastWeightKg: 0,
      lastReps: 0,
      trend: [],
      recentSessions: [],
    );
  }
}

final class ExerciseProgressTrendPoint {
  const ExerciseProgressTrendPoint({
    required this.weekStart,
    required this.volumeKg,
    required this.oneRmKg,
  });

  final DateTime weekStart;
  final double volumeKg;
  final double oneRmKg;
}

final class ExerciseRecentSession {
  const ExerciseRecentSession({
    required this.date,
    required this.setCount,
    required this.volumeKg,
    required this.topWeightKg,
    required this.topReps,
    required this.topOneRmKg,
  });

  final DateTime date;
  final int setCount;
  final double volumeKg;
  final double topWeightKg;
  final int topReps;
  final double topOneRmKg;
}
