import 'package:fit_log/src/features/performance/domain/models/active_exercise_progress.dart';
import 'package:fit_log/src/data/providers/workout_storage_service_provider.dart';
import 'package:fit_log/src/data/services/workout_storage_service.dart';
import 'package:fit_log/src/features/performance/presentation/models/performance_models.dart';
import 'package:fit_log/src/features/performance/presentation/providers/active_exercise_progress_provider.dart';
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
    expect(summary.activeExercises, isNotEmpty);
    expect(summary.activeExercises.first.exerciseId, 10);
    expect(summary.activeExercises.first.name, 'Leg Press');
    expect(summary.activeExercises.first.totalVolumeKg, 1000);
    expect(summary.recentPrs.first.exerciseId, 10);
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

  test('exercise progress detail builds correct trend and session history',
      () async {
    final storage = _FakePerformanceStorage(
      activeExerciseIds: const [10],
      exerciseLogs: [
        WorkoutLogEntry(
          date: DateTime(2024, 2, 1),
          planId: 1,
          exerciseId: 10,
          setNumber: 1,
          reps: 10,
          weight: 100,
          rir: 2,
        ),
        WorkoutLogEntry(
          date: DateTime(2024, 2, 8),
          planId: 1,
          exerciseId: 10,
          setNumber: 1,
          reps: 8,
          weight: 120,
          rir: 1,
        ),
      ],
    );
    final container = _container(storage);
    addTearDown(container.dispose);

    final detail = await container.read(
      exerciseProgressDetailProvider(10).future,
    );

    expect(detail.totalVolumeKg, 100 * 10 + 120 * 8);
    expect(detail.lastWeightKg, 120);
    expect(detail.lastReps, 8);
    expect(detail.recentSessions.length, 2);
    expect(detail.trend.length, 2);
  });

  test('active exercise progress excludes current-day logs from baseline',
      () async {
    final storage = _FakePerformanceStorage(
      activeExerciseIds: const [],
      exerciseLogs: [
        WorkoutLogEntry(
          date: DateTime(2024, 2, 9),
          planId: 1,
          exerciseId: 10,
          setNumber: 1,
          reps: 5,
          weight: 100,
          rir: 2,
        ),
        WorkoutLogEntry(
          date: DateTime(2024, 2, 10),
          planId: 1,
          exerciseId: 10,
          setNumber: 1,
          reps: 5,
          weight: 200,
          rir: 2,
        ),
      ],
    );
    final container = _container(storage);
    addTearDown(container.dispose);

    final insight = await container.read(
      activeExerciseProgressProvider(
        ActiveExerciseProgressRequest(
          exerciseId: 10,
          sessionDate: DateTime(2024, 2, 10, 16),
        ),
      ).future,
    );

    expect(insight.lastSession?.date, DateTime(2024, 2, 9));
    expect(
      insight.recentBaseline?.comparableStrengthKg,
      closeTo(100 * (1 + 5 / 30), 0.01),
    );
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
