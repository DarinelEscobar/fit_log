import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/data/create/initialize_xlsx.dart';
import 'src/app.dart';
import 'src/utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await XlsxInitializer.ensureXlsxFilesExist();
  await NotificationService.init();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
