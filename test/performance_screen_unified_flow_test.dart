import 'package:fit_log/src/data/providers/workout_storage_service_provider.dart';
import 'package:fit_log/src/data/services/workout_storage_service.dart';
import 'package:fit_log/src/features/performance/presentation/pages/exercise_progress_detail_screen.dart';
import 'package:fit_log/src/features/performance/presentation/pages/performance_dashboard_screen.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_plan.dart';
import 'package:fit_log/src/features/routines/presentation/models/exercise_list_view_data.dart';
import 'package:fit_log/src/features/routines/presentation/providers/exercises_provider.dart';
import 'package:fit_log/src/features/routines/presentation/providers/workout_plan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeWorkoutPlanController
    extends StateNotifier<AsyncValue<List<WorkoutPlan>>>
    implements WorkoutPlanController {
  _FakeWorkoutPlanController(List<WorkoutPlan> plans) : super(AsyncData(plans));

  @override
  Future<void> refresh({bool silent = false}) async {}

  @override
  Future<void> setPlanActive(int planId, bool isActive) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakePerformanceFlowStorage extends WorkoutStorageService {
  _FakePerformanceFlowStorage({
    required this.activeExerciseIds,
    this.latestExerciseDate,
    this.latestPlanDate,
    this.logs = const [],
  });

  final List<int> activeExerciseIds;
  final DateTime? latestExerciseDate;
  final DateTime? latestPlanDate;
  final List<WorkoutLogEntry> logs;

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
    return logs.where((log) {
      if (exerciseId != null && log.exerciseId != exerciseId) {
        return false;
      }
      if (exerciseIds != null && !exerciseIds.contains(log.exerciseId)) {
        return false;
      }
      if (planIds != null && !planIds.contains(log.planId)) {
        return false;
      }
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

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final anchor = DateTime(2026, 10, 2);

  final testPlans = [
    WorkoutPlan(id: 1, name: 'Upper Body Power', frequency: 'Mon / Thu'),
    WorkoutPlan(id: 2, name: 'Lower Body Strength', frequency: 'Tue / Fri'),
  ];

  final testExercises = [
    Exercise(
      id: 10,
      name: 'Bench Press',
      category: 'Barbell',
      mainMuscleGroup: 'Chest',
      description: 'Flat barbell bench press with paused reps',
    ),
    Exercise(
      id: 20,
      name: 'Barbell Squat',
      category: 'Barbell',
      mainMuscleGroup: 'Legs',
      description: 'Full depth back squat',
    ),
  ];

  final testLogs = [
    // Session 1: Bench Press (Oct 2)
    WorkoutLogEntry(
      date: anchor,
      planId: 1,
      exerciseId: 10,
      setNumber: 1,
      weight: 100,
      reps: 8,
      rir: 2,
    ),
    WorkoutLogEntry(
      date: anchor,
      planId: 1,
      exerciseId: 10,
      setNumber: 2,
      weight: 100,
      reps: 8,
      rir: 1,
    ),
    // Session 2: Squat (Sep 28)
    WorkoutLogEntry(
      date: anchor.subtract(const Duration(days: 4)),
      planId: 2,
      exerciseId: 20,
      setNumber: 1,
      weight: 140,
      reps: 6,
      rir: 2,
    ),
    WorkoutLogEntry(
      date: anchor.subtract(const Duration(days: 4)),
      planId: 2,
      exerciseId: 20,
      setNumber: 2,
      weight: 140,
      reps: 6,
      rir: 1,
    ),
    // Session 3: Bench Press (Sep 15)
    WorkoutLogEntry(
      date: anchor.subtract(const Duration(days: 17)),
      planId: 1,
      exerciseId: 10,
      setNumber: 1,
      weight: 95,
      reps: 10,
      rir: 2,
    ),
  ];

  Widget buildDashboardApp({
    List<WorkoutPlan>? plans,
    List<Exercise>? exercises,
    List<WorkoutLogEntry>? logs,
    WorkoutStorageService? customStorage,
  }) {
    final storage = customStorage ??
        _FakePerformanceFlowStorage(
          activeExerciseIds: const [10, 20],
          latestExerciseDate: anchor,
          latestPlanDate: anchor,
          logs: logs ?? testLogs,
        );

    return ProviderScope(
      overrides: [
        workoutPlanProvider.overrideWith(
          (ref) => _FakeWorkoutPlanController(plans ?? testPlans),
        ),
        allExercisesProvider.overrideWith(
          (ref) async => exercises ?? testExercises,
        ),
        workoutStorageServiceProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(
        home: PerformanceDashboardScreen(),
      ),
    );
  }

  testWidgets(
      'PerformanceDashboardScreen renders hero volume, period selector, trends, and exercise explorer',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDashboardApp());
    await tester.pumpAndSettle();

    // Verify AppBar Title & Toru
    expect(find.byKey(const Key('performance-dashboard-title')), findsOneWidget);
    expect(find.text('PERFORMANCE'), findsOneWidget);

    // Period selector chips
    expect(find.byKey(const Key('performance-period-oneWeek')), findsOneWidget);
    expect(find.byKey(const Key('performance-period-fourWeeks')), findsOneWidget);
    expect(find.byKey(const Key('performance-period-twelveWeeks')), findsOneWidget);
    expect(find.byKey(const Key('performance-period-yearToDate')), findsOneWidget);

    // Active routines indicator
    expect(find.text('ACTIVE ROUTINES'), findsOneWidget);
    expect(find.text('2 ACTIVE'), findsOneWidget);

    // Hero Total Volume in 4W:
    // Bench: 100*8*2 = 1600; Squat: 140*6*2 = 1680; Bench Sep 15: 95*10 = 950. Total = 4230 (4.2k)
    expect(find.text('4.2k'), findsOneWidget);
    expect(find.text('kg·reps'), findsWidgets);
    expect(find.text('3 training days • 4W window'), findsOneWidget);

    // Volume trend section
    expect(find.text('Volume Trend'), findsOneWidget);
    expect(find.text('Weekly Volume (kg·reps)'), findsOneWidget);

    // Muscle Focus breakdown
    expect(find.text('Muscle Focus'), findsOneWidget);
    expect(find.text('4W DISTRIBUTION'), findsOneWidget);
    expect(find.text('CHEST'), findsWidgets);
    expect(find.text('LEGS'), findsWidgets);

    // Recent PRs section
    expect(find.text('Recent PRs'), findsOneWidget);

    // Exercise Progress Explorer
    expect(find.text('Exercise Progress'), findsOneWidget);
    expect(find.text('2 EXERCISES'), findsOneWidget);
    expect(find.byKey(const Key('performance-exercise-card-10')), findsOneWidget);
    expect(find.byKey(const Key('performance-exercise-card-20')), findsOneWidget);
  });

  testWidgets(
      'PerformanceDashboardScreen switches periods and updates calculations cleanly',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDashboardApp());
    await tester.pumpAndSettle();

    // Switch to 1W
    await tester.tap(find.byKey(const Key('performance-period-oneWeek')));
    await tester.pumpAndSettle();

    // 1W has Bench (Oct 2) and Squat (Sep 28). Total volume = 1600 + 1680 = 3280 (3.3k)
    expect(find.text('3.3k'), findsOneWidget);
    expect(find.text('2 training days • 1W window'), findsOneWidget);
  });

  testWidgets(
      'Performance dashboard renders weekly volume trend chart accurately',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDashboardApp());
    await tester.pumpAndSettle();

    expect(find.text('Volume Trend'), findsOneWidget);
    expect(find.text('4W WEEKLY LOAD'), findsOneWidget);
    expect(find.text('Weekly Volume (kg·reps)'), findsOneWidget);
  });

  testWidgets(
      'Exercise explorer search filters exercises dynamically and handles clear',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDashboardApp());
    await tester.pumpAndSettle();

    // Both exercises visible
    expect(find.byKey(const Key('performance-exercise-card-10')), findsOneWidget);
    expect(find.byKey(const Key('performance-exercise-card-20')), findsOneWidget);

    // Search for "Squat"
    await tester.enterText(find.byType(TextField), 'Squat');
    await tester.pumpAndSettle();

    // Only Squat visible
    expect(find.byKey(const Key('performance-exercise-card-20')), findsOneWidget);
    expect(find.byKey(const Key('performance-exercise-card-10')), findsNothing);

    // Clear search
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    // Both visible again
    expect(find.byKey(const Key('performance-exercise-card-10')), findsOneWidget);
    expect(find.byKey(const Key('performance-exercise-card-20')), findsOneWidget);
  });

  testWidgets(
      'Tapping exercise card in explorer navigates to ExerciseProgressDetailScreen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDashboardApp());
    await tester.pumpAndSettle();

    // Tap Bench Press tile
    final benchTile = find.byKey(const Key('performance-exercise-card-10'));
    await tester.ensureVisible(benchTile);
    await tester.pumpAndSettle();
    await tester.tap(benchTile);
    await tester.pumpAndSettle();

    // Verify detail screen opened
    expect(find.text('PROGRESSION'), findsOneWidget);
    expect(find.byKey(const Key('exercise-progress-title')), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('EST. 1RM'), findsOneWidget);
    expect(find.text('LAST SESSION'), findsOneWidget);
    expect(find.text('TOTAL VOLUME'), findsOneWidget);
    expect(find.text('Progression Trend'), findsOneWidget);
    expect(find.text('Exercise Blueprint'), findsOneWidget);
    expect(find.text('Recent Sessions'), findsOneWidget);
  });

  testWidgets(
      'ExerciseProgressDetailScreen metric toggle and session history render accurately',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const itemView = ExerciseListItemView(
      exerciseId: 10,
      name: 'Bench Press',
      description: 'Flat bench test description',
      category: 'Barbell',
      mainMuscleGroup: 'Chest',
      sets: 3,
      reps: 8,
      restSeconds: 120,
      weight: 100,
    );

    final storage = _FakePerformanceFlowStorage(
      activeExerciseIds: const [10],
      logs: testLogs,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutStorageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: ExerciseProgressDetailScreen(exercise: itemView),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Key stats
    expect(find.text('EST. 1RM'), findsOneWidget);
    expect(find.text('126.7'), findsOneWidget); // 100 * (1 + 8/30) = 126.666
    expect(find.text('LAST SESSION'), findsOneWidget);
    expect(find.text('kg × 8'), findsOneWidget);

    // Exercise Blueprint
    expect(find.text('Exercise Blueprint'), findsOneWidget);
    expect(find.text('3 sets × 8 reps'), findsOneWidget);
    expect(find.text('120s'), findsOneWidget);
    expect(find.text('100 kg'), findsWidgets);

    // Progression Trend toggle
    expect(find.text('Estimated 1RM (kg)'), findsOneWidget);
    await tester.tap(find.text('VOLUME'));
    await tester.pumpAndSettle();
    expect(find.text('Session Volume (kg·reps)'), findsOneWidget);

    // Recent Sessions
    expect(find.text('Recent Sessions'), findsOneWidget);
    expect(find.text('2 LOGGED'), findsOneWidget);
  });

  testWidgets(
      'PerformanceDashboardScreen handles no active routines empty state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildDashboardApp(
        plans: [],
        logs: [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active routines yet'), findsOneWidget);
    expect(
      find.text(
        'Performance analytics will appear once you activate routines and record sessions.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'PerformanceDashboardScreen handles no logs in period state cleanly',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildDashboardApp(
        logs: [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No logs found for this period'), findsOneWidget);
    expect(
      find.text(
        'The 4W dashboard uses logged sets for exercises in your current active routines.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'ExerciseProgressDetailScreen renders at 375x667 with 1.8x text scale without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const itemView = ExerciseListItemView(
      exerciseId: 10,
      name: 'Bench Press',
      description: 'Flat bench test description',
      category: 'Barbell',
      mainMuscleGroup: 'Chest',
      sets: 3,
      reps: 8,
      restSeconds: 120,
      weight: 100,
    );

    final storage = _FakePerformanceFlowStorage(
      activeExerciseIds: const [10],
      logs: testLogs,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutStorageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(375, 667),
              textScaler: TextScaler.linear(1.8),
            ),
            child: ExerciseProgressDetailScreen(exercise: itemView),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll chart into view
    final trendFinder = find.text('Progression Trend');
    await tester.scrollUntilVisible(
      trendFinder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify 1RM mode legend renders cleanly
    expect(find.text('Estimated 1RM (kg)'), findsOneWidget);

    // Toggle to volume mode and ensure legend wraps without overflow
    await tester.tap(find.text('VOLUME'));
    await tester.pumpAndSettle();
    expect(find.text('Session Volume (kg·reps)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
