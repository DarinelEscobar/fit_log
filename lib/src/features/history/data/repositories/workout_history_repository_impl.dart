import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_session.dart';
import '../../../../data/services/workout_storage_service.dart';
import '../../domain/repositories/workout_history_repository.dart';

class WorkoutHistoryRepositoryImpl implements WorkoutHistoryRepository {
  WorkoutHistoryRepositoryImpl({WorkoutStorageService? storageService})
      : _storageService = storageService ?? WorkoutStorageService();

  final WorkoutStorageService _storageService;

  @override
  Future<List<WorkoutSession>> getAllSessions() async {
    return _storageService.fetchAllSessions();
  }

  @override
  Future<List<WorkoutLogEntry>> getAllLogs() async {
    return _storageService.fetchAllLogs();
  }
}
