import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_history_repository_impl.dart';
import '../../domain/usecases/get_workout_sessions_usecase.dart';
import '../../domain/usecases/get_workout_logs_usecase.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';

final _repoProvider = Provider((_) => WorkoutHistoryRepositoryImpl());

final workoutSessionsProvider = FutureProvider((ref) async {
  final usecase = GetWorkoutSessionsUseCase(ref.watch(_repoProvider));
  return usecase();
});

final workoutLogsProvider = FutureProvider((ref) async {
  final usecase = GetWorkoutLogsUseCase(ref.watch(_repoProvider));
  return usecase();
});

final logsByExerciseProvider =
    FutureProvider.family<List<WorkoutLogEntry>, int>((ref, exerciseId) async {
  final logs = await ref.watch(workoutLogsProvider.future);
  return logs.where((l) => l.exerciseId == exerciseId).toList();
});
