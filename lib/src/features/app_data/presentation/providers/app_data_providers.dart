import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../data/repositories/app_data_repository_impl.dart';
import '../../domain/repositories/app_data_repository.dart';
import '../../domain/usecases/export_app_data_usecase.dart';
import '../../domain/usecases/import_app_data_usecase.dart';

final appDataRepositoryProvider =
    Provider<AppDataRepository>((_) => AppDataRepositoryImpl());

final exportDataProvider = FutureProvider<File>((ref) {
  final usecase = ExportAppDataUseCase(ref.watch(appDataRepositoryProvider));
  return usecase();
});

final importDataProvider = FutureProvider.family<void, File>((ref, file) {
  final usecase = ImportAppDataUseCase(ref.watch(appDataRepositoryProvider));
  return usecase(file);
});
