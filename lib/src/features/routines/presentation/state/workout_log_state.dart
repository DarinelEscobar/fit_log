import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_log_entry.dart';

/// ­Key = "exerciseId-setNumber".
typedef _Key = String;

class WorkoutLogNotifier extends StateNotifier<Map<_Key, WorkoutLogEntry>> {
  WorkoutLogNotifier() : super({});

  // ── CRUD ───────────────────────────────────────────────────────────
  void addOrUpdate(WorkoutLogEntry e) =>
      state = {...state, _k(e): e.copyWith(completed: true)};

  void toggleComplete(WorkoutLogEntry e) =>
      state = {
        ...state,
        _k(e): e.copyWith(completed: !(state[_k(e)]?.completed ?? false))
      };

  void remove(WorkoutLogEntry e) {
    final map = {...state}..remove(_k(e));
    state = map;
  }

  void clear() => state = {};

  /// Sólo los sets marcados como completados (para guardar).
  List<WorkoutLogEntry> get completedLogs =>
      state.values.where((e) => e.completed).toList();

  /// Todos los sets (útil para debug).
  List<WorkoutLogEntry> get allLogs => state.values.toList();

  // ── util ───────────────────────────────────────────────────────────
  _Key _k(WorkoutLogEntry e) => '${e.exerciseId}-${e.setNumber}';
}

final workoutLogProvider =
    StateNotifierProvider<WorkoutLogNotifier, Map<_Key, WorkoutLogEntry>>(
        (ref) => WorkoutLogNotifier());
