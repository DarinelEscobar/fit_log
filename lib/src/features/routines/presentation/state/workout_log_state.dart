// lib/src/features/routines/presentation/state/workout_log_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_log_entry.dart';

class WorkoutLogNotifier extends StateNotifier<List<WorkoutLogEntry>> {
  WorkoutLogNotifier() : super(const []);

  void add(WorkoutLogEntry e) => state = [...state, e];
  void remove(WorkoutLogEntry e) => state = [...state]..remove(e);
  void clear() => state = const [];
}

final workoutLogProvider =
    StateNotifierProvider<WorkoutLogNotifier, List<WorkoutLogEntry>>(
        (ref) => WorkoutLogNotifier());
