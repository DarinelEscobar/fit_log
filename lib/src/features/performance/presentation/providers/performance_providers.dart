import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/workout_storage_service_provider.dart';
import '../../../routines/domain/entities/exercise.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/presentation/providers/exercises_provider.dart';
import '../models/performance_models.dart';

final performanceDashboardProvider = FutureProvider.family<
    PerformanceDashboardSummary, PerformanceDashboardRequest>((ref, request) async {
  if (request.activePlanIds.isEmpty) {
    return PerformanceDashboardSummary.empty(request.period);
  }

  final storage = ref.watch(workoutStorageServiceProvider);
  final exercises = await ref.watch(allExercisesProvider.future);
  final exerciseMap = {
    for (final exercise in exercises) exercise.id: exercise,
  };
  final range = request.period.resolve(DateTime.now());
  final logs = await storage.fetchWorkoutLogs(
    planIds: request.activePlanIds,
    startDate: range.start,
    endDate: range.end,
  );

  return _buildDashboardSummary(
    period: request.period,
    range: range,
    logs: logs,
    exerciseMap: exerciseMap,
  );
});

final exerciseProgressDetailProvider = FutureProvider.family<
    ExerciseProgressDetailData, int>((ref, exerciseId) async {
  final storage = ref.watch(workoutStorageServiceProvider);
  final logs = await storage.fetchWorkoutLogs(exerciseId: exerciseId);
  return _buildExerciseProgressDetail(logs);
});

PerformanceDashboardSummary _buildDashboardSummary({
  required PerformancePeriod period,
  required PerformancePeriodRange range,
  required List<WorkoutLogEntry> logs,
  required Map<int, Exercise> exerciseMap,
}) {
  if (logs.isEmpty) {
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

  final totalVolumeKg = logs.fold<double>(
    0,
    (sum, entry) => sum + entry.weight * entry.reps,
  );
  final totalReps = logs.fold<int>(0, (sum, entry) => sum + entry.reps);
  final uniqueTrainingDays = logs
      .map((entry) => DateTime(entry.date.year, entry.date.month, entry.date.day))
      .toSet()
      .length;

  final periodLength = range.end.difference(range.start).inDays + 1;
  final consistencyPercent = periodLength <= 0
      ? 0
      : ((uniqueTrainingDays / periodLength) * 100).clamp(0, 100).round();

  final trendByWeek = <DateTime, List<WorkoutLogEntry>>{};
  final volumeByMuscle = <String, double>{};

  for (final log in logs) {
    final weekStart = _weekStart(log.date);
    trendByWeek.putIfAbsent(weekStart, () => []).add(log);

    final muscleGroup = _normalizeMuscleGroup(
      exerciseMap[log.exerciseId]?.mainMuscleGroup ?? '',
    );
    if (muscleGroup.isNotEmpty) {
      volumeByMuscle[muscleGroup] = (volumeByMuscle[muscleGroup] ?? 0) +
          (log.weight * log.reps);
    }
  }

  final trend = trendByWeek.entries.map((entry) {
    final weekLogs = entry.value;
    final volumeKg = weekLogs.fold<double>(
      0,
      (sum, log) => sum + log.weight * log.reps,
    );
    final topSetKg = weekLogs.fold<double>(
      0,
      (peak, log) {
        final estimate = _estimateOneRm(log);
        return estimate > peak ? estimate : peak;
      },
    );
    return PerformanceTrendPoint(
      weekStart: entry.key,
      volumeKg: volumeKg,
      topSetKg: topSetKg,
    );
  }).toList(growable: false)
    ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

  final muscleFocus = volumeByMuscle.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final focusTotal = totalVolumeKg <= 0 ? 1 : totalVolumeKg;
  final focusCards = [
    for (final entry in muscleFocus.take(3))
      PerformanceMuscleFocus(
        label: entry.key,
        volumeKg: entry.value,
        percent: ((entry.value / focusTotal) * 100).round(),
      ),
  ];

  final groupedByExercise = <int, List<WorkoutLogEntry>>{};
  for (final log in logs) {
    groupedByExercise.putIfAbsent(log.exerciseId, () => []).add(log);
  }

  final prCards = <PerformancePrCard>[];
  final oneRmCandidate = _bestSetForMetric(
    groupedByExercise,
    exerciseMap,
    metric: _Metric.oneRm,
  );
  if (oneRmCandidate != null) {
    prCards.add(oneRmCandidate);
  }
  final volumeCandidate = _bestSetForMetric(
    groupedByExercise,
    exerciseMap,
    metric: _Metric.volume,
  );
  if (volumeCandidate != null &&
      (prCards.isEmpty ||
          volumeCandidate.exerciseName != prCards.first.exerciseName ||
          volumeCandidate.label != prCards.first.label)) {
    prCards.add(volumeCandidate);
  }

  if (prCards.length > 2) {
    prCards.removeRange(2, prCards.length);
  }

  return PerformanceDashboardSummary(
    period: period,
    startDate: range.start,
    endDate: range.end,
    totalVolumeKg: totalVolumeKg,
    totalReps: totalReps,
    consistencyPercent: consistencyPercent,
    trainingDays: uniqueTrainingDays,
    trend: trend,
    muscleFocus: focusCards,
    recentPrs: prCards,
  );
}

ExerciseProgressDetailData _buildExerciseProgressDetail(
  List<WorkoutLogEntry> logs,
) {
  if (logs.isEmpty) {
    return ExerciseProgressDetailData.empty();
  }

  final sortedLogs = List<WorkoutLogEntry>.from(logs)
    ..sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.setNumber.compareTo(b.setNumber);
    });

  final totalVolumeKg = sortedLogs.fold<double>(
    0,
    (sum, entry) => sum + entry.weight * entry.reps,
  );
  final estimatedOneRmKg = sortedLogs.fold<double>(
    0,
    (peak, entry) {
      final estimate = _estimateOneRm(entry);
      return estimate > peak ? estimate : peak;
    },
  );

  final latest = sortedLogs.last;
  final groupedByWeek = <DateTime, List<WorkoutLogEntry>>{};
  final groupedByDate = <DateTime, List<WorkoutLogEntry>>{};

  for (final log in sortedLogs) {
    groupedByWeek.putIfAbsent(_weekStart(log.date), () => []).add(log);
    final day = DateTime(log.date.year, log.date.month, log.date.day);
    groupedByDate.putIfAbsent(day, () => []).add(log);
  }

  final trend = groupedByWeek.entries.map((entry) {
    final weekLogs = entry.value;
    final volumeKg = weekLogs.fold<double>(
      0,
      (sum, log) => sum + log.weight * log.reps,
    );
    final topOneRmKg = weekLogs.fold<double>(
      0,
      (peak, log) {
        final estimate = _estimateOneRm(log);
        return estimate > peak ? estimate : peak;
      },
    );
    return ExerciseProgressTrendPoint(
      weekStart: entry.key,
      volumeKg: volumeKg,
      oneRmKg: topOneRmKg,
    );
  }).toList(growable: false)
    ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

  final recentSessions = groupedByDate.entries
      .map((entry) {
        final dayLogs = entry.value;
        dayLogs.sort((a, b) => a.setNumber.compareTo(b.setNumber));
        final volumeKg = dayLogs.fold<double>(
          0,
          (sum, log) => sum + log.weight * log.reps,
        );
        final topSet = dayLogs.fold<WorkoutLogEntry>(
          dayLogs.first,
          (peak, log) => _estimateOneRm(log) > _estimateOneRm(peak) ? log : peak,
        );
        return ExerciseRecentSession(
          date: entry.key,
          setCount: dayLogs.length,
          volumeKg: volumeKg,
          topWeightKg: topSet.weight,
          topReps: topSet.reps,
          topOneRmKg: _estimateOneRm(topSet),
        );
      })
      .toList(growable: false)
    ..sort((a, b) => b.date.compareTo(a.date));

  return ExerciseProgressDetailData(
    estimatedOneRmKg: estimatedOneRmKg,
    totalVolumeKg: totalVolumeKg,
    lastSessionDate: DateTime(
      latest.date.year,
      latest.date.month,
      latest.date.day,
    ),
    lastWeightKg: latest.weight,
    lastReps: latest.reps,
    trend: trend,
    recentSessions: recentSessions.take(3).toList(growable: false),
  );
}

PerformancePrCard? _bestSetForMetric(
  Map<int, List<WorkoutLogEntry>> groupedByExercise,
  Map<int, Exercise> exerciseMap, {
  required _Metric metric,
}) {
  PerformancePrCard? best;
  for (final entry in groupedByExercise.entries) {
    final logs = List<WorkoutLogEntry>.from(entry.value)
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return a.setNumber.compareTo(b.setNumber);
      });
    if (logs.isEmpty) {
      continue;
    }

    final exerciseName = exerciseMap[entry.key]?.name ?? 'Exercise ${entry.key}';
    final selected = switch (metric) {
      _Metric.oneRm => _pickBestOneRmLog(logs),
      _Metric.volume => _pickBestVolumeDate(logs),
    };
    if (selected == null) {
      continue;
    }

    final detail = switch (metric) {
      _Metric.oneRm =>
        '${_formatNumber(selected.value)} kg × ${selected.reps} reps',
      _Metric.volume => '${_formatNumber(selected.value)} kg·reps',
    };
    final previous = switch (metric) {
      _Metric.oneRm => _previousBestOneRm(logs, selected.sourceIndex),
      _Metric.volume => _previousBestVolume(logs, selected.sourceIndex),
    };
    final deltaLabel = previous == null
        ? 'New peak'
        : _formatDelta(
            selected.value - previous,
            metric == _Metric.volume ? 'kg·reps' : 'kg',
          );

    final card = PerformancePrCard(
      label: switch (metric) {
        _Metric.oneRm => '1RM',
        _Metric.volume => 'VOL',
      },
      exerciseName: exerciseName,
      detail: detail,
      valueKg: selected.value,
      deltaLabel: deltaLabel,
      date: selected.date,
    );

    if (best == null ||
        selected.value > best.valueKg ||
        (selected.value == best.valueKg && selected.date.isAfter(best.date))) {
      best = card;
    }
  }

  return best;
}

_MetricSelection? _pickBestOneRmLog(List<WorkoutLogEntry> logs) {
  if (logs.isEmpty) {
    return null;
  }

  var bestIndex = 0;
  var bestValue = _estimateOneRm(logs.first);
  for (var index = 1; index < logs.length; index++) {
    final value = _estimateOneRm(logs[index]);
    if (value > bestValue ||
        (value == bestValue && logs[index].date.isAfter(logs[bestIndex].date))) {
      bestIndex = index;
      bestValue = value;
    }
  }

  return _MetricSelection(
    value: bestValue,
    date: logs[bestIndex].date,
    reps: logs[bestIndex].reps,
    sourceIndex: bestIndex,
  );
}

_MetricSelection? _pickBestVolumeDate(List<WorkoutLogEntry> logs) {
  if (logs.isEmpty) {
    return null;
  }

  final byDate = <DateTime, double>{};
  final byDateIndex = <DateTime, int>{};
  for (var index = 0; index < logs.length; index++) {
    final day = DateTime(
      logs[index].date.year,
      logs[index].date.month,
      logs[index].date.day,
    );
    byDate[day] = (byDate[day] ?? 0) + logs[index].weight * logs[index].reps;
    byDateIndex.putIfAbsent(day, () => index);
  }

  DateTime? bestDate;
  double? bestValue;
  for (final entry in byDate.entries) {
    if (bestValue == null ||
        entry.value > bestValue ||
        (entry.value == bestValue && entry.key.isAfter(bestDate!))) {
      bestDate = entry.key;
      bestValue = entry.value;
    }
  }

  if (bestDate == null || bestValue == null) {
    return null;
  }

  return _MetricSelection(
    value: bestValue,
    date: bestDate,
    reps: logs[byDateIndex[bestDate] ?? 0].reps,
    sourceIndex: byDateIndex[bestDate] ?? 0,
  );
}

double? _previousBestOneRm(List<WorkoutLogEntry> logs, int selectedIndex) {
  if (selectedIndex <= 0) {
    return null;
  }
  var best = 0.0;
  for (var i = 0; i < selectedIndex; i++) {
    final estimate = _estimateOneRm(logs[i]);
    if (estimate > best) {
      best = estimate;
    }
  }
  return best == 0 ? null : best;
}

double? _previousBestVolume(List<WorkoutLogEntry> logs, int selectedIndex) {
  if (selectedIndex <= 0) {
    return null;
  }
  final byDate = <DateTime, double>{};
  for (var i = 0; i < selectedIndex; i++) {
    final day = DateTime(
      logs[i].date.year,
      logs[i].date.month,
      logs[i].date.day,
    );
    byDate[day] = (byDate[day] ?? 0) + logs[i].weight * logs[i].reps;
  }
  if (byDate.isEmpty) {
    return null;
  }
  return byDate.values.reduce((a, b) => a > b ? a : b);
}

DateTime _weekStart(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - DateTime.monday));
}

double _estimateOneRm(WorkoutLogEntry entry) {
  return entry.weight * (1 + (entry.reps / 30));
}

String _normalizeMuscleGroup(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  return trimmed
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase()
      .split(' ')
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _formatNumber(double value) {
  if (value >= 1000) {
    return (value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1);
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

String _formatDelta(double value, String suffix) {
  if (value == 0) {
    return 'Flat';
  }
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(value.abs() >= 10 ? 0 : 1)} $suffix';
}

enum _Metric { oneRm, volume }

final class _MetricSelection {
  const _MetricSelection({
    required this.value,
    required this.date,
    required this.reps,
    required this.sourceIndex,
  });

  final double value;
  final DateTime date;
  final int reps;
  final int sourceIndex;
}
