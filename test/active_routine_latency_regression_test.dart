import 'package:fit_log/src/data/providers/workout_storage_service_provider.dart';
import 'package:fit_log/src/data/services/workout_storage_service.dart';
import 'package:fit_log/src/features/routines/domain/entities/active_session_exercise_setup_preset.dart';
import 'package:fit_log/src/features/routines/domain/entities/active_workout_session_draft.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/plan_exercise_detail.dart';
import 'package:fit_log/src/features/routines/domain/entities/warm_up_step.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_plan.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_session.dart';
import 'package:fit_log/src/features/routines/domain/repositories/workout_plan_repository.dart';
import 'package:fit_log/src/features/routines/presentation/pages/start_routine_screen.dart';
import 'package:fit_log/src/features/routines/presentation/providers/workout_plan_repository_provider.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/active_session_exercise_card.dart';
import 'package:fit_log/src/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vibration_platform_interface/vibration_platform_interface.dart';

const _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');
final List<MethodCall> _notificationCalls = <MethodCall>[];
final _fakeVibrationPlatform = _TestVibrationPlatform();
late VibrationPlatform _originalVibrationPlatform;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _originalVibrationPlatform = VibrationPlatform.instance;
  });

  setUp(() async {
    _notificationCalls.clear();
    _fakeVibrationPlatform.reset();
    VibrationPlatform.instance = _fakeVibrationPlatform;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    _setUpNotificationsChannel();
    await NotificationService.init();
    _notificationCalls.clear();
  });

  tearDownAll(() {
    VibrationPlatform.instance = _originalVibrationPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
  });

  testWidgets(
      'foco, drafts, insets y ticks preservan estado sin reiniciar tarjeta ni teclado',
      (tester) async {
    var currentTime = DateTime.now().add(const Duration(minutes: 5));
    final repo = _TestWorkoutPlanRepository();
    final insetValueNotifier = ValueNotifier<EdgeInsets>(EdgeInsets.zero);

    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutPlanRepositoryProvider.overrideWithValue(repo),
          workoutStorageServiceProvider.overrideWithValue(
            _TestWorkoutStorageService(),
          ),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<EdgeInsets>(
            valueListenable: insetValueNotifier,
            builder: (context, insets, _) => MediaQuery(
              data: const MediaQueryData(size: Size(430, 1000))
                  .copyWith(viewInsets: insets),
              child: StartRoutineScreen(
                plan: WorkoutPlan(id: 1, name: 'Upper A', frequency: 'Mon / Thu'),
                now: () => currentTime,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 1. Initial State: Barbell Bench Press visible, initial session time is 00:00
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.textContaining('00:00'), findsOneWidget);

    // Get initial state of the card
    final cardStateBefore = tester.state<ActiveSessionExerciseCardState>(
      find.byType(ActiveSessionExerciseCard).first,
    );

    // 2. FOCO: Tap on the KG input of set 1
    final kgFieldFinder = find.byKey(const Key('active-set-1-1-kg'));
    expect(kgFieldFinder, findsOneWidget);
    await tester.tap(kgFieldFinder);
    await tester.pump();

    final textField = tester.widget<TextField>(kgFieldFinder);
    expect(textField.focusNode?.hasFocus, isTrue);

    // 3. DRAFT: Enter new weight and reps
    await tester.enterText(kgFieldFinder, '85');
    await tester.pump();
    final repsFieldFinder = find.byKey(const Key('active-set-1-1-reps'));
    await tester.enterText(repsFieldFinder, '6');
    await tester.pump();

    // Allow 300ms draft persistence debounce to complete
    await tester.pump(const Duration(milliseconds: 350));
    expect(repo.activeSessionDraft, isNotNull);
    final draftLog = repo.activeSessionDraft!.logs
        .singleWhere((log) => log.exerciseId == 1 && log.setNumber == 1);
    expect(draftLog.weight, 85);
    expect(draftLog.reps, 6);

    // 4. INSETS: Simulate keyboard opening by animating viewInsets.bottom to 320
    insetValueNotifier.value = const EdgeInsets.only(bottom: 320);
    await tester.pump();

    // Verify LOG SET button stays immediately above the keyboard
    final buttonRect = tester.getRect(
      find.byKey(const Key('active-session-register-set')),
    );
    expect(buttonRect.bottom, lessThanOrEqualTo(1000 - 320));
    expect(buttonRect.bottom, greaterThan(1000 - 320 - 56));

    // Verify the card was NOT destroyed or recreated during inset update
    final cardStateDuringKeyboard = tester.state<ActiveSessionExerciseCardState>(
      find.byType(ActiveSessionExerciseCard).first,
    );
    expect(identical(cardStateBefore, cardStateDuringKeyboard), isTrue);

    // 5. TICK: Advance time by 5 seconds (simulating 1-second ticks)
    currentTime = currentTime.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    // Verify session timer updated to 00:05 in the AppBar
    expect(find.textContaining('00:05'), findsOneWidget);

    // Verify card state and input values remain completely stable and intact
    final cardStateAfterTicks = tester.state<ActiveSessionExerciseCardState>(
      find.byType(ActiveSessionExerciseCard).first,
    );
    expect(identical(cardStateBefore, cardStateAfterTicks), isTrue);
    final kgFieldAfterTicks = tester.widget<TextField>(kgFieldFinder);
    expect(kgFieldAfterTicks.controller?.text, '85');

    // 6. LOG SET: Tap register set to complete set 1
    await tester.tap(find.byKey(const Key('active-session-register-set')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify set 1 was completed and rest timer started
    expect(repo.activeSessionDraft, isNotNull);
    final completedLog = repo.activeSessionDraft!.logs
        .singleWhere((log) => log.exerciseId == 1 && log.setNumber == 1);
    expect(completedLog.completed, isTrue);
  });
}

void _setUpNotificationsChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_notificationsChannel, (call) async {
    _notificationCalls.add(call);
    switch (call.method) {
      case 'initialize':
        return true;
      case 'getNotificationAppLaunchDetails':
        return null;
      case 'cancel':
      case 'zonedSchedule':
      default:
        return null;
    }
  });
}

class _TestVibrationPlatform extends VibrationPlatform {
  bool hasCustomVibrations = true;
  final List<dynamic> calls = [];

  void reset() => calls.clear();

  @override
  Future<bool> hasVibrator() async => true;

  @override
  Future<bool> hasAmplitudeControl() async => false;

  @override
  Future<bool> hasCustomVibrationsSupport() async => hasCustomVibrations;

  @override
  Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
  }) async {
    calls.add('vibrate');
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
  }
}

class _TestWorkoutStorageService extends WorkoutStorageService {
  @override
  Future<List<WorkoutLogEntry>> fetchWorkoutLogs({
    int? exerciseId,
    List<int>? exerciseIds,
    List<int>? planIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async =>
      const [];
}

class _TestWorkoutPlanRepository implements WorkoutPlanRepository {
  ActiveWorkoutSessionDraft? activeSessionDraft;
  final Map<int, ActiveSessionExerciseSetupPreset> activeSessionSetupPresets = {};

  final List<Exercise> _exercises = [
    Exercise(
      id: 1,
      name: 'Barbell Bench Press',
      description: 'Flat bench barbell press',
      category: 'Chest',
      mainMuscleGroup: 'Chest',
    ),
    Exercise(
      id: 2,
      name: 'Incline Dumbbell Press',
      description: 'Incline press with dumbbells',
      category: 'Chest',
      mainMuscleGroup: 'Chest',
    ),
  ];

  final Map<int, List<PlanExerciseDetail>> _details = {
    1: [
      PlanExerciseDetail(
        exerciseId: 1,
        name: 'Barbell Bench Press',
        description: 'Flat bench barbell press',
        sets: 3,
        reps: 8,
        weight: 80,
        restSeconds: 90,
        rir: 2,
        tempo: '3-1-1-0',
      ),
      PlanExerciseDetail(
        exerciseId: 2,
        name: 'Incline Dumbbell Press',
        description: 'Incline press with dumbbells',
        sets: 3,
        reps: 10,
        weight: 24,
        restSeconds: 90,
        rir: 2,
        tempo: '3-0-1-0',
      ),
    ],
  };

  @override
  Future<void> addExerciseToPlan(
    int planId,
    PlanExerciseDetail detail, {
    int? position,
  }) async {}

  @override
  Future<void> deleteExerciseFromPlan(int planId, int exerciseId) async {}

  @override
  Future<List<Exercise>> getAllExercises() async => _exercises;

  @override
  Future<List<WorkoutPlan>> getAllPlans() async => const [];

  @override
  Future<void> createWorkoutPlan(String name, String frequency) async {}

  @override
  Future<void> createExercise(
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) async {}

  @override
  Future<List<Exercise>> getExercisesForPlan(int planId) async => _exercises;

  @override
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId) async =>
      _details[planId] ?? const [];

  @override
  Future<List<WarmUpStep>> getWarmUpSteps(int planId) async => const [];

  @override
  Future<void> replaceWarmUpSteps(int planId, List<WarmUpStep> steps) async {}

  @override
  Future<List<Exercise>> getSimilarExercises(int exerciseId) async => const [];

  @override
  Future<ActiveSessionExerciseSetupPreset?> getActiveSessionExerciseSetupPreset(
    int exerciseId,
  ) async =>
      activeSessionSetupPresets[exerciseId];

  @override
  Future<void> saveActiveSessionExerciseSetupPreset(
    ActiveSessionExerciseSetupPreset preset,
  ) async {
    activeSessionSetupPresets[preset.exerciseId] = preset;
  }

  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {}

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {}

  @override
  Future<ActiveWorkoutSessionDraft?> getActiveSessionDraft() async =>
      activeSessionDraft;

  @override
  Future<void> saveActiveSessionDraft(ActiveWorkoutSessionDraft draft) async {
    activeSessionDraft = draft;
  }

  @override
  Future<void> clearActiveSessionDraft() async {
    activeSessionDraft = null;
  }

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
    int planId,
    PlanExerciseDetail detail,
  ) async {}

  @override
  Future<void> updateWorkoutPlan(
    int planId,
    String name,
    String frequency,
  ) async {}
}
