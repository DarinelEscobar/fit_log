import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:excel/excel.dart';
import 'package:fit_log/src/data/create/initialize_xlsx.dart';
import 'package:fit_log/src/data/services/workout_storage_service.dart';
import 'package:fit_log/src/features/app_data/data/repositories/app_data_repository_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late Directory documentsDirectory;
  late Directory databaseDirectory;
  late String databasePath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('fitlog_data_test_');
    documentsDirectory = Directory(p.join(tempRoot.path, 'documents'));
    databaseDirectory = Directory(p.join(tempRoot.path, 'databases'));
    databasePath = p.join(databaseDirectory.path, 'fit_log.db');
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
    'repairDataIntegrity keeps history and fixes parent references',
    () async {
      final service = WorkoutStorageService(dbFactory: databaseFactoryFfi);
      await service.reopenIfNeeded();
      await service.close();

      final db = await databaseFactoryFfi.openDatabase(databasePath);
      await db.execute('DROP INDEX IF EXISTS idx_workout_logs_unique');
      await db.insert('workout_plans', {
        'plan_id': 1,
        'name': 'Existing Plan',
        'frequency': 'Weekly',
        'is_active': 1,
      });
      await db.insert('exercises', {
        'exercise_id': 1,
        'name': 'Existing Exercise',
        'description': '',
        'category': 'Compound',
        'main_muscle_group': 'Chest',
      });
      await db.insert('workout_logs', _logRow(exerciseId: 35));
      await db.insert('workout_logs', _logRow(exerciseId: 35));
      await db.insert('workout_logs', _logRow(planId: 9, exerciseId: 1));
      await db.insert('workout_sessions', {
        'date': '2026-01-02',
        'plan_id': 9,
        'fatigue_level': '3',
        'duration_minutes': 60,
        'mood': '4',
        'notes': '',
      });
      await db.insert(
        'plan_exercises',
        _planExerciseRow(planId: 0, exerciseId: 0),
      );
      await db.insert(
        'plan_exercises',
        _planExerciseRow(planId: 8, exerciseId: 77),
      );
      await db.close();

      await service.repairDataIntegrity();
      await service.close();

      final verifyDb = await databaseFactoryFfi.openDatabase(databasePath);
      addTearDown(verifyDb.close);

      expect(
        await _count(
          verifyDb,
          'SELECT COUNT(*) FROM workout_logs WHERE exercise_id = 35',
        ),
        1,
      );
      expect(
        await _count(
          verifyDb,
          "SELECT COUNT(*) FROM exercises WHERE name = 'Recovered Exercise 35'",
        ),
        1,
      );
      expect(
        await _count(
          verifyDb,
          "SELECT COUNT(*) FROM exercises WHERE name = 'Recovered Exercise 77'",
        ),
        1,
      );
      expect(
        await _count(
          verifyDb,
          "SELECT COUNT(*) FROM workout_plans WHERE name = 'Recovered Plan 9'",
        ),
        1,
      );
      expect(
        await _count(
          verifyDb,
          "SELECT COUNT(*) FROM workout_plans WHERE name = 'Recovered Plan 8'",
        ),
        1,
      );
      expect(
        await _count(
          verifyDb,
          'SELECT COUNT(*) FROM plan_exercises WHERE plan_id <= 0 '
          'OR exercise_id <= 0',
        ),
        0,
      );
      expect(await _planExerciseOrphanCount(verifyDb), 0);
    },
  );

  test('invalid zip import leaves the current database intact', () async {
    final service = WorkoutStorageService(dbFactory: databaseFactoryFfi);
    await service.reopenIfNeeded();
    await service.close();

    final db = await databaseFactoryFfi.openDatabase(databasePath);
    await db.insert('workout_plans', {
      'plan_id': 1,
      'name': 'Do Not Replace',
      'frequency': 'Weekly',
      'is_active': 1,
    });
    await db.close();

    final archive = Archive()
      ..addFile(ArchiveFile('notes.txt', 4, [110, 111, 116, 101]));
    final invalidZip = File(p.join(tempRoot.path, 'invalid_backup.zip'));
    await invalidZip.writeAsBytes(ZipEncoder().encode(archive)!);

    final repository = AppDataRepositoryImpl(
      storageService: WorkoutStorageService(dbFactory: databaseFactoryFfi),
    );

    await expectLater(
      repository.importData(invalidZip),
      throwsA(isA<FormatException>()),
    );

    final verifyDb = await databaseFactoryFfi.openDatabase(databasePath);
    addTearDown(verifyDb.close);
    expect(
      await _count(
        verifyDb,
        "SELECT COUNT(*) FROM workout_plans WHERE name = 'Do Not Replace'",
      ),
      1,
    );
  });

  test('xlsx initializer writes empty cells instead of null text', () async {
    await XlsxInitializer.ensureXlsxFilesExist();

    final metricsFile = File(
      p.join(documentsDirectory.path, 'body_metrics.xlsx'),
    );
    final excel = Excel.decodeBytes(await metricsFile.readAsBytes());
    final sheet = excel.tables['BodyMetrics']!;
    final bodyFatValue = sheet.rows[1][3]?.value;

    expect(bodyFatValue?.toString(), isNot('null'));
  });
}

Map<String, Object?> _logRow({int planId = 1, required int exerciseId}) {
  return {
    'date': '2026-01-01',
    'plan_id': planId,
    'exercise_id': exerciseId,
    'set_number': 1,
    'reps': 10,
    'weight': 20.0,
    'rir': 2,
  };
}

Map<String, Object?> _planExerciseRow({
  required int planId,
  required int exerciseId,
}) {
  return {
    'plan_id': planId,
    'exercise_id': exerciseId,
    'position': 0,
    'suggested_sets': 3,
    'suggested_reps': 10,
    'estimated_weight': 20.0,
    'rest_seconds': 60,
    'rir': 2,
    'tempo': '3-1-1-0',
    'image_path': '',
  };
}

Future<int> _count(Database db, String sql) async {
  return Sqflite.firstIntValue(await db.rawQuery(sql)) ?? 0;
}

Future<int> _planExerciseOrphanCount(Database db) {
  return _count(db, '''
    SELECT COUNT(*)
    FROM plan_exercises plan_exercises
    LEFT JOIN workout_plans plans
      ON plans.plan_id = plan_exercises.plan_id
    LEFT JOIN exercises exercises
      ON exercises.exercise_id = plan_exercises.exercise_id
    WHERE plans.plan_id IS NULL
      OR exercises.exercise_id IS NULL
    ''');
}
