// lib/src/features/history/presentation/pages/exercise_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/exercise_logs_chart.dart';
import '../providers/history_providers.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_session.dart';
import 'package:intl/intl.dart';

class ExerciseLogsScreen extends ConsumerWidget {
  final int exerciseId;
  final String exerciseName;

  const ExerciseLogsScreen({
    Key? key,
    required this.exerciseId,
    required this.exerciseName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogs = ref.watch(logsByExerciseProvider(exerciseId));
    final asyncSessions = ref.watch(workoutSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(exerciseName)),
      body: asyncLogs.when(
        data: (logs) => asyncSessions.when(
          data: (sessions) => ExerciseLogsChart(data: _summaries(logs, sessions)),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<WeekSummary> _summaries(
    List<WorkoutLogEntry> logs,
    List<WorkoutSession> sessions,
  ) {
    final sessionMap = <DateTime, WorkoutSession>{};
    for (final s in sessions) {
      final monday = s.date.subtract(Duration(days: s.date.weekday - 1));
      final key = DateTime(monday.year, monday.month, monday.day);
      sessionMap[key] = s;
    }

    final map = <DateTime, List<WorkoutLogEntry>>{};
    for (final l in logs) {
      final monday = l.date.subtract(Duration(days: l.date.weekday - 1));
      final key = DateTime(monday.year, monday.month, monday.day);
      map.putIfAbsent(key, () => []).add(l);
    }
    final sorted = map.keys.toList()..sort();
    final result = <WeekSummary>[];
    for (final k in sorted) {
      final entries = map[k]!;
      final volume = entries.fold<double>(0, (s, e) => s + e.reps * e.weight);
      entries.sort((a, b) {
        final cw = b.weight.compareTo(a.weight);
        if (cw != 0) return cw;
        return a.rir.compareTo(b.rir);
      });
      result.add(WeekSummary(k, volume, entries.first, sessionMap[k]));
    }
    return result;
  }
}


