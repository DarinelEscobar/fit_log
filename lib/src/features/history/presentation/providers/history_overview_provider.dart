import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routines/domain/entities/exercise.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_plan.dart';
import '../../../routines/domain/entities/workout_session.dart';
import '../../../routines/presentation/providers/exercises_provider.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../models/history_models.dart';
import 'history_providers.dart';

final historyOverviewProvider =
    Provider.family<AsyncValue<HistoryOverviewData>, HistoryFilter>(
  (ref, filter) {
    final plansAsync = ref.watch(workoutPlanProvider);
    final sessionsAsync = ref.watch(workoutSessionsProvider);
    final logsAsync = ref.watch(workoutLogsProvider);
    final exercisesAsync = ref.watch(allExercisesProvider);

    final error = _firstError([
      plansAsync,
      sessionsAsync,
      logsAsync,
      exercisesAsync,
    ]);
    if (error != null) {
      return AsyncError(error.error, error.stackTrace);
    }

    if (!plansAsync.hasValue ||
        !sessionsAsync.hasValue ||
        !logsAsync.hasValue ||
        !exercisesAsync.hasValue) {
      return const AsyncLoading();
    }

    return AsyncData(
      _buildHistoryOverview(
        filter: filter,
        plans: plansAsync.requireValue,
        sessions: sessionsAsync.requireValue,
        logs: logsAsync.requireValue,
        exercises: exercisesAsync.requireValue,
      ),
    );
  },
);

AsyncError<dynamic>? _firstError(List<AsyncValue<dynamic>> values) {
  for (final value in values) {
    final error = value.asError;
    if (error != null) {
      return error;
    }
  }
  return null;
}

HistoryOverviewData _buildHistoryOverview({
  required HistoryFilter filter,
  required List<WorkoutPlan> plans,
  required List<WorkoutSession> sessions,
  required List<WorkoutLogEntry> logs,
  required List<Exercise> exercises,
}) {
  final planMap = {for (final plan in plans) plan.id: plan};
  final exerciseMap = {for (final exercise in exercises) exercise.id: exercise};
  final anchorDate = _latestDate(sessions, logs) ?? DateTime.now();
  final range = filter.period.resolve(anchorDate);

  final availablePlanIds = <int>{
    for (final session in sessions) session.planId,
    for (final log in logs) log.planId,
  };
  final planOptions = [
    for (final planId in availablePlanIds)
      HistoryPlanOption(
        planId: planId,
        name: planMap[planId]?.name ?? 'Plan $planId',
      ),
  ]..sort((a, b) => a.name.compareTo(b.name));

  final filteredSessions = sessions.where((session) {
    return _matchesFilter(
      planId: session.planId,
      date: session.date,
      filter: filter,
      range: range,
    );
  }).toList(growable: false);

  final filteredLogs = logs.where((log) {
    return _matchesFilter(
      planId: log.planId,
      date: log.date,
      filter: filter,
      range: range,
    );
  }).toList(growable: false);

  final sessionsByKey = {
    for (final session in filteredSessions)
      _HistorySessionKey(session.planId, _day(session.date)): session,
  };
  final logsByKey = <_HistorySessionKey, List<WorkoutLogEntry>>{};
  for (final log in filteredLogs) {
    final key = _HistorySessionKey(log.planId, _day(log.date));
    logsByKey.putIfAbsent(key, () => <WorkoutLogEntry>[]).add(log);
  }

  final keys = <_HistorySessionKey>{
    ...sessionsByKey.keys,
    ...logsByKey.keys,
  }.toList()
    ..sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      final aName = planMap[a.planId]?.name ?? 'Plan ${a.planId}';
      final bName = planMap[b.planId]?.name ?? 'Plan ${b.planId}';
      return aName.compareTo(bName);
    });

  final sessionSummaries = [
    for (final key in keys)
      _buildSessionSummary(
        key: key,
        session: sessionsByKey[key],
        logs: logsByKey[key] ?? const <WorkoutLogEntry>[],
        planMap: planMap,
        exerciseMap: exerciseMap,
      ),
  ];

  final totalVolumeKg = sessionSummaries.fold<double>(
    0,
    (sum, session) => sum + session.totalVolumeKg,
  );
  final totalSets = sessionSummaries.fold<int>(
    0,
    (sum, session) => sum + session.totalSets,
  );
  final durationSessions = sessionSummaries
      .where((session) => session.durationMinutes > 0)
      .toList(growable: false);
  final averageDurationMinutes = durationSessions.isEmpty
      ? 0
      : (durationSessions.fold<int>(
                0,
                (sum, session) => sum + session.durationMinutes,
              ) /
              durationSessions.length)
          .round();

  return HistoryOverviewData(
    filter: filter,
    range: range,
    planOptions: planOptions,
    sessions: sessionSummaries,
    totalVolumeKg: totalVolumeKg,
    totalSets: totalSets,
    trainingDays:
        sessionSummaries.map((session) => _day(session.date)).toSet().length,
    averageDurationMinutes: averageDurationMinutes,
  );
}

DateTime? _latestDate(
  List<WorkoutSession> sessions,
  List<WorkoutLogEntry> logs,
) {
  DateTime? latest;
  for (final session in sessions) {
    if (latest == null || session.date.isAfter(latest)) {
      latest = session.date;
    }
  }
  for (final log in logs) {
    if (latest == null || log.date.isAfter(latest)) {
      latest = log.date;
    }
  }
  return latest;
}

bool _matchesFilter({
  required int planId,
  required DateTime date,
  required HistoryFilter filter,
  required HistoryDateRange range,
}) {
  if (filter.planId != null && planId != filter.planId) {
    return false;
  }
  final day = _day(date);
  return !day.isBefore(range.start) && !day.isAfter(range.end);
}

HistorySessionSummary _buildSessionSummary({
  required _HistorySessionKey key,
  required WorkoutSession? session,
  required List<WorkoutLogEntry> logs,
  required Map<int, WorkoutPlan> planMap,
  required Map<int, Exercise> exerciseMap,
}) {
  final exercises = _buildExerciseSummaries(logs, exerciseMap);
  final totalVolumeKg = logs.fold<double>(
    0,
    (sum, log) => sum + log.weight * log.reps,
  );
  final totalReps = logs.fold<int>(0, (sum, log) => sum + log.reps);

  return HistorySessionSummary(
    planId: key.planId,
    planName: planMap[key.planId]?.name ?? 'Plan ${key.planId}',
    date: key.date,
    durationMinutes: session?.durationMinutes ?? 0,
    energy: session?.fatigueLevel ?? '',
    mood: session?.mood ?? '',
    notes: session?.notes ?? '',
    totalVolumeKg: totalVolumeKg,
    totalSets: logs.length,
    totalReps: totalReps,
    exercises: exercises,
  );
}

List<HistoryExerciseSummary> _buildExerciseSummaries(
  List<WorkoutLogEntry> logs,
  Map<int, Exercise> exerciseMap,
) {
  final byExercise = <int, List<WorkoutLogEntry>>{};
  for (final log in logs) {
    byExercise.putIfAbsent(log.exerciseId, () => <WorkoutLogEntry>[]).add(log);
  }

  final summaries = [
    for (final entry in byExercise.entries)
      _buildExerciseSummary(entry.key, entry.value, exerciseMap[entry.key]),
  ]..sort((a, b) => a.name.compareTo(b.name));

  return summaries;
}

HistoryExerciseSummary _buildExerciseSummary(
  int exerciseId,
  List<WorkoutLogEntry> logs,
  Exercise? exercise,
) {
  final sortedLogs = List<WorkoutLogEntry>.from(logs)
    ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  final topLog = sortedLogs.fold<WorkoutLogEntry?>(
    null,
    (top, log) => top == null || log.weight > top.weight ? log : top,
  );

  return HistoryExerciseSummary(
    exerciseId: exerciseId,
    name: exercise?.name ?? 'Exercise $exerciseId',
    description: exercise?.description ?? '',
    category: exercise?.category ?? '',
    mainMuscleGroup: exercise?.mainMuscleGroup ?? '',
    volumeKg: sortedLogs.fold<double>(
      0,
      (sum, log) => sum + log.weight * log.reps,
    ),
    totalReps: sortedLogs.fold<int>(0, (sum, log) => sum + log.reps),
    topWeightKg: topLog?.weight ?? 0,
    topReps: topLog?.reps ?? 0,
    sets: [
      for (final log in sortedLogs)
        HistorySetRow(
          setNumber: log.setNumber,
          weightKg: log.weight,
          reps: log.reps,
          rir: log.rir,
        ),
    ],
  );
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

final class _HistorySessionKey {
  const _HistorySessionKey(this.planId, this.date);

  final int planId;
  final DateTime date;

  @override
  bool operator ==(Object other) {
    return other is _HistorySessionKey &&
        other.planId == planId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(planId, date);
}
