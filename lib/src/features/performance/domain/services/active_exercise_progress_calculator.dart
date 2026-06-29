import '../../../routines/domain/entities/workout_log_entry.dart';
import '../models/active_exercise_progress.dart';

final class ActiveExerciseProgressCalculator {
  static const int recentSessionLimit = 5;
  static const int workingSetLimit = 3;
  static const double workingSetFloorRatio = 0.90;
  static const double holdingThresholdPercent = 0.025;

  const ActiveExerciseProgressCalculator._();

  static ActiveExerciseProgressInsight buildInsight({
    required List<WorkoutLogEntry> logs,
    required DateTime currentSessionDate,
  }) {
    final currentDay = DateTime(
      currentSessionDate.year,
      currentSessionDate.month,
      currentSessionDate.day,
    );
    final previousLogs = logs
        .where((log) => log.activeProgressDay.isBefore(currentDay))
        .toList(growable: false);
    final sessions = _buildSessionSummaries(previousLogs);

    if (sessions.isEmpty) {
      return ActiveExerciseProgressInsight.empty();
    }

    final recentSessions = sessions.length <= recentSessionLimit
        ? sessions
        : sessions.sublist(sessions.length - recentSessionLimit);
    final baselineKg = _median(
      recentSessions
          .map((session) => session.comparableStrengthKg)
          .toList(growable: false),
    );

    return ActiveExerciseProgressInsight(
      lastSession: sessions.last,
      recentBaseline: baselineKg == null
          ? null
          : ActiveExerciseProgressBaseline(
              comparableStrengthKg: baselineKg,
              sessionCount: recentSessions.length,
            ),
      recentTrendPoints: [
        for (final session in recentSessions)
          ActiveExerciseTrendPoint(
            date: session.date,
            comparableStrengthKg: session.comparableStrengthKg,
          ),
      ],
      confidence: _confidenceFor(recentSessions.length),
    );
  }

  static ActiveExerciseSessionSummary? buildCurrentSession(
    List<WorkoutLogEntry> logs,
  ) {
    return buildSessionSummary(logs);
  }

  static ActiveExerciseSessionSummary? buildSessionSummary(
    List<WorkoutLogEntry> logs,
  ) {
    final usableLogs = logs.where(_isUsableSet).toList(growable: false)
      ..sort((a, b) {
        final setCompare = a.setNumber.compareTo(b.setNumber);
        if (setCompare != 0) {
          return setCompare;
        }
        return a.date.compareTo(b.date);
      });

    if (usableLogs.isEmpty) {
      return null;
    }

    final rawSets = [
      for (final log in usableLogs)
        ActiveExerciseSetSummary(
          setNumber: log.setNumber,
          reps: log.reps,
          weightKg: log.weight,
          estimatedOneRmKg: estimateOneRm(log),
          isWorkingSet: false,
        ),
    ];
    final topEstimatedOneRmKg = rawSets.fold<double>(
      0,
      (peak, set) => set.estimatedOneRmKg > peak ? set.estimatedOneRmKg : peak,
    );
    final candidates = [
      for (var index = 0; index < rawSets.length; index++)
        if (topEstimatedOneRmKg <= 0 ||
            rawSets[index].estimatedOneRmKg >=
                topEstimatedOneRmKg * workingSetFloorRatio)
          _WorkingSetCandidate(index: index, set: rawSets[index]),
    ]..sort((a, b) {
        final estimateCompare =
            b.set.estimatedOneRmKg.compareTo(a.set.estimatedOneRmKg);
        if (estimateCompare != 0) {
          return estimateCompare;
        }
        return a.set.setNumber.compareTo(b.set.setNumber);
      });
    final selectedCandidates =
        candidates.take(workingSetLimit).toList(growable: false);
    final workingIndexes =
        selectedCandidates.map((candidate) => candidate.index).toSet();
    final selectedComparableValues = selectedCandidates
        .map((candidate) => candidate.set.estimatedOneRmKg)
        .toList(growable: false);
    final comparableStrengthKg = selectedComparableValues.isEmpty
        ? 0.0
        : selectedComparableValues.reduce((a, b) => a + b) /
            selectedComparableValues.length;
    final sets = [
      for (var index = 0; index < rawSets.length; index++)
        rawSets[index].copyWith(isWorkingSet: workingIndexes.contains(index)),
    ];
    final topSet = sets.reduce((best, set) {
      if (set.estimatedOneRmKg > best.estimatedOneRmKg) {
        return set;
      }
      return best;
    });
    final volumeKg = usableLogs.fold<double>(
      0,
      (sum, log) => sum + (log.weight * log.reps),
    );
    final firstLog = usableLogs.first;

    return ActiveExerciseSessionSummary(
      date: firstLog.activeProgressDay,
      planId: firstLog.planId,
      setCount: usableLogs.length,
      volumeKg: volumeKg,
      comparableStrengthKg: comparableStrengthKg,
      topWeightKg: topSet.weightKg,
      topReps: topSet.reps,
      topEstimatedOneRmKg: topSet.estimatedOneRmKg,
      sets: sets,
    );
  }

  static ActiveExerciseProgressDelta compareCurrentToBaseline({
    required ActiveExerciseSessionSummary? currentSession,
    required ActiveExerciseProgressBaseline? baseline,
  }) {
    if (currentSession == null) {
      return const ActiveExerciseProgressDelta(
        status: ActiveExerciseProgressDeltaStatus.pending,
        currentComparableStrengthKg: 0,
        baselineComparableStrengthKg: 0,
        deltaKg: 0,
        deltaPercent: 0,
      );
    }

    final baselineKg = baseline?.comparableStrengthKg ?? 0;
    if (baselineKg <= 0) {
      return ActiveExerciseProgressDelta(
        status: ActiveExerciseProgressDeltaStatus.noBaseline,
        currentComparableStrengthKg: currentSession.comparableStrengthKg,
        baselineComparableStrengthKg: baselineKg,
        deltaKg: 0,
        deltaPercent: 0,
      );
    }

    final deltaKg = currentSession.comparableStrengthKg - baselineKg;
    final deltaPercent = deltaKg / baselineKg;
    final status = deltaPercent >= holdingThresholdPercent
        ? ActiveExerciseProgressDeltaStatus.ahead
        : deltaPercent <= -holdingThresholdPercent
            ? ActiveExerciseProgressDeltaStatus.below
            : ActiveExerciseProgressDeltaStatus.holding;

    return ActiveExerciseProgressDelta(
      status: status,
      currentComparableStrengthKg: currentSession.comparableStrengthKg,
      baselineComparableStrengthKg: baselineKg,
      deltaKg: deltaKg,
      deltaPercent: deltaPercent,
    );
  }

  static double estimateOneRm(WorkoutLogEntry entry) {
    return entry.weight * (1 + entry.reps / 30);
  }

  static List<ActiveExerciseSessionSummary> _buildSessionSummaries(
    List<WorkoutLogEntry> logs,
  ) {
    final grouped = <_SessionKey, List<WorkoutLogEntry>>{};
    for (final log in logs) {
      final key = _SessionKey(log.activeProgressDay, log.planId);
      grouped.putIfAbsent(key, () => []).add(log);
    }

    final sessions = <ActiveExerciseSessionSummary>[];
    for (final entry in grouped.entries) {
      final summary = buildSessionSummary(entry.value);
      if (summary != null) {
        sessions.add(summary);
      }
    }

    sessions.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.planId.compareTo(b.planId);
    });
    return sessions;
  }

  static bool _isUsableSet(WorkoutLogEntry log) {
    return log.completed &&
        log.reps > 0 &&
        log.weight.isFinite &&
        log.weight >= 0;
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) {
      return null;
    }

    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static ActiveExerciseProgressConfidence _confidenceFor(int sessionCount) {
    return switch (sessionCount) {
      0 => ActiveExerciseProgressConfidence.none,
      1 => ActiveExerciseProgressConfidence.low,
      <= 3 => ActiveExerciseProgressConfidence.medium,
      _ => ActiveExerciseProgressConfidence.high,
    };
  }
}

final class _WorkingSetCandidate {
  const _WorkingSetCandidate({
    required this.index,
    required this.set,
  });

  final int index;
  final ActiveExerciseSetSummary set;
}

final class _SessionKey {
  const _SessionKey(this.date, this.planId);

  final DateTime date;
  final int planId;

  @override
  bool operator ==(Object other) {
    return other is _SessionKey && other.date == date && other.planId == planId;
  }

  @override
  int get hashCode => Object.hash(date, planId);
}
