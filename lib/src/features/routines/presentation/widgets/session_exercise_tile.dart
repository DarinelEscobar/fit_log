import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/exercise_tile.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../services/workout_session_helper.dart';
import '../../../history/presentation/providers/history_providers.dart';

class SessionExerciseTile extends ConsumerWidget {
  final PlanExerciseDetail detail;
  final int index;
  final int? expandedExerciseId;
  final void Function(int exerciseId) onToggle;
  final Map<int, GlobalKey<ExerciseTileState>> keys;
  final Map<String, WorkoutLogEntry> logsMap;
  final bool highlightDone;
  final VoidCallback onChanged;
  final void Function(WorkoutLogEntry) removeLog;
  final void Function(WorkoutLogEntry) updateLog;
  final int planId;
  final bool showBest;
  final VoidCallback? onSwap;

  const SessionExerciseTile({
    super.key,
    required this.detail,
    required this.index,
    required this.expandedExerciseId,
    required this.onToggle,
    required this.keys,
    required this.logsMap,
    required this.highlightDone,
    required this.onChanged,
    required this.removeLog,
    required this.updateLog,
    required this.planId,
    required this.showBest,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    keys[detail.exerciseId] ??= GlobalKey<ExerciseTileState>();
    final asyncLogs = ref.watch(logsByExerciseProvider(detail.exerciseId));
    return asyncLogs.when(
      data: (logs) {
        final last = WorkoutSessionHelper.lastLogs(logs);
        final best = WorkoutSessionHelper.bestLogs(logs);
        return ExerciseTile(
          key: keys[detail.exerciseId],
          detail: detail,
          expanded: expandedExerciseId == detail.exerciseId,
          onToggle: () => onToggle(detail.exerciseId),
          logsMap: logsMap,
          highlightDone: highlightDone,
          onChanged: onChanged,
          removeLog: removeLog,
          update: updateLog,
          planId: planId,
          lastLogs: last,
          bestLogs: best,
          showBest: showBest,
          onSwap: onSwap,
        );
      },
      loading: () => ExerciseTile(
        key: keys[detail.exerciseId],
        detail: detail,
        expanded: expandedExerciseId == detail.exerciseId,
        onToggle: () => onToggle(detail.exerciseId),
        logsMap: logsMap,
        highlightDone: highlightDone,
        onChanged: onChanged,
        removeLog: removeLog,
        update: updateLog,
        planId: planId,
        showBest: showBest,
        onSwap: onSwap,
      ),
      error: (e, _) => ExerciseTile(
        key: keys[detail.exerciseId],
        detail: detail,
        expanded: expandedExerciseId == detail.exerciseId,
        onToggle: () => onToggle(detail.exerciseId),
        logsMap: logsMap,
        highlightDone: highlightDone,
        onChanged: onChanged,
        removeLog: removeLog,
        update: updateLog,
        planId: planId,
        showBest: showBest,
        onSwap: onSwap,
      ),
    );
  }
}
