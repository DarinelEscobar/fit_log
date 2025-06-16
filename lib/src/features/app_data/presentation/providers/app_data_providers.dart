import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/app_data_repository_impl.dart';
import '../../domain/usecases/export_app_data_usecase.dart';
import '../../domain/usecases/import_app_data_usecase.dart';
import 'dart:io';

final _repoProvider = Provider((_) => AppDataRepositoryImpl());

final exportDataProvider = FutureProvider<File>((ref) {
  final usecase = ExportAppDataUseCase(ref.watch(_repoProvider));
  return usecase();
});

final importDataProvider = FutureProvider.family<void, File>((ref, file) {
  final usecase = ImportAppDataUseCase(ref.watch(_repoProvider));
  return usecase(file);
});
