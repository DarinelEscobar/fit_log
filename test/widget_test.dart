import 'package:fit_log/src/app.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/plan_exercise_detail.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_plan.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_session.dart';
import 'package:fit_log/src/features/routines/domain/repositories/workout_plan_repository.dart';
import 'package:fit_log/src/features/routines/presentation/providers/workout_plan_repository_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home dashboard is the default entry view', (tester) async {
    await _pumpApp(tester);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-hero-title')), findsOneWidget);
    expect(find.byKey(const Key('home-view-routines')), findsOneWidget);
    expect(find.byKey(const Key('home-manage-data')), findsOneWidget);
  });

  testWidgets('home actions open routines and data management', (tester) async {
    await _pumpApp(tester);

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('home-view-routines')));
    await tester.tap(find.byKey(const Key('home-view-routines')));
    await tester.pumpAndSettle();
    expect(find.text('My Routines'), findsOneWidget);

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('home-manage-data')));
    await tester.tap(find.byKey(const Key('home-manage-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('data-screen-title')), findsOneWidget);
  });

  testWidgets('routines flow opens exercise list and routine editor',
      (tester) async {
    final repo = _FakeWorkoutPlanRepository();
    await _pumpApp(tester, repo: repo);

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-view-routines')));
    await tester.pumpAndSettle();

    expect(find.text('My Routines'), findsOneWidget);
    expect(find.text('ACTIVE ROUTINES'), findsOneWidget);
    expect(repo.getAllExercisesCalls, 1);

    await tester.tap(find.byKey(const Key('routine-card-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exercise-list-title')), findsOneWidget);
    expect(
        find.byKey(const Key('exercise-list-start-workout')), findsOneWidget);

    await tester.tap(find.byTooltip('Edit routine').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('routine-editor-title')), findsOneWidget);
    expect(find.text('EXERCISES'), findsOneWidget);
    expect(find.text('EXERCISE NAME'), findsWidgets);
  });

  testWidgets('activating a routine keeps routines content visible',
      (tester) async {
    final repo = _FakeWorkoutPlanRepository(
      setPlanActiveDelay: const Duration(milliseconds: 180),
    );
    await _pumpApp(tester, repo: repo);

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-view-routines')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('INACTIVE ROUTINES'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate'));
    await tester.pump();

    expect(find.text('My Routines'), findsOneWidget);
    expect(find.text('ACTIVE ROUTINES'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();

    expect(repo.setPlanActiveCalls, 1);
    expect(find.text('3 ACTIVE'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  _FakeWorkoutPlanRepository? repo,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final effectiveRepo = repo ?? _FakeWorkoutPlanRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutPlanRepositoryProvider.overrideWithValue(
          effectiveRepo,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class _FakeWorkoutPlanRepository implements WorkoutPlanRepository {
  _FakeWorkoutPlanRepository({
    this.setPlanActiveDelay = Duration.zero,
  }) : _plans = [
          WorkoutPlan(id: 1, name: 'Upper A', frequency: 'Mon / Thu'),
          WorkoutPlan(id: 2, name: 'Lower Strength', frequency: 'Tue / Fri'),
          WorkoutPlan(
            id: 3,
            name: 'Mobility Reset',
            frequency: 'Daily',
            isActive: false,
          ),
        ];

  final Duration setPlanActiveDelay;
  final List<WorkoutPlan> _plans;
  int getAllExercisesCalls = 0;
  int setPlanActiveCalls = 0;

  final List<Exercise> _exercises = [
    Exercise(
      id: 1,
      name: 'Barbell Bench Press',
      description: 'Drive through the floor and keep the bar path stacked.',
      category: 'Strength',
      mainMuscleGroup: 'Chest',
    ),
    Exercise(
      id: 2,
      name: 'Weighted Pull-ups',
      description: 'Full extension at the bottom and control the descent.',
      category: 'Strength',
      mainMuscleGroup: 'Back',
    ),
    Exercise(
      id: 3,
      name: 'Romanian Deadlift',
      description: 'Load the hips and keep the lats tight.',
      category: 'Strength',
      mainMuscleGroup: 'Hamstrings',
    ),
  ];

  final Map<int, List<PlanExerciseDetail>> _details = {
    1: [
      PlanExerciseDetail(
        exerciseId: 1,
        name: 'Barbell Bench Press',
        description: 'Drive through the floor and keep the bar path stacked.',
        sets: 4,
        reps: 8,
        weight: 185,
        restSeconds: 90,
        rir: 2,
        tempo: '3-1-1-0',
      ),
      PlanExerciseDetail(
        exerciseId: 2,
        name: 'Weighted Pull-ups',
        description: 'Full extension at the bottom and control the descent.',
        sets: 3,
        reps: 6,
        weight: 35,
        restSeconds: 120,
        rir: 1,
        tempo: '2-1-1-0',
      ),
    ],
    2: [
      PlanExerciseDetail(
        exerciseId: 3,
        name: 'Romanian Deadlift',
        description: 'Load the hips and keep the lats tight.',
        sets: 4,
        reps: 8,
        weight: 225,
        restSeconds: 120,
        rir: 2,
        tempo: '3-0-1-0',
      ),
    ],
    3: const [],
  };

  @override
  Future<void> addExerciseToPlan(int planId, PlanExerciseDetail detail,
      {int? position}) async {}

  @override
  Future<void> createExercise(
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) async {}

  @override
  Future<void> createWorkoutPlan(String name, String frequency) async {}

  @override
  Future<void> deleteExerciseFromPlan(int planId, int exerciseId) async {}

  @override
  Future<List<Exercise>> getAllExercises() async {
    getAllExercisesCalls++;
    return _exercises;
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async =>
      List<WorkoutPlan>.from(_plans);

  @override
  Future<List<Exercise>> getExercisesForPlan(int planId) async {
    final detailIds =
        (_details[planId] ?? const []).map((d) => d.exerciseId).toSet();
    return _exercises
        .where((exercise) => detailIds.contains(exercise.id))
        .toList();
  }

  @override
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId) async =>
      _details[planId] ?? const [];

  @override
  Future<List<Exercise>> getSimilarExercises(int exerciseId) async => const [];

  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {}

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {}

  @override
  Future<void> setWorkoutPlanActive(int planId, bool isActive) async {
    setPlanActiveCalls++;
    if (setPlanActiveDelay > Duration.zero) {
      await Future<void>.delayed(setPlanActiveDelay);
    }

    final index = _plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) {
      return;
    }

    final plan = _plans[index];
    _plans[index] = WorkoutPlan(
      id: plan.id,
      name: plan.name,
      frequency: plan.frequency,
      isActive: isActive,
    );
  }

  @override
  Future<void> updateExercise(
    int id,
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) async {}

  @override
  Future<void> updateExerciseInPlan(
      int planId, PlanExerciseDetail detail) async {}

  @override
  Future<void> updateWorkoutPlan(
      int planId, String name, String frequency) async {}
}
