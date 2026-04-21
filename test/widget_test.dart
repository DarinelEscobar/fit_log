import 'package:fit_log/src/app.dart';
import 'package:fit_log/src/features/routines/domain/entities/exercise.dart';
import 'package:fit_log/src/features/routines/domain/entities/plan_exercise_detail.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_plan.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_session.dart';
import 'package:fit_log/src/features/routines/domain/repositories/workout_plan_repository.dart';
import 'package:fit_log/src/features/routines/presentation/pages/start_routine_screen.dart';
import 'package:fit_log/src/features/routines/presentation/providers/workout_plan_repository_provider.dart';
import 'package:fit_log/src/features/routines/presentation/widgets/active_session_exercise_card.dart';
import 'package:fit_log/src/utils/notification_service.dart';
import 'package:fit_log/src/navigation/widgets/kinetic_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibration/vibration_presets.dart';
import 'package:vibration_platform_interface/vibration_platform_interface.dart';

const _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');
final List<MethodCall> _notificationCalls = <MethodCall>[];
final _fakeVibrationPlatform = _FakeVibrationPlatform();
late VibrationPlatform _originalVibrationPlatform;

void main() {
  setUpAll(() {
    _originalVibrationPlatform = VibrationPlatform.instance;
  });

  setUp(() async {
    _notificationCalls.clear();
    _fakeVibrationPlatform.reset();
    VibrationPlatform.instance = _fakeVibrationPlatform;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    _setUpRoutineChannels();
    await NotificationService.init();
    _notificationCalls.clear();
  });

  tearDownAll(() {
    VibrationPlatform.instance = _originalVibrationPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
  });

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

  testWidgets('active workout session shows the redesigned shell', (
    tester,
  ) async {
    await _pumpStartRoutine(tester);

    expect(find.byKey(const Key('active-session-title')), findsOneWidget);
    expect(
        find.byKey(const Key('active-session-register-set')), findsOneWidget);
    expect(
        find.byKey(const Key('active-session-notes-toggle')), findsOneWidget);
    expect(find.byKey(const Key('active-session-notes')), findsNothing);
    expect(find.text('TEMPO'), findsOneWidget);
    expect(find.text('3-1-1-0'), findsOneWidget);
    expect(find.byType(KineticBottomNavBar), findsNothing);
    expect(find.text('DONE'), findsNothing);
    expect(find.textContaining('sets programmed'), findsNothing);
    expect(find.textContaining('LBS'), findsNothing);
    expect(find.textContaining('LOG HISTORY'), findsNothing);
    expect(find.text('ACTIVE WORKOUT'), findsNothing);
    expect(find.text('Current Session'), findsNothing);
  });

  testWidgets('numeric workout inputs select all current text on tap', (
    tester,
  ) async {
    await _pumpStartRoutine(tester);

    await _openNotesComposer(tester);
    final inputFinder = find.byKey(const Key('active-set-1-1-kg'));
    await tester.tap(inputFinder);
    await tester.pump();

    final editableFinder = find.descendant(
      of: inputFinder,
      matching: find.byType(EditableText),
    );
    final editableState = tester.state<EditableTextState>(editableFinder);

    expect(editableState.textEditingValue.selection.baseOffset, 0);
    expect(
      editableState.textEditingValue.selection.extentOffset,
      editableState.textEditingValue.text.length,
    );
  });

  testWidgets('add and remove set update the visible set rows', (tester) async {
    await _pumpStartRoutine(tester);

    expect(find.byKey(const Key('active-set-row-1-5')), findsNothing);

    await tester.tap(find.byKey(const Key('active-set-options-toggle-1')));
    await tester.pump();
    await _scrollUntilVisible(
        tester, find.byKey(const Key('active-set-add-1')));
    await tester.tap(find.byKey(const Key('active-set-add-1')));
    await tester.pump();

    expect(find.byKey(const Key('active-set-row-1-5')), findsOneWidget);

    await _scrollUntilVisible(
      tester,
      find.byKey(const Key('active-set-remove-1')),
    );
    await tester.tap(find.byKey(const Key('active-set-remove-1')));
    await tester.pump();

    expect(find.byKey(const Key('active-set-row-1-5')), findsNothing);
  });

  testWidgets(
      'rest timer schedules a stable notification id and strong completion vibration',
      (tester) async {
    var currentNow = DateTime.now().add(const Duration(minutes: 5));
    await _pumpStartRoutine(
      tester,
      now: () => currentNow,
    );

    await _completeFirstSet(tester);

    const scheduledNotificationId = 1001;
    final scheduleCall = _notificationCalls.singleWhere(
      (call) => call.method == 'zonedSchedule',
    );
    final cancelCalls = _notificationCalls
        .where((call) => call.method == 'cancel')
        .toList(growable: false);
    final cancelIds = cancelCalls
        .map((call) => (call.arguments as Map<dynamic, dynamic>)['id'] as int)
        .toList(growable: false);
    final scheduleArguments = scheduleCall.arguments as Map<dynamic, dynamic>;
    final platformSpecifics =
        scheduleArguments['platformSpecifics'] as Map<dynamic, dynamic>;
    final vibrationPattern =
        (platformSpecifics['vibrationPattern'] as List<dynamic>)
            .cast<int>()
            .toList(growable: false);

    expect(cancelIds, contains(scheduledNotificationId));
    expect(scheduleArguments['id'], scheduledNotificationId);
    expect(platformSpecifics['channelId'], 'rest_timer_v3_alarm');
    expect(platformSpecifics['scheduleMode'], 'exactAllowWhileIdle');
    expect(platformSpecifics['importance'], Importance.max.value);
    expect(platformSpecifics['priority'], Priority.high.value);
    expect(platformSpecifics['playSound'], isTrue);
    expect(platformSpecifics['enableVibration'], isTrue);
    expect(
      platformSpecifics['visibility'],
      NotificationVisibility.public.index,
    );
    expect(
      platformSpecifics['category'],
      AndroidNotificationCategory.alarm.name,
    );
    expect(
      platformSpecifics['audioAttributesUsage'],
      AudioAttributesUsage.alarm.value,
    );
    expect(vibrationPattern, [0, 1200, 250, 1200, 250, 1800]);

    expect(find.textContaining('Rest timer running'), findsOneWidget);

    currentNow = currentNow.add(const Duration(seconds: 91));
    final cardState = tester.state<ActiveSessionExerciseCardState>(
      find.byType(ActiveSessionExerciseCard).first,
    );
    await cardState.syncRestTimer(
      currentNow,
      vibrateOnCompletion: true,
    );
    await tester.pump();

    expect(find.textContaining('Rest timer running'), findsNothing);
    expect(cardState.restRemainingSeconds, 0);
    expect(_notificationCalls.where((call) => call.method == 'cancel'),
        hasLength(2));
    expect(_fakeVibrationPlatform.vibrateCalls, hasLength(1));
    expect(
      _fakeVibrationPlatform.vibrateCalls.single.pattern,
      presets[VibrationPreset.countdownTimerAlert]!.pattern,
    );
    expect(
      _fakeVibrationPlatform.vibrateCalls.single.intensities,
      presets[VibrationPreset.countdownTimerAlert]!.intensities,
    );
  });

  testWidgets(
      'resuming after background clears an expired rest timer without relying on the ticker',
      (tester) async {
    var currentNow = DateTime.now().add(const Duration(minutes: 5));
    await _pumpStartRoutine(
      tester,
      now: () => currentNow,
    );

    await _completeFirstSet(tester);
    expect(find.textContaining('Rest timer running'), findsOneWidget);

    currentNow = currentNow.add(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    final cardState = tester.state<ActiveSessionExerciseCardState>(
      find.byType(ActiveSessionExerciseCard).first,
    );

    expect(find.textContaining('Rest timer running'), findsNothing);
    expect(cardState.restRemainingSeconds, 0);
    final cancelIds = _notificationCalls
        .where((call) => call.method == 'cancel')
        .map((call) => (call.arguments as Map<dynamic, dynamic>)['id'] as int)
        .toList(growable: false);

    expect(cancelIds, contains(1001));
    expect(_fakeVibrationPlatform.vibrateCalls, isEmpty);
  });

  testWidgets('finish summary resumes with edited notes applied back', (
    tester,
  ) async {
    await _pumpStartRoutine(tester);

    await _openNotesComposer(tester);
    await tester.enterText(
      find.byKey(const Key('active-session-notes')),
      'Real session note',
    );
    await tester.pump();

    await _completeFirstSet(tester);

    await tester.tap(find.byKey(const Key('active-session-finish')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finish-session-title')), findsOneWidget);
    expect(find.byType(KineticBottomNavBar), findsNothing);
    expect(find.text('Real session note'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('finish-session-notes')),
      'Edited from summary',
    );
    await tester.pump();

    await _scrollUntilVisible(
      tester,
      find.byKey(const Key('finish-resume-button')),
    );
    await tester.tap(find.byKey(const Key('finish-resume-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-session-title')), findsOneWidget);
    expect(find.text('Edited from summary'), findsOneWidget);
  });

  testWidgets('finish summary discard keeps active-session notes unchanged', (
    tester,
  ) async {
    await _pumpStartRoutine(tester);

    await _openNotesComposer(tester);
    await tester.enterText(
      find.byKey(const Key('active-session-notes')),
      'Original active note',
    );
    await tester.pump();

    await _completeFirstSet(tester);

    await tester.tap(find.byKey(const Key('active-session-finish')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('finish-session-notes')),
      'Changed only in summary',
    );
    await tester.pump();

    await _scrollUntilVisible(
      tester,
      find.byKey(const Key('finish-discard-button')),
    );
    await tester.tap(find.byKey(const Key('finish-discard-button')));
    await tester.pumpAndSettle();

    expect(find.text('Original active note'), findsOneWidget);
    expect(find.text('Changed only in summary'), findsNothing);
  });

  testWidgets('save and finish persists logs and summary values', (
    tester,
  ) async {
    final repo = _FakeWorkoutPlanRepository();
    var currentNow = DateTime.now().add(const Duration(minutes: 5));
    await _pumpStartRoutine(
      tester,
      repo: repo,
      now: () => currentNow,
    );

    await _openNotesComposer(tester);
    await tester.enterText(
      find.byKey(const Key('active-session-notes')),
      'Initial active note',
    );
    await tester.pump();

    await _completeFirstSet(tester);

    currentNow = currentNow.add(const Duration(minutes: 2));

    await tester.tap(find.byKey(const Key('active-session-finish')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('finish-session-notes')),
      'Saved from summary',
    );
    await _scrollUntilVisible(tester, find.byKey(const Key('finish-energy-8')));
    await tester.tap(find.byKey(const Key('finish-energy-8')));
    await tester.pump();
    await _scrollUntilVisible(tester, find.byKey(const Key('finish-mood-4')));
    await tester.tap(find.byKey(const Key('finish-mood-4')));
    await tester.pump();
    await _scrollUntilVisible(
        tester, find.byKey(const Key('finish-save-button')));
    await tester.tap(find.byKey(const Key('finish-save-button')));
    await tester.pumpAndSettle();

    expect(repo.savedLogs, isNotEmpty);
    expect(repo.savedSessions, hasLength(1));
    expect(repo.savedSessions.single.notes, 'Saved from summary');
    expect(repo.savedSessions.single.fatigueLevel, '8');
    expect(repo.savedSessions.single.mood, '4');
    expect(repo.savedSessions.single.durationMinutes, 2);
  });

  testWidgets('system back opens exit confirmation and stay keeps session open',
      (tester) async {
    await _pumpStartRoutineInHost(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirm-exit-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-exit-stay')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-session-title')), findsOneWidget);
    expect(find.byKey(const Key('routine-host-open')), findsNothing);
  });

  testWidgets('close button uses same modal and exit leaves active session',
      (tester) async {
    await _pumpStartRoutineInHost(tester);

    await tester.tap(find.byKey(const Key('active-session-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirm-exit-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-exit-exit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-session-title')), findsNothing);
    expect(find.byKey(const Key('routine-host-open')), findsOneWidget);
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

Future<void> _pumpStartRoutine(
  WidgetTester tester, {
  _FakeWorkoutPlanRepository? repo,
  DateTime Function()? now,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  _setUpRoutineChannels();
  final effectiveRepo = repo ?? _FakeWorkoutPlanRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutPlanRepositoryProvider.overrideWithValue(effectiveRepo),
      ],
      child: MaterialApp(
        home: StartRoutineScreen(
          plan: WorkoutPlan(id: 1, name: 'Upper A', frequency: 'Mon / Thu'),
          now: now ?? DateTime.now,
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  final messengerState =
      tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
  messengerState.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
  await tester.pump();
}

Future<void> _pumpStartRoutineInHost(
  WidgetTester tester, {
  _FakeWorkoutPlanRepository? repo,
  DateTime Function()? now,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  _setUpRoutineChannels();
  final effectiveRepo = repo ?? _FakeWorkoutPlanRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutPlanRepositoryProvider.overrideWithValue(effectiveRepo),
      ],
      child: MaterialApp(
        home: _RoutineHost(now: now ?? DateTime.now),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('routine-host-open')));
  await tester.pumpAndSettle();

  final messengerState =
      tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
  messengerState.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
  await tester.pump();
}

class _FakeVibrationPlatform extends VibrationPlatform {
  final List<_VibrationCall> vibrateCalls = <_VibrationCall>[];
  int hasVibratorCalls = 0;

  void reset() {
    vibrateCalls.clear();
    hasVibratorCalls = 0;
  }

  @override
  Future<bool> hasVibrator() async {
    hasVibratorCalls++;
    return true;
  }

  @override
  Future<bool> hasAmplitudeControl() async => false;

  @override
  Future<bool> hasCustomVibrationsSupport() async => true;

  @override
  Future<void> vibrate({
    int duration = 500,
    List<int> pattern = const [],
    int repeat = -1,
    List<int> intensities = const [],
    int amplitude = -1,
    double sharpness = 0.5,
  }) async {
    vibrateCalls.add(
      _VibrationCall(
        duration: duration,
        pattern: List<int>.from(pattern),
        repeat: repeat,
        intensities: List<int>.from(intensities),
        amplitude: amplitude,
        sharpness: sharpness,
      ),
    );
  }

  @override
  Future<void> cancel() async {}
}

class _VibrationCall {
  const _VibrationCall({
    required this.duration,
    required this.pattern,
    required this.repeat,
    required this.intensities,
    required this.amplitude,
    required this.sharpness,
  });

  final int duration;
  final List<int> pattern;
  final int repeat;
  final List<int> intensities;
  final int amplitude;
  final double sharpness;
}

void _setUpRoutineChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_notificationsChannel, (call) async {
    _notificationCalls.add(call);
    switch (call.method) {
      case 'initialize':
      case 'requestNotificationsPermission':
      case 'requestExactAlarmsPermission':
      case 'requestPermissions':
      case 'requestFullScreenIntentPermission':
      case 'requestNotificationPolicyAccess':
        return true;
      default:
        return null;
    }
  });
}

Future<void> _completeFirstSet(WidgetTester tester) async {
  final firstCardState = tester.state<ActiveSessionExerciseCardState>(
    find.byType(ActiveSessionExerciseCard).first,
  );

  expect(firstCardState.logCurrentSet(), isTrue);
  await tester.pump();
}

Future<void> _openNotesComposer(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('active-session-notes-toggle')));
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pump();
}

class _RoutineHost extends StatelessWidget {
  const _RoutineHost({
    this.now = DateTime.now,
  });

  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('routine-host-open'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StartRoutineScreen(
                plan:
                    WorkoutPlan(id: 1, name: 'Upper A', frequency: 'Mon / Thu'),
                now: now,
              ),
            ),
          ),
          child: const Text('OPEN ROUTINE'),
        ),
      ),
    );
  }
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
  final List<WorkoutLogEntry> savedLogs = [];
  final List<WorkoutSession> savedSessions = [];

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
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {
    savedLogs
      ..clear()
      ..addAll(logs);
  }

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    savedSessions.add(session);
  }

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
