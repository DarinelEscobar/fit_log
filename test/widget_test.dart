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
    expect(find.text('Rutinas'), findsOneWidget);

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('home-manage-data')));
    await tester.tap(find.byKey(const Key('home-manage-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('data-screen-title')), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutPlanRepositoryProvider.overrideWithValue(
          _FakeWorkoutPlanRepository(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class _FakeWorkoutPlanRepository implements WorkoutPlanRepository {
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
  Future<List<Exercise>> getAllExercises() async => const [];

  @override
  Future<List<WorkoutPlan>> getAllPlans() async => [
        WorkoutPlan(id: 1, name: 'Upper A', frequency: 'Mon / Thu'),
      ];

  @override
  Future<List<Exercise>> getExercisesForPlan(int planId) async => const [];

  @override
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId) async =>
      const [];

  @override
  Future<List<Exercise>> getSimilarExercises(int exerciseId) async => const [];

  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {}

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {}

  @override
  Future<void> setWorkoutPlanActive(int planId, bool isActive) async {}

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
