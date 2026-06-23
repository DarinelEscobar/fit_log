import 'package:flutter/foundation.dart';

enum HistoryPeriod { oneWeek, fourWeeks, twelveWeeks, yearToDate }

@immutable
final class HistoryFilter {
  const HistoryFilter({
    required this.period,
    this.planId,
  });

  final HistoryPeriod period;
  final int? planId;

  @override
  bool operator ==(Object other) {
    return other is HistoryFilter &&
        other.period == period &&
        other.planId == planId;
  }

  @override
  int get hashCode => Object.hash(period, planId);
}

@immutable
final class HistoryDateRange {
  const HistoryDateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

extension HistoryPeriodX on HistoryPeriod {
  String get label => switch (this) {
        HistoryPeriod.oneWeek => '1W',
        HistoryPeriod.fourWeeks => '4W',
        HistoryPeriod.twelveWeeks => '12W',
        HistoryPeriod.yearToDate => 'YTD',
      };

  HistoryDateRange resolve(DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (this) {
      HistoryPeriod.oneWeek => HistoryDateRange(
          start: day.subtract(const Duration(days: 6)),
          end: day,
        ),
      HistoryPeriod.fourWeeks => HistoryDateRange(
          start: day.subtract(const Duration(days: 27)),
          end: day,
        ),
      HistoryPeriod.twelveWeeks => HistoryDateRange(
          start: day.subtract(const Duration(days: 83)),
          end: day,
        ),
      HistoryPeriod.yearToDate => HistoryDateRange(
          start: DateTime(day.year),
          end: day,
        ),
    };
  }
}

@immutable
final class HistoryOverviewData {
  const HistoryOverviewData({
    required this.filter,
    required this.range,
    required this.planOptions,
    required this.sessions,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.trainingDays,
    required this.averageDurationMinutes,
  });

  final HistoryFilter filter;
  final HistoryDateRange range;
  final List<HistoryPlanOption> planOptions;
  final List<HistorySessionSummary> sessions;
  final double totalVolumeKg;
  final int totalSets;
  final int trainingDays;
  final int averageDurationMinutes;

  bool get hasSessions => sessions.isNotEmpty;
}

@immutable
final class HistoryPlanOption {
  const HistoryPlanOption({
    required this.planId,
    required this.name,
  });

  final int planId;
  final String name;
}

@immutable
final class HistorySessionSummary {
  const HistorySessionSummary({
    required this.planId,
    required this.planName,
    required this.date,
    required this.durationMinutes,
    required this.energy,
    required this.mood,
    required this.notes,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.totalReps,
    required this.exercises,
  });

  final int planId;
  final String planName;
  final DateTime date;
  final int durationMinutes;
  final String energy;
  final String mood;
  final String notes;
  final double totalVolumeKg;
  final int totalSets;
  final int totalReps;
  final List<HistoryExerciseSummary> exercises;
}

@immutable
final class HistoryExerciseSummary {
  const HistoryExerciseSummary({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.category,
    required this.mainMuscleGroup,
    required this.volumeKg,
    required this.totalReps,
    required this.topWeightKg,
    required this.topReps,
    required this.sets,
  });

  final int exerciseId;
  final String name;
  final String description;
  final String category;
  final String mainMuscleGroup;
  final double volumeKg;
  final int totalReps;
  final double topWeightKg;
  final int topReps;
  final List<HistorySetRow> sets;
}

@immutable
final class HistorySetRow {
  const HistorySetRow({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.rir,
  });

  final int setNumber;
  final double weightKg;
  final int reps;
  final int rir;
}
