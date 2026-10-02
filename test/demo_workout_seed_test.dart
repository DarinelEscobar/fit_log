import 'dart:io';

import 'package:fit_log/src/data/fixtures/demo_workout_seed.dart';
import 'package:fit_log/src/data/services/workout_storage_service.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late Directory documentsDirectory;
  late Directory databaseDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('fitlog_demo_seed_test_');
    documentsDirectory = Directory(p.join(tempRoot.path, 'documents'));
    databaseDirectory = Directory(p.join(tempRoot.path, 'databases'));
    await documentsDirectory.create(recursive: true);
    await databaseDirectory.create(recursive: true);
    await databaseFactory.setDatabasesPath(databaseDirectory.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
          return documentsDirectory.path;
        case 'getTemporaryDirectory':
          return tempRoot.path;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test(
    'first run creates routines, exercise details, warm-ups, and history; second run does not duplicate',
    () async {
      final fixedNow = DateTime(2026, 10, 1, 10, 0, 0);
      final service = WorkoutStorageService(dbFactory: databaseFactoryFfi);

      // First run on clean database
      final firstResult = await seedDemoWorkoutDataIfNeeded(
        service,
        referenceDate: fixedNow,
      );
      expect(firstResult, isTrue);

      // Verify two routines (Upper body / Lower body)
      final plans = await service.fetchWorkoutPlans();
      expect(plans.length, 2);
      final planNames = plans.map((p) => p.name).toSet();
      expect(planNames, containsAll(['Upper Body', 'Lower Body']));

      final upperPlan = plans.firstWhere((p) => p.name == 'Upper Body');
      final lowerPlan = plans.firstWhere((p) => p.name == 'Lower Body');

      // Verify Upper Body exercise details (3 sets x 8-12 reps, RIR 2, tempo 3-1-1, rest 60s)
      final upperDetails = await service.fetchPlanExerciseDetails(upperPlan.id);
      expect(upperDetails.length, 3);
      for (final detail in upperDetails) {
        expect(detail.sets, 3);
        expect(detail.reps >= 8 && detail.reps <= 12, isTrue);
        expect(detail.rir, 2);
        expect(detail.tempo, '3-1-1');
        expect(detail.restSeconds, 60);
      }

      // Verify Lower Body exercise details (3 sets x 8-12 reps, RIR 2, tempo 3-1-1, rest 60s)
      final lowerDetails = await service.fetchPlanExerciseDetails(lowerPlan.id);
      expect(lowerDetails.length, 3);
      for (final detail in lowerDetails) {
        expect(detail.sets, 3);
        expect(detail.reps >= 8 && detail.reps <= 12, isTrue);
        expect(detail.rir, 2);
        expect(detail.tempo, '3-1-1');
        expect(detail.restSeconds, 60);
      }

      // Verify short 2-step warmups
      final upperWarmup = await service.fetchWarmUpSteps(upperPlan.id);
      expect(upperWarmup.length, 2);

      final lowerWarmup = await service.fetchWarmUpSteps(lowerPlan.id);
      expect(lowerWarmup.length, 2);

      // Verify history sessions (4-6 sessions across last 2 weeks)
      final sessions = await service.fetchAllSessions();
      expect(sessions.length >= 4 && sessions.length <= 6, isTrue);
      expect(sessions.length, 5);

      // Verify history logs
      final logs = await service.fetchAllLogs();
      expect(logs.length, 45);

      await service.close();

      // Second run: must be idempotent, return false, and not duplicate data
      final secondService =
          WorkoutStorageService(dbFactory: databaseFactoryFfi);
      final secondResult = await seedDemoWorkoutDataIfNeeded(
        secondService,
        referenceDate: fixedNow,
      );
      expect(secondResult, isFalse);

      final plansAfterSecond = await secondService.fetchWorkoutPlans();
      expect(plansAfterSecond.length, 2);

      final sessionsAfterSecond = await secondService.fetchAllSessions();
      expect(sessionsAfterSecond.length, 5);

      final logsAfterSecond = await secondService.fetchAllLogs();
      expect(logsAfterSecond.length, 45);

      await secondService.close();
    },
  );

  test(
    'does not modify database and returns false when a workout plan already exists',
    () async {
      final service = WorkoutStorageService(dbFactory: databaseFactoryFfi);
      await service.createWorkoutPlan('User Custom Routine', 'Weekly');

      final seeded = await seedDemoWorkoutDataIfNeeded(service);
      expect(seeded, isFalse);

      final plans = await service.fetchWorkoutPlans();
      expect(plans.length, 1);
      expect(plans.first.name, 'User Custom Routine');

      final sessions = await service.fetchAllSessions();
      expect(sessions, isEmpty);

      final logs = await service.fetchAllLogs();
      expect(logs, isEmpty);

      await service.close();
    },
  );

  test(
    'does not modify database and returns false when workout logs already exist',
    () async {
      final service = WorkoutStorageService(dbFactory: databaseFactoryFfi);
      await service.saveWorkoutLogs([
        WorkoutLogEntry(
          date: DateTime(2026, 9, 20),
          planId: 99,
          exerciseId: 1,
          setNumber: 1,
          reps: 10,
          weight: 60.0,
          rir: 2,
        ),
      ]);

      final seeded = await seedDemoWorkoutDataIfNeeded(service);
      expect(seeded, isFalse);

      final plans = await service.fetchWorkoutPlans();
      expect(plans, isEmpty);

      final sessions = await service.fetchAllSessions();
      expect(sessions, isEmpty);

      final logs = await service.fetchAllLogs();
      expect(logs.length, 1);

      await service.close();
    },
  );
}
