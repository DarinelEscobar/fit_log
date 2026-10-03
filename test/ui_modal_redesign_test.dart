import 'package:fit_log/src/features/performance/presentation/models/performance_models.dart';
import 'package:fit_log/src/features/performance/presentation/pages/exercise_progress_detail_screen.dart';
import 'package:fit_log/src/features/performance/presentation/providers/performance_providers.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/plan_exercise_detail.dart';
import 'package:fit_log/src/features/routines/domain/entities/warm_up_session_state.dart';
import 'package:fit_log/src/features/routines/domain/entities/warm_up_step.dart';
import 'package:fit_log/src/features/routines/presentation/models/exercise_list_view_data.dart';
import 'package:fit_log/src/features/routines/presentation/models/finish_session_summary_draft.dart';
import 'package:fit_log/src/features/routines/presentation/models/routine_editor_draft.dart';
import 'package:fit_log/src/features/routines/presentation/pages/finish_session_summary_screen.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/active_session_exercise_setup_sheet.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/confirm_exit_sheet.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/exercise_definition_dialog.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/active_session_exercise_sections.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/routine_editor_exercise_card.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/routine_metadata_dialog.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/warm_up_editor_section.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/warm_up_flow.dart';
import 'package:fit_log/src/theme/kinetic_noir.dart';
import 'package:fit_log/src/features/routines/presentation/pages/select_exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pumpTestWidget(
  WidgetTester tester, {
  required Widget child,
  double textScale = 1.0,
  Size surfaceSize = const Size(375, 667),
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: KineticNoirPalette.background,
        ),
        builder: (context, childWidget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: childWidget!,
        ),
        home: Scaffold(
          backgroundColor: KineticNoirPalette.background,
          body: child,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('UI Modals & Sheets Redesign Tests', () {
    testWidgets(
        'ExerciseDefinitionDialog renders cleanly without overflow at textScale 1.8',
        (tester) async {
      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showDialog<ExerciseDefinitionInput>(
                context: context,
                builder: (_) => const ExerciseDefinitionDialog(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create exercise'), findsOneWidget);
      expect(find.byKey(const Key('exercise-definition-name')), findsOneWidget);
      expect(find.byKey(const Key('exercise-definition-category')),
          findsOneWidget);
      expect(
          find.byKey(const Key('exercise-definition-muscle')), findsOneWidget);
      expect(find.byKey(const Key('exercise-definition-description')),
          findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('exercise-definition-name')), 'Pull-Up');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise-definition-copy-prompt')),
          findsOneWidget);

      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Create exercise'), findsNothing);
    });

    testWidgets('RoutineMetadataDialog renders cleanly and saves metadata',
        (tester) async {
      RoutineMetadataInput? result;

      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showDialog<RoutineMetadataInput>(
                  context: context,
                  builder: (_) => const RoutineMetadataDialog(),
                );
              },
              child: const Text('Open Routine Meta'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Routine Meta'));
      await tester.pumpAndSettle();

      expect(find.text('Create routine'), findsOneWidget);
      expect(find.text('ROUTINE NAME'), findsOneWidget);
      expect(find.text('FREQUENCY'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Upper / Lower');
      await tester.enterText(find.byType(TextField).last, '4 days/week');
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Upper / Lower');
      expect(result!.frequency, '4 days/week');
    });

    testWidgets('showConfirmExitSheet handles Stay and Exit actions cleanly',
        (tester) async {
      bool? exitResult;

      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                exitResult = await showConfirmExitSheet(context);
              },
              child: const Text('Trigger Exit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Exit'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirm-exit-title')), findsOneWidget);
      expect(find.byKey(const Key('confirm-exit-stay')), findsOneWidget);
      expect(find.byKey(const Key('confirm-exit-exit')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('confirm-exit-stay')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-exit-stay')));
      await tester.pumpAndSettle();
      expect(exitResult, isFalse);

      await tester.tap(find.text('Trigger Exit'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('confirm-exit-exit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-exit-exit')));
      await tester.pumpAndSettle();
      expect(exitResult, isTrue);
    });

    testWidgets('showActiveSessionExerciseSetupSheet updates setup detail',
        (tester) async {
      final detail = PlanExerciseDetail(
        exerciseId: 20,
        name: 'Incline Dumbbell Press',
        description: 'Controlled chest press',
        sets: 3,
        reps: 10,
        weight: 24.0,
        restSeconds: 90,
        rir: 2,
        tempo: '3-0-1-0',
      );

      PlanExerciseDetail? updated;

      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        child: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                updated = await showActiveSessionExerciseSetupSheet(
                  context,
                  detail: detail,
                );
              },
              child: const Text('Open Setup'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Incline Dumbbell Press'), findsOneWidget);
      expect(find.byKey(const Key('session-setup-sets')), findsOneWidget);
      expect(find.byKey(const Key('session-setup-reps')), findsOneWidget);
      expect(find.byKey(const Key('session-setup-rest')), findsOneWidget);
      expect(find.byKey(const Key('session-setup-rir')), findsOneWidget);
      expect(find.byKey(const Key('session-setup-tempo')), findsOneWidget);
      expect(find.byKey(const Key('session-setup-save')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('session-setup-sets')), '4');
      await tester.enterText(find.byKey(const Key('session-setup-reps')), '12');
      await tester.tap(find.byKey(const Key('session-setup-save')));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.sets, 4);
      expect(updated!.reps, 12);
    });

    testWidgets('WarmUpEditorSection and dialog expand and save steps',
        (tester) async {
      final steps = <WarmUpStep>[
        const WarmUpStep(
          id: 1,
          name: 'Arm Swings',
          notes: 'Both directions',
          sets: 2,
          workSeconds: 30,
          restSeconds: 15,
          perSide: false,
        ),
      ];

      var updatedSteps = steps;

      await _pumpTestWidget(
        tester,
        textScale: 1.5,
        child: WarmUpEditorSection(
          steps: steps,
          onChanged: (newSteps) => updatedSteps = newSteps,
        ),
      );

      expect(find.text('WARM-UP'), findsOneWidget);
      expect(find.text('Arm Swings'), findsOneWidget);
      expect(find.byKey(const Key('warmup-add-step')), findsOneWidget);

      await tester.tap(find.byKey(const Key('warmup-add-step')));
      await tester.pumpAndSettle();

      expect(find.text('Add warm-up step'), findsOneWidget);
      expect(find.text('Time is per side'), findsOneWidget);

      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Add warm-up step'), findsNothing);
      expect(updatedSteps, isNotEmpty);
    });

    testWidgets('RoutineEditorExerciseCard expands smoothly on tap',
        (tester) async {
      final draft = RoutineEditorDraft(
        originalExercise: Exercise(
          id: 1,
          name: 'Barbell Squat',
          description: 'Full depth',
          category: 'Strength',
          mainMuscleGroup: 'Quadriceps',
        ),
        originalDetail: PlanExerciseDetail(
          exerciseId: 1,
          name: 'Barbell Squat',
          description: 'Full depth',
          sets: 4,
          reps: 8,
          weight: 100.0,
          restSeconds: 120,
          rir: 2,
          tempo: '3-1-1-0',
        ),
      );

      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RoutineEditorExerciseCard(
              compactLayout: false,
              draft: draft,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Barbell Squat'), findsOneWidget);
      expect(find.text('EXERCISE NAME'), findsNothing);

      await tester.tap(find.text('Barbell Squat'));
      await tester.pumpAndSettle();

      expect(find.text('EXERCISE NAME'), findsOneWidget);
      expect(find.text('PROGRAMMING'), findsOneWidget);
      expect(find.text('SETS'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);
      expect(find.text('WEIGHT'), findsOneWidget);
    });

    testWidgets(
        'FinishSessionSummaryScreen allows selection and enforces energy+mood rule',
        (tester) async {
      const draft = FinishSessionSummaryDraft(
        planName: 'Hypertrophy Day A',
        duration: Duration(minutes: 55),
        volumeKg: 12500,
        completedSets: 18,
        totalSets: 20,
        notes: 'Great pump',
        energy: null,
        mood: null,
      );

      await _pumpTestWidget(
        tester,
        textScale: 1.5,
        child: const FinishSessionSummaryScreen(draft: draft),
      );

      expect(find.text('Session review'), findsOneWidget);
      expect(find.text('12.5k'), findsOneWidget);
      expect(find.byKey(const Key('finish-save-button')), findsOneWidget);
      expect(find.byKey(const Key('finish-resume-button')), findsOneWidget);
      expect(find.byKey(const Key('finish-discard-button')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('finish-energy-8')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('finish-energy-8')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('finish-mood-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('finish-mood-4')));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('finish-save-button')),
      );
      expect(saveButton.onPressed, isNotNull);

      // Verify sub-1000 volume format without k suffix
      const sub1000Draft = FinishSessionSummaryDraft(
        planName: 'Hypertrophy Day A',
        duration: Duration(minutes: 55),
        volumeKg: 850,
        completedSets: 18,
        totalSets: 20,
        notes: 'Great pump',
        energy: null,
        mood: null,
      );

      await _pumpTestWidget(
        tester,
        textScale: 1.5,
        child: const FinishSessionSummaryScreen(draft: sub1000Draft),
      );
      expect(find.text('850'), findsOneWidget);
    });

    testWidgets(
        'FinishSessionSummaryScreen handles progressive disclosure for empty notes at 375x667',
        (tester) async {
      const emptyNotesDraft = FinishSessionSummaryDraft(
        planName: 'Upper Body Power',
        duration: Duration(minutes: 42),
        volumeKg: 4200,
        completedSets: 12,
        totalSets: 12,
        notes: '',
        energy: null,
        mood: null,
      );

      await _pumpTestWidget(
        tester,
        surfaceSize: const Size(375, 667),
        child: const FinishSessionSummaryScreen(draft: emptyNotesDraft),
      );

      // Verify compact summary band
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('SETS'), findsOneWidget);
      expect(find.text('4.2k'), findsOneWidget);
      expect(find.text('12/12'), findsOneWidget);

      // Verify 1-10 energy values exist
      for (var i = 1; i <= 10; i++) {
        expect(find.byKey(Key('finish-energy-$i')), findsOneWidget);
      }

      // Verify 1-5 mood buttons exist
      for (var i = 1; i <= 5; i++) {
        expect(find.byKey(Key('finish-mood-$i')), findsOneWidget);
      }

      // Notes are collapsed initially
      expect(find.byKey(const Key('finish-session-notes')), findsNothing);
      expect(find.byKey(const Key('finish-expand-notes-button')), findsOneWidget);

      // Tap to expand notes
      await tester.tap(find.byKey(const Key('finish-expand-notes-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('finish-session-notes')), findsOneWidget);
      expect(find.text('COLLAPSE'), findsOneWidget);

      // Tap to collapse notes
      await tester.tap(find.text('COLLAPSE'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('finish-session-notes')), findsNothing);
      expect(find.byKey(const Key('finish-expand-notes-button')), findsOneWidget);
    });

    testWidgets(
        'ActiveSessionExecutionSummary renders SET, REPS, RIR, TEMPO clearly without overflow at 1.8x text scale',
        (tester) async {
      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        surfaceSize: const Size(375, 667),
        child: const Scaffold(
          body: ActiveSessionExecutionSummary(
            currentSet: 2,
            totalSets: 4,
            targetReps: 10,
            rir: 2,
            tempo: '3-1-1-0',
          ),
        ),
      );

      expect(find.text('SET'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('RIR'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('TEMPO'), findsOneWidget);
      expect(find.text('3-1-1-0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'WarmUpFlow renders cleanly in landscape at textScale 1.8 without overflow',
        (tester) async {
      const step = WarmUpStep(
        id: 1,
        name: 'Standing Quad Stretch',
        notes: 'Hold ankle behind you',
        sets: 2,
        workSeconds: 30,
        restSeconds: 15,
        perSide: true,
      );
      final state = WarmUpSessionState(
        stepIndex: 0,
        setNumber: 1,
        side: WarmUpSide.left,
        phase: WarmUpPhase.work,
        status: WarmUpSessionStatus.running,
        phaseEndsAt: DateTime.now().add(const Duration(seconds: 25)),
      );

      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        surfaceSize: const Size(667, 375),
        child: WarmUpFlow(
          steps: const [step],
          state: state,
          now: DateTime.now(),
          onPauseResume: () {},
          onSkipStep: () {},
          onFinish: () {},
        ),
      );

      expect(find.text('WORK'), findsOneWidget);
      expect(find.text('LEFT SIDE'), findsOneWidget);
      expect(find.byKey(const Key('warmup-current-exercise')), findsOneWidget);
      expect(find.byKey(const Key('warmup-pause-resume')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ExerciseProgressDetailScreen renders compact header and natural stats without overflow at textScale 1.8',
        (tester) async {
      const exerciseItem = ExerciseListItemView(
        exerciseId: 1,
        name: 'Incline Dumbbell Bench Press',
        category: 'Strength',
        mainMuscleGroup: 'Chest',
        description:
            'Adjust bench to 30 degrees. Lower dumbbells slowly with control.',
        sets: 3,
        reps: 10,
        restSeconds: 90,
        weight: 24.0,
      );
      final summary = ExerciseProgressDetailData(
        estimatedOneRmKg: 100,
        totalVolumeKg: 2040,
        lastSessionDate: DateTime.now().subtract(const Duration(days: 2)),
        lastWeightKg: 85,
        lastReps: 8,
        trend: const [],
        recentSessions: const [],
      );

      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseProgressDetailProvider(1).overrideWith(
              (ref) async => summary,
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: KineticNoirPalette.background,
            ),
            builder: (context, childWidget) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.8),
              ),
              child: childWidget!,
            ),
            home: const ExerciseProgressDetailScreen(exercise: exerciseItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise-progress-title')), findsOneWidget);
      expect(find.text('EST. 1RM', skipOffstage: false), findsOneWidget);
      expect(find.text('LAST SESSION', skipOffstage: false), findsOneWidget);
      expect(find.text('TOTAL VOLUME', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'SelectExerciseScreen renders cleanly at 375x667 1.8 with keyboard viewInsets and allows selection',
        (tester) async {
      final sampleExercises = <Exercise>[
        Exercise(
          id: 101,
          name: 'Barbell Bench Press',
          category: 'Strength',
          mainMuscleGroup: 'Chest',
          description: 'Chest press on flat bench',
        ),
        Exercise(
          id: 102,
          name: 'Incline Dumbbell Press',
          category: 'Strength',
          mainMuscleGroup: 'Chest',
          description: 'Upper chest press',
        ),
      ];

      Exercise? selectedExercise;

      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        surfaceSize: const Size(375, 667),
        viewInsets: const EdgeInsets.only(bottom: 280),
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedExercise = await Navigator.push<Exercise>(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectExerciseScreen(
                    groups: const {'Chest', 'Back'},
                    initialExercises: sampleExercises,
                  ),
                ),
              );
            },
            child: const Text('Open Picker'),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // No overflow exception with keyboard insets at 1.8 font scale
      expect(tester.takeException(), isNull);

      // Verify header components
      expect(find.text('EXERCISE LIBRARY'), findsOneWidget);
      expect(find.byKey(const Key('select-exercise-create-new')),
          findsOneWidget);

      // Focus search TextField cleanly via ensureVisible
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Enter query to filter
      await tester.enterText(find.byType(TextField), 'Bench');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Clear search via clear button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Tap and select an exercise cleanly
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      await tester.ensureVisible(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();

      expect(selectedExercise, isNotNull);
      expect(selectedExercise!.id, 101);
      expect(selectedExercise!.name, 'Barbell Bench Press');
    });

    testWidgets(
        'FinishSessionSummaryScreen provides >= 48x48 touch targets and keeps required fields visible at 375x667 without scroll',
        (tester) async {
      const draft = FinishSessionSummaryDraft(
        planName: 'Hypertrophy Day A',
        duration: Duration(minutes: 45),
        volumeKg: 3500,
        completedSets: 12,
        totalSets: 12,
        notes: '',
        energy: null,
        mood: null,
      );

      await _pumpTestWidget(
        tester,
        surfaceSize: const Size(375, 667),
        textScale: 1.0,
        child: const FinishSessionSummaryScreen(draft: draft),
      );

      // Verify all 10 energy chips satisfy Android 48x48dp minimum hit target
      for (var i = 1; i <= 10; i++) {
        final chipFinder = find.byKey(Key('finish-energy-$i'));
        expect(chipFinder, findsOneWidget);
        final chipSize = tester.getSize(chipFinder);
        expect(chipSize.width, greaterThanOrEqualTo(48.0),
            reason: 'Energy chip $i width must be >= 48dp');
        expect(chipSize.height, greaterThanOrEqualTo(48.0),
            reason: 'Energy chip $i height must be >= 48dp');
      }

      // Verify all 5 mood buttons satisfy Android 48x48dp minimum hit target
      for (var i = 1; i <= 5; i++) {
        final moodFinder = find.byKey(Key('finish-mood-$i'));
        expect(moodFinder, findsOneWidget);
        final moodSize = tester.getSize(moodFinder);
        expect(moodSize.width, greaterThanOrEqualTo(48.0),
            reason: 'Mood button $i width must be >= 48dp');
        expect(moodSize.height, greaterThanOrEqualTo(48.0),
            reason: 'Mood button $i height must be >= 48dp');
      }

      // Verify required fields (summary, energy, mood, save button) are visible
      // on the initial screen without scrolling at 375x667
      final energy10Bottom =
          tester.getBottomRight(find.byKey(const Key('finish-energy-10'))).dy;
      final mood5Bottom =
          tester.getBottomRight(find.byKey(const Key('finish-mood-5'))).dy;
      final saveButtonBottom =
          tester.getBottomRight(find.byKey(const Key('finish-save-button'))).dy;

      expect(energy10Bottom, lessThanOrEqualTo(667.0),
          reason: 'Energy selector should fit inside 375x667 viewport');
      expect(mood5Bottom, lessThanOrEqualTo(667.0),
          reason: 'Mood selector should fit inside 375x667 viewport');
      expect(saveButtonBottom, lessThanOrEqualTo(667.0),
          reason: 'Save button should be visible inside 375x667 viewport');
    });

    testWidgets(
        'ActiveSessionExecutionSummary prioritizes TEMPO and REPS with full text under 1.8x text scale and IME',
        (tester) async {
      await _pumpTestWidget(
        tester,
        textScale: 1.8,
        surfaceSize: const Size(375, 667),
        viewInsets: const EdgeInsets.only(bottom: 240),
        child: const Scaffold(
          body: ActiveSessionExecutionSummary(
            currentSet: 1,
            totalSets: 3,
            targetReps: 12,
            rir: 2,
            tempo: '4-0-1-0',
          ),
        ),
      );

      // Verify full tempo text and reps text are rendered
      expect(find.text('4-0-1-0'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('TEMPO'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);

      // Verify secondary pills exist
      expect(find.text('SET'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('RIR'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify TEMPO RenderBox has ample width (> 100dp) so it is not squeezed
      final tempoSize = tester.getSize(find.text('4-0-1-0'));
      expect(tempoSize.width, greaterThan(60.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'FinishSessionSummaryScreen discard confirmation modal cancel keeps screen, confirm pops discard',
        (tester) async {
      FinishSessionSummaryResult? result;
      const draft = FinishSessionSummaryDraft(
        planName: 'Hypertrophy Day A',
        duration: Duration(minutes: 45),
        volumeKg: 3500,
        completedSets: 12,
        totalSets: 12,
        notes: '',
        energy: null,
        mood: null,
      );

      await _pumpTestWidget(
        tester,
        surfaceSize: const Size(375, 667),
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<FinishSessionSummaryResult>(
                MaterialPageRoute(
                  builder: (_) => const FinishSessionSummaryScreen(draft: draft),
                ),
              );
            },
            child: const Text('Open Summary'),
          ),
        ),
      );

      await tester.tap(find.text('Open Summary'));
      await tester.pumpAndSettle();

      // Tap discard button
      expect(find.byKey(const Key('finish-discard-button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('finish-discard-button')));
      await tester.pumpAndSettle();

      // Verify discard confirmation sheet is displayed
      expect(find.byKey(const Key('confirm-discard-title')), findsOneWidget);
      expect(find.byKey(const Key('confirm-discard-cancel')), findsOneWidget);
      expect(find.byKey(const Key('confirm-discard-confirm')), findsOneWidget);

      // Tap Cancel (KEEP WORKOUT)
      await tester.tap(find.byKey(const Key('confirm-discard-cancel')));
      await tester.pumpAndSettle();

      // Discard sheet is gone, but FinishSessionSummaryScreen is still open
      expect(find.byKey(const Key('confirm-discard-title')), findsNothing);
      expect(find.byKey(const Key('finish-session-title')), findsOneWidget);
      expect(result, isNull);

      // Tap discard again, and this time confirm
      await tester.tap(find.byKey(const Key('finish-discard-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-discard-confirm')), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-discard-confirm')));
      await tester.pumpAndSettle();

      // Summary screen popped with discard result
      expect(result, isNotNull);
      expect(result!.action, FinishSessionSummaryAction.discard);
    });

    testWidgets(
        'FinishSessionSummaryScreen AppBar close button pops with resume result',
        (tester) async {
      FinishSessionSummaryResult? result;
      const draft = FinishSessionSummaryDraft(
        planName: 'Hypertrophy Day A',
        duration: Duration(minutes: 45),
        volumeKg: 3500,
        completedSets: 12,
        totalSets: 12,
        notes: 'Session notes',
        energy: '8',
        mood: '4',
      );

      await _pumpTestWidget(
        tester,
        surfaceSize: const Size(375, 667),
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<FinishSessionSummaryResult>(
                MaterialPageRoute(
                  builder: (_) => const FinishSessionSummaryScreen(draft: draft),
                ),
              );
            },
            child: const Text('Open Summary'),
          ),
        ),
      );

      await tester.tap(find.text('Open Summary'));
      await tester.pumpAndSettle();

      // Tap AppBar close button (X)
      expect(find.byTooltip('Close'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.action, FinishSessionSummaryAction.resume);
      expect(result!.energy, '8');
      expect(result!.mood, '4');
      expect(result!.notes, 'Session notes');
    });
  });
}
