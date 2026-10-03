import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../../../../data/providers/workout_storage_service_provider.dart';
import '../../data/repositories/app_data_repository_impl.dart';
import '../../domain/repositories/app_data_repository.dart';
import '../../domain/usecases/export_app_data_usecase.dart';
import '../../domain/usecases/import_app_data_usecase.dart';

abstract class BackupShareService {
  Future<ShareResult> shareBackupFile(File file);
}

class SharePlusBackupShareService implements BackupShareService {
  const SharePlusBackupShareService();

  @override
  Future<ShareResult> shareBackupFile(File file) {
    return Share.shareXFiles(
      [XFile(file.path)],
      text: 'Backup Fit Log',
      subject: 'FitLog Backup',
    );
  }
}

final backupShareServiceProvider = Provider<BackupShareService>((ref) {
  return const SharePlusBackupShareService();
});

final appDataRepositoryProvider = Provider<AppDataRepository>((ref) {
  return AppDataRepositoryImpl(
    storageService: ref.watch(workoutStorageServiceProvider),
  );
});

final exportDataProvider = FutureProvider<File>((ref) {
  final usecase = ExportAppDataUseCase(ref.watch(appDataRepositoryProvider));
  return usecase();
});

final importDataProvider = FutureProvider.family<void, File>((ref, file) {
  final usecase = ImportAppDataUseCase(ref.watch(appDataRepositoryProvider));
  return usecase(file);
});

