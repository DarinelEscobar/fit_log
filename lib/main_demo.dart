import 'package:flutter/material.dart';

import 'main.dart' as entrypoint;
import 'src/data/fixtures/demo_workout_seed.dart';
import 'src/data/services/workout_storage_service.dart';

/// Entry point for running FitLog with minimal demo fixture data.
///
/// Seeds demo routines, exercises, warmup steps, and recent history
/// only if the database has no plans, logs, or sessions.
/// Closes the seed storage service before delegating to normal [entrypoint.main].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = WorkoutStorageService();
  try {
    await seedDemoWorkoutDataIfNeeded(storageService);
  } finally {
    await storageService.close();
  }

  await entrypoint.main();
}
