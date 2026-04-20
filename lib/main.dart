import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/data/create/initialize_xlsx.dart';
import 'src/data/providers/workout_storage_service_provider.dart';
import 'src/app.dart';
import 'src/utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await XlsxInitializer.ensureXlsxFilesExist();
  final container = ProviderContainer();
  await container
      .read(workoutStorageServiceProvider)
      .warmUpRoutineRuntimeCache();
  await NotificationService.init();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}
