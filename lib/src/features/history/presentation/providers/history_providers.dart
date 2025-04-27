import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_history_repository_impl.dart';
import '../../domain/usecases/get_workout_sessions_usecase.dart';
import '../../domain/usecases/get_workout_logs_usecase.dart';

final _repoProvider = Provider((_) => WorkoutHistoryRepositoryImpl());

final workoutSessionsProvider = FutureProvider((ref) {
  final usecase = GetWorkoutSessionsUseCase(ref.watch(_repoProvider));
  return usecase();
});

final workoutLogsProvider = FutureProvider((ref) {
  final usecase = GetWorkoutLogsUseCase(ref.watch(_repoProvider));
  return usecase();
});