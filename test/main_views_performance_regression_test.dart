import 'package:fit_log/src/features/history/presentation/models/history_models.dart';
import 'package:fit_log/src/features/history/presentation/providers/history_overview_provider.dart';
import 'package:fit_log/src/features/history/presentation/providers/history_providers.dart';
import 'package:fit_log/src/features/routines/domain/entities/active_workout_session_draft.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_plan.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_session.dart';
import 'package:fit_log/src/features/routines/domain/repositories/workout_plan_repository.dart';
import 'package:fit_log/src/features/routines/presentation/providers/exercises_provider.dart';
import 'package:fit_log/src/features/routines/presentation/providers/workout_plan_provider.dart';
import 'package:fit_log/src/features/routines/presentation/providers/workout_plan_repository_provider.dart';
import 'package:fit_log/src/navigation/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _DummyRepo implements WorkoutPlanRepository {
  @override
  Future<ActiveWorkoutSessionDraft?> getActiveSessionDraft() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('bundled typography loads without runtime network fetching',
      (tester) async {
    await tester.runAsync(() async {
      for (final weight in [
        FontWeight.w300,
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
      ]) {
        GoogleFonts.spaceGrotesk(fontWeight: weight);
      }
      for (final weight in [
        FontWeight.w200,
        FontWeight.w300,
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
      ]) {
        GoogleFonts.manrope(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
    });
    expect(tester.takeException(), isNull);
  });

  group('History Overview Date Boundaries & Dual Filter Regressions', () {
    final plan1 = WorkoutPlan(id: 1, name: 'Plan Alpha', frequency: '3x');
    final plan2 = WorkoutPlan(id: 2, name: 'Plan Beta', frequency: '2x');
    final exercise1 = Exercise(
      id: 10,
      name: 'Bench Press',
      description: '',
      category: 'Compound',
      mainMuscleGroup: 'Chest',
    );
    final exercise2 = Exercise(
      id: 20,
      name: 'Squat',
      description: '',
      category: 'Compound',
      mainMuscleGroup: 'Legs',
    );

    test('history separates two saved sessions of the same routine and day',
        () async {
      final day = DateTime(2026, 10, 1);
      final container = ProviderContainer(overrides: [
        workoutPlanProvider
            .overrideWith((ref) => _FakeWorkoutPlanController([plan1])),
        allExercisesProvider.overrideWith((ref) => [exercise1]),
        workoutSessionsProvider.overrideWith((ref) => [
              for (final id in ['morning', 'evening'])
                WorkoutSession(
                    planId: 1,
                    date: day,
                    sessionId: id,
                    fatigueLevel: '5',
                    durationMinutes: 30,
                    mood: '3',
                    notes: id)
            ]),
        workoutLogsProvider.overrideWith((ref) => [
              for (final id in ['morning', 'evening'])
                WorkoutLogEntry(
                    planId: 1,
                    exerciseId: 10,
                    date: day,
                    sessionId: id,
                    setNumber: 1,
                    weight: 40,
                    reps: 8,
                    rir: 2)
            ]),
      ]);
      addTearDown(container.dispose);
      final overview = container
          .read(historyOverviewProvider(
              const HistoryFilter(period: HistoryPeriod.oneWeek)))
          .requireValue;
      expect(overview.sessions, hasLength(2));
      expect(overview.totalSets, 2);
      expect(overview.sessions.map((session) => session.notes).toSet(),
          {'morning', 'evening'});
    });

    test(
        'includes timestamps with microsecond precision on end day and boundaries',
        () {
      final container = ProviderContainer(
        overrides: [
          workoutPlanProvider.overrideWith(
              (ref) => _FakeWorkoutPlanController([plan1, plan2])),
          allExercisesProvider.overrideWith((ref) => [exercise1, exercise2]),
          workoutSessionsProvider.overrideWith(
            (ref) => [
              // Anchor session (latest date): 2026-10-10 23:59:59.999999
              // 1W range resolves to [2026-10-04, 2026-10-10]
              WorkoutSession(
                planId: 1,
                date: DateTime(2026, 10, 10, 23, 59, 59, 999, 999),
                fatigueLevel: 'Moderate',
                durationMinutes: 45,
                mood: 'Great',
                notes: 'Last microsecond of anchor day',
              ),
              // Start boundary session: 2026-10-04 00:00:00.000000 -> INCLUDED
              WorkoutSession(
                planId: 1,
                date: DateTime(2026, 10, 4, 0, 0, 0),
                fatigueLevel: 'Low',
                durationMinutes: 30,
                mood: 'Good',
                notes: 'Start day midnight',
              ),
              // Day before start range: 2026-10-03 23:59:59.999999 -> EXCLUDED
              WorkoutSession(
                planId: 1,
                date: DateTime(2026, 10, 3, 23, 59, 59, 999, 999),
                fatigueLevel: 'Low',
                durationMinutes: 30,
                mood: 'Fine',
                notes: 'Before start day',
              ),
              // Session on plan 2 within range
              WorkoutSession(
                planId: 2,
                date: DateTime(2026, 10, 8, 14, 0, 0),
                fatigueLevel: 'High',
                durationMinutes: 60,
                mood: 'Tired',
                notes: 'Plan 2 session',
              ),
            ],
          ),
          workoutLogsProvider.overrideWith(
            (ref) => [
              WorkoutLogEntry(
                planId: 1,
                exerciseId: 10,
                date: DateTime(2026, 10, 10, 23, 59, 59, 999, 999),
                setNumber: 1,
                weight: 100,
                reps: 5,
                rir: 2,
              ),
              WorkoutLogEntry(
                planId: 1,
                exerciseId: 10,
                date: DateTime(2026, 10, 4, 0, 0, 0),
                setNumber: 1,
                weight: 80,
                reps: 8,
                rir: 1,
              ),
              WorkoutLogEntry(
                planId: 2,
                exerciseId: 20,
                date: DateTime(2026, 10, 8, 14, 0, 0),
                setNumber: 1,
                weight: 120,
                reps: 5,
                rir: 3,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      // 1. All plans filter: 1W range should have 3 sessions (Oct 10, Oct 4, Oct 8), excluding Oct 3
      const allFilter = HistoryFilter(period: HistoryPeriod.oneWeek);
      final allOverview =
          container.read(historyOverviewProvider(allFilter)).requireValue;
      expect(allOverview.sessions.length, equals(3));
      expect(allOverview.totalVolumeKg,
          equals(100 * 5 + 80 * 8 + 120 * 5)); // 500 + 640 + 600 = 1740
      expect(allOverview.totalSets, equals(3));
      expect(allOverview.trainingDays, equals(3));

      // 2. Dual filter: planId = 1 isolates to plan 1 sessions
      const plan1Filter =
          HistoryFilter(period: HistoryPeriod.oneWeek, planId: 1);
      final plan1Overview =
          container.read(historyOverviewProvider(plan1Filter)).requireValue;
      expect(plan1Overview.sessions.length, equals(2));
      expect(plan1Overview.totalVolumeKg, equals(1140.0)); // 500 + 640
      expect(plan1Overview.sessions.every((s) => s.planId == 1), isTrue);

      // 3. Dual filter: exerciseId = 20 isolates to exercise 20 logs
      const ex20Filter =
          HistoryFilter(period: HistoryPeriod.oneWeek, exerciseId: 20);
      final ex20Overview =
          container.read(historyOverviewProvider(ex20Filter)).requireValue;
      expect(ex20Overview.sessions.length, equals(1));
      expect(ex20Overview.totalVolumeKg, equals(600.0));
      expect(ex20Overview.sessions.first.planId, equals(2));
    });

    test(
        'invalidates cache and updates totals when underlying logs/sessions change',
        () {
      final sessionsState = StateProvider<List<WorkoutSession>>((ref) => []);
      final logsState = StateProvider<List<WorkoutLogEntry>>((ref) => []);

      final container = ProviderContainer(
        overrides: [
          workoutPlanProvider
              .overrideWith((ref) => _FakeWorkoutPlanController([plan1])),
          allExercisesProvider.overrideWith((ref) => [exercise1]),
          workoutSessionsProvider
              .overrideWith((ref) => ref.watch(sessionsState)),
          workoutLogsProvider.overrideWith((ref) => ref.watch(logsState)),
        ],
      );
      addTearDown(container.dispose);

      const filter = HistoryFilter(period: HistoryPeriod.oneWeek);

      // Initially empty
      var overview =
          container.read(historyOverviewProvider(filter)).requireValue;
      expect(overview.sessions, isEmpty);
      expect(overview.totalVolumeKg, equals(0.0));
      expect(overview.planOptions, isEmpty);

      // Add a session and log
      final date = DateTime(2026, 10, 5, 10, 0);
      container.read(sessionsState.notifier).state = [
        WorkoutSession(
          planId: 1,
          date: date,
          fatigueLevel: 'Low',
          durationMinutes: 40,
          mood: 'Good',
          notes: '',
        ),
      ];
      container.read(logsState.notifier).state = [
        WorkoutLogEntry(
          planId: 1,
          exerciseId: 10,
          date: date,
          setNumber: 1,
          weight: 80,
          reps: 10,
          rir: 1,
        ),
      ];

      // Re-read overview: must reflect updated state immediately without stale cache
      overview = container.read(historyOverviewProvider(filter)).requireValue;
      expect(overview.sessions.length, equals(1));
      expect(overview.totalVolumeKg, equals(800.0)); // 80 * 10
      expect(overview.planOptions.length, equals(1));
      expect(overview.exerciseOptions.length, equals(1));
    });
  });

  group('MainScaffold TickerMode Optimization', () {
    testWidgets('pauses tickers on hidden tabs and activates on selected tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer(
        overrides: [
          workoutPlanRepositoryProvider.overrideWithValue(_DummyRepo()),
          workoutPlanProvider
              .overrideWith((ref) => _FakeWorkoutPlanController([])),
          routinePlanBusyIdsProvider.overrideWith((ref) => <int>{}),
          routineLibraryMetadataEpochProvider.overrideWith((ref) => 0),
          allExercisesProvider.overrideWith((ref) => <Exercise>[]),
          workoutSessionsProvider.overrideWith((ref) => <WorkoutSession>[]),
          workoutLogsProvider.overrideWith((ref) => <WorkoutLogEntry>[]),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MainScaffold(),
          ),
        ),
      );
      await tester.pump();

      // Directly verify IndexedStack tab children TickerModes
      final indexedStack =
          tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.children.length, equals(3));

      final tab0Ticker = indexedStack.children[0] as TickerMode;
      final tab1Ticker = indexedStack.children[1] as TickerMode;
      final tab2Ticker = indexedStack.children[2] as TickerMode;

      expect(tab0Ticker.enabled, isTrue);
      expect(tab1Ticker.enabled, isFalse);
      expect(tab2Ticker.enabled, isFalse);

      // Switch to History tab (tab index 1)
      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pump();

      final updatedIndexedStack =
          tester.widget<IndexedStack>(find.byType(IndexedStack));
      final updatedTab0Ticker = updatedIndexedStack.children[0] as TickerMode;
      final updatedTab1Ticker = updatedIndexedStack.children[1] as TickerMode;
      final updatedTab2Ticker = updatedIndexedStack.children[2] as TickerMode;

      expect(updatedTab0Ticker.enabled, isFalse);
      expect(updatedTab1Ticker.enabled, isTrue);
      expect(updatedTab2Ticker.enabled, isFalse);
    });
  });
}
