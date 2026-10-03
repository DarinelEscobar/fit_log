import 'package:fit_log/src/features/history/presentation/pages/history_screen.dart';
import 'package:fit_log/src/features/history/presentation/providers/history_providers.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_plan.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_session.dart';
import 'package:fit_log/src/features/routines/presentation/providers/exercises_provider.dart';
import 'package:fit_log/src/features/routines/presentation/providers/workout_plan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class _FakeWorkoutPlanController
    extends StateNotifier<AsyncValue<List<WorkoutPlan>>>
    implements WorkoutPlanController {
  _FakeWorkoutPlanController(List<WorkoutPlan> plans)
      : super(AsyncData(plans));

  @override
  Future<void> refresh({bool silent = false}) async {}

  @override
  Future<void> setPlanActive(int planId, bool isActive) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final baseAnchor = DateTime(2026, 10, 2);

  final List<WorkoutPlan> testPlans = [
    WorkoutPlan(id: 1, name: 'Upper Body Power', frequency: 'Mon / Thu'),
    WorkoutPlan(id: 2, name: 'Lower Body Hypertrophy', frequency: 'Tue / Fri'),
  ];

  final List<Exercise> testExercises = [
    Exercise(
      id: 1,
      name: 'Barbell Bench Press',
      category: 'Barbell',
      mainMuscleGroup: 'Chest',
      description: 'Flat bench',
    ),
    Exercise(
      id: 2,
      name: 'Incline Dumbbell Press',
      category: 'Dumbbell',
      mainMuscleGroup: 'Chest',
      description: 'Incline bench',
    ),
    Exercise(
      id: 3,
      name: 'Barbell Squat',
      category: 'Barbell',
      mainMuscleGroup: 'Quadriceps',
      description: 'Back squat',
    ),
  ];

  // Create sessions spread over multiple weeks and months
  final session1 = WorkoutSession(
    date: baseAnchor, // 2026-10-02 (Week of Sep 28 - Oct 4, Month: Oct 2026)
    planId: 1,
    fatigueLevel: '8',
    mood: '4',
    notes: 'Heavy upper workout, good chest pump',
    durationMinutes: 55,
  );
  final session2 = WorkoutSession(
    date: baseAnchor.subtract(const Duration(days: 2)), // 2026-09-30 (Sep 28 - Oct 4, Month: Sep 2026)
    planId: 2,
    fatigueLevel: '7',
    mood: '5',
    notes: 'Leg day high intensity',
    durationMinutes: 60,
  );
  final session3 = WorkoutSession(
    date: baseAnchor.subtract(const Duration(days: 10)), // 2026-09-22 (Sep 21 - Sep 27, Month: Sep 2026)
    planId: 1,
    fatigueLevel: '9',
    mood: '4',
    notes: 'Upper volume session',
    durationMinutes: 50,
  );
  final session4 = WorkoutSession(
    date: DateTime(2026, 8, 15), // Month: August 2026
    planId: 2,
    fatigueLevel: '6',
    mood: '4',
    notes: 'August squat PR',
    durationMinutes: 65,
  );

  final testSessions = [session1, session2, session3, session4];

  final testLogs = [
    // Session 1: Bench Press + Incline DB Press
    WorkoutLogEntry(
      date: session1.date,
      planId: 1,
      exerciseId: 1,
      setNumber: 1,
      weight: 100.0,
      reps: 8,
      rir: 2,
    ),
    WorkoutLogEntry(
      date: session1.date,
      planId: 1,
      exerciseId: 1,
      setNumber: 2,
      weight: 100.0,
      reps: 8,
      rir: 1,
    ),
    WorkoutLogEntry(
      date: session1.date,
      planId: 1,
      exerciseId: 2,
      setNumber: 1,
      weight: 36.0,
      reps: 10,
      rir: 2,
    ),
    // Session 2: Squat
    WorkoutLogEntry(
      date: session2.date,
      planId: 2,
      exerciseId: 3,
      setNumber: 1,
      weight: 140.0,
      reps: 6,
      rir: 2,
    ),
    WorkoutLogEntry(
      date: session2.date,
      planId: 2,
      exerciseId: 3,
      setNumber: 2,
      weight: 140.0,
      reps: 6,
      rir: 1,
    ),
    // Session 3: Bench Press only
    WorkoutLogEntry(
      date: session3.date,
      planId: 1,
      exerciseId: 1,
      setNumber: 1,
      weight: 95.0,
      reps: 10,
      rir: 2,
    ),
    // Session 4: Squat
    WorkoutLogEntry(
      date: session4.date,
      planId: 2,
      exerciseId: 3,
      setNumber: 1,
      weight: 145.0,
      reps: 5,
      rir: 1,
    ),
  ];

  Widget buildTestApp({
    List<WorkoutPlan>? plans,
    List<Exercise>? exercises,
    List<WorkoutSession>? sessions,
    List<WorkoutLogEntry>? logs,
  }) {
    return ProviderScope(
      overrides: [
        workoutPlanProvider.overrideWith(
          (ref) => _FakeWorkoutPlanController(plans ?? testPlans),
        ),
        allExercisesProvider.overrideWith(
          (ref) async => exercises ?? testExercises,
        ),
        workoutSessionsProvider.overrideWith(
          (ref) async => sessions ?? testSessions,
        ),
        workoutLogsProvider.overrideWith(
          (ref) async => logs ?? testLogs,
        ),
      ],
      child: const MaterialApp(
        home: HistoryScreen(),
      ),
    );
  }

  testWidgets('HistoryScreen renders 4W view with week groups, expanding first group by default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify Title & Period
    expect(find.byKey(const Key('history-screen-title')), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('SESSION REVIEW'), findsOneWidget);

    // In 4W: session1 (Oct 2), session2 (Sep 30), session3 (Sep 22) are within 28 days. session4 (Aug 15) is outside.
    // 3 sessions total in 4W
    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // 3 workouts
    expect(find.text('3 training days'), findsOneWidget);

    // Week groups should exist
    // Week 1: Sep 28 – Oct 4 contains session1 and session2 (2 workouts)
    // Week 2: Sep 21 – Sep 27 contains session3 (1 workout)
    expect(find.textContaining('Sep 28 – Oct 4'), findsOneWidget);
    expect(find.textContaining('Sep 21 – Sep 27'), findsOneWidget);

    // Session 1 and Session 2 session cards are visible (keys):
    final session1Card = find.byKey(Key('history-session-1-${DateFormat('yyyy-MM-dd').format(session1.date)}'));
    final session2Card = find.byKey(Key('history-session-2-${DateFormat('yyyy-MM-dd').format(session2.date)}'));
    expect(session1Card, findsOneWidget);
    expect(session2Card, findsOneWidget);

    // The second week group is collapsed initially, so session 3 is not visible:
    final session3Card = find.byKey(Key('history-session-1-${DateFormat('yyyy-MM-dd').format(session3.date)}'));
    expect(session3Card, findsNothing);

    // Expand week 2:
    final week2Toggle = find.byKey(const Key('history-group-toggle-week_2026_09_21'));
    expect(week2Toggle, findsOneWidget);
    await tester.tap(week2Toggle);
    await tester.pumpAndSettle();

    // Now session 3 is also visible
    expect(session3Card, findsOneWidget);

    // Collapse week 1:
    final week1Toggle = find.byKey(const Key('history-group-toggle-week_2026_09_28'));
    await tester.tap(week1Toggle);
    await tester.pumpAndSettle();

    // Week 1 sessions are now collapsed:
    expect(find.byKey(Key('history-session-1-${DateFormat('yyyy-MM-dd').format(session1.date)}')), findsNothing);
    expect(find.byKey(Key('history-session-2-${DateFormat('yyyy-MM-dd').format(session2.date)}')), findsNothing);
    // Week 2 session remains visible:
    expect(session3Card, findsOneWidget);
  });

  testWidgets('HistoryScreen 1W renders direct flat concise list without grouping headers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Switch to 1W
    final period1W = find.byKey(const Key('history-period-oneWeek'));
    expect(period1W, findsOneWidget);
    await tester.tap(period1W);
    await tester.pumpAndSettle();

    // In 1W (last 7 days from anchor Oct 2): session1 (Oct 2) and session2 (Sep 30) match.
    expect(find.text('2'), findsOneWidget); // 2 workouts
    expect(find.text('2 training days'), findsOneWidget);

    // Flat list: no week group headers (no "Sep 28 – Oct 4" group header)
    expect(find.byKey(const Key('history-group-toggle-week_2026_09_28')), findsNothing);

    // Both sessions directly visible via session keys
    expect(find.byKey(Key('history-session-1-${DateFormat('yyyy-MM-dd').format(session1.date)}')), findsOneWidget);
    expect(find.byKey(Key('history-session-2-${DateFormat('yyyy-MM-dd').format(session2.date)}')), findsOneWidget);
  });

  testWidgets('HistoryScreen YTD groups by month with compact disclosure', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Switch to YTD
    final periodYTD = find.byKey(const Key('history-period-yearToDate'));
    expect(periodYTD, findsOneWidget);
    await tester.tap(periodYTD);
    await tester.pumpAndSettle();

    // All 4 sessions are in 2026 YTD
    expect(find.text('4'), findsOneWidget); // 4 workouts
    expect(find.text('4 training days'), findsOneWidget);

    // Month groups: October 2026, September 2026, August 2026
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('August 2026'), findsOneWidget);

    // First month (October 2026) is expanded by default (session1)
    expect(find.byKey(Key('history-session-1-${DateFormat('yyyy-MM-dd').format(session1.date)}')), findsOneWidget);
    // August is collapsed initially (session4)
    expect(find.byKey(Key('history-session-2-${DateFormat('yyyy-MM-dd').format(session4.date)}')), findsNothing);

    // Tap to expand August 2026
    final augToggle = find.byKey(const Key('history-group-toggle-month_2026_08'));
    expect(augToggle, findsOneWidget);
    await tester.tap(augToggle);
    await tester.pumpAndSettle();

    expect(find.byKey(Key('history-session-2-${DateFormat('yyyy-MM-dd').format(session4.date)}')), findsOneWidget);
  });

  testWidgets('HistoryScreen exercise filter updates stats and lists accurately', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Check exercise filter chips exist
    expect(find.byKey(const Key('history-exercise-filter-all')), findsOneWidget);
    final benchPressFilter = find.byKey(const Key('history-exercise-filter-1'));
    expect(benchPressFilter, findsOneWidget);

    // Select Barbell Bench Press (exerciseId: 1)
    await tester.tap(benchPressFilter);
    await tester.pumpAndSettle();

    // Bench press is in session 1 (Oct 2) and session 3 (Sep 22) -> 2 workouts in 4W
    // Session 2 was Squat only, so it must be excluded!
    expect(find.text('2'), findsOneWidget); // 2 workouts
    expect(find.text('2 training days'), findsOneWidget);
    expect(find.byKey(Key('history-session-2-${DateFormat('yyyy-MM-dd').format(session2.date)}')), findsNothing); // Session 2 excluded

    // CLEAR FILTERS button appears
    final clearButton = find.text('CLEAR FILTERS');
    expect(clearButton, findsOneWidget);

    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    // Back to 3 workouts in 4W
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('HistoryScreen plan filter isolates workouts for selected plan', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Select Lower Body Hypertrophy (planId: 2)
    final plan2Filter = find.byKey(const Key('history-plan-filter-2'));
    expect(plan2Filter, findsOneWidget);
    await tester.tap(plan2Filter);
    await tester.pumpAndSettle();

    // Only session 2 matches in 4W
    expect(find.text('1 training days'), findsOneWidget);
    expect(find.byKey(Key('history-session-2-${DateFormat('yyyy-MM-dd').format(session2.date)}')), findsOneWidget);
    expect(find.byKey(Key('history-session-1-${DateFormat('yyyy-MM-dd').format(session1.date)}')), findsNothing);
  });

  testWidgets('Tapping session card opens HistorySessionDetailScreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Switch to 1W to have flat list
    await tester.tap(find.byKey(const Key('history-period-oneWeek')));
    await tester.pumpAndSettle();

    // Tap Upper Body Power session card
    final sessionCard = find.byKey(Key('history-session-1-${DateFormat('yyyy-MM-dd').format(baseAnchor)}'));
    expect(sessionCard, findsOneWidget);
    await tester.tap(sessionCard);
    await tester.pumpAndSettle();

    // Verify detail screen opened
    expect(find.byKey(const Key('history-session-detail-title')), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Incline Dumbbell Press'), findsOneWidget);
    expect(find.text('PROGRESS'), findsNWidgets(2));
  });

  testWidgets('HistoryScreen handles empty state gracefully', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(sessions: [], logs: []));
    await tester.pumpAndSettle();

    expect(find.text('No sessions in this window'), findsOneWidget);
    expect(find.text('Finish a workout or choose a wider period to review previous training.'), findsOneWidget);
  });
}
