import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/data/sqlite/app_database.dart';
import 'src/data/services/excel_sync_service.dart';
import 'src/app.dart';
import 'src/utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.instance;
  await ExcelSyncService(db).migrateFromExcel();
  await NotificationService.init();
  runApp(const ProviderScope(child: MyApp()));
}
