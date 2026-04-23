import 'package:fit_log/src/data/providers/workout_storage_service_provider.dart';
import 'package:fit_log/src/data/services/workout_storage_service.dart';
import 'package:fit_log/src/features/performance/presentation/models/performance_models.dart';
import 'package:fit_log/src/features/performance/presentation/providers/performance_providers.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/presentation/providers/exercises_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('dashboard anchors period to latest active-exercise log', () async {
    final storage = _FakePerformanceStorage(
      activeExerciseIds: const [10],
      latestExerciseDate: DateTime(2024, 2, 10),
      exerciseLogs: [
        WorkoutLogEntry(
          date: DateTime(2024, 2, 10),
          planId: 1,
          exerciseId: 10,
          setNumber: 1,
          reps: 10,
          weight: 100,
          rir: 2,
        ),
      ],
    );
    final container = _container(storage);
    addTearDown(container.dispose);

    final summary = await container.read(
      performanceDashboardProvider(
        const PerformanceDashboardRequest(
          period: PerformancePeriod.oneWeek,
          activePlanIds: [99],
        ),
      ).future,
    );

    expect(summary.hasData, isTrue);
    expect(summary.totalVolumeKg, 1000);
    expect(summary.totalReps, 10);
    expect(summary.endDate, DateTime(2024, 2, 10));
  });

  test(
      'dashboard falls back to active-plan logs when exercise history is empty',
      () async {
    final storage = _FakePerformanceStorage(
      activeExerciseIds: const [10],
      latestPlanDate: DateTime(2024, 2, 10),
      planLogs: [
        WorkoutLogEntry(
          date: DateTime(2024, 2, 10),
          planId: 99,
          exerciseId: 42,
          setNumber: 1,
          reps: 8,
          weight: 50,
          rir: 2,
        ),
      ],
    );
    final container = _container(storage);
    addTearDown(container.dispose);

    final summary = await container.read(
      performanceDashboardProvider(
        const PerformanceDashboardRequest(
          period: PerformancePeriod.oneWeek,
          activePlanIds: [99],
        ),
      ).future,
    );

    expect(summary.hasData, isTrue);
    expect(summary.totalVolumeKg, 400);
    expect(summary.totalReps, 8);
  });
}

ProviderContainer _container(_FakePerformanceStorage storage) {
  return ProviderContainer(
    overrides: [
      workoutStorageServiceProvider.overrideWithValue(storage),
      allExercisesProvider.overrideWith((ref) async => [
            Exercise(
              id: 10,
              name: 'Leg Press',
              description: '',
              category: 'Compound',
              mainMuscleGroup: 'Legs',
            ),
            Exercise(
              id: 42,
              name: 'Shoulder Press',
              description: '',
              category: 'Compound',
              mainMuscleGroup: 'Shoulders',
            ),
          ]),
    ],
  );
}

final class _FakePerformanceStorage extends WorkoutStorageService {
  _FakePerformanceStorage({
    required this.activeExerciseIds,
    this.latestExerciseDate,
    this.latestPlanDate,
    this.exerciseLogs = const [],
    this.planLogs = const [],
  });

  final List<int> activeExerciseIds;
  final DateTime? latestExerciseDate;
  final DateTime? latestPlanDate;
  final List<WorkoutLogEntry> exerciseLogs;
  final List<WorkoutLogEntry> planLogs;

  @override
  Future<List<int>> fetchExerciseIdsForPlans(List<int> planIds) async {
    return activeExerciseIds;
  }

  @override
  Future<DateTime?> fetchLatestWorkoutLogDate({
    List<int>? planIds,
    List<int>? exerciseIds,
    int? exerciseId,
  }) async {
    if (exerciseIds != null || exerciseId != null) {
      return latestExerciseDate;
    }
    return latestPlanDate;
  }

  @override
  Future<List<WorkoutLogEntry>> fetchWorkoutLogs({
    List<int>? planIds,
    List<int>? exerciseIds,
    int? exerciseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final source =
        exerciseIds != null || exerciseId != null ? exerciseLogs : planLogs;
    return source.where((log) {
      if (startDate != null && log.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && log.date.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }
}
