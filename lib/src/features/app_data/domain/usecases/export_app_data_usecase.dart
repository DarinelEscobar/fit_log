import '../repositories/app_data_repository.dart';
import 'dart:io';

class ExportAppDataUseCase {
  final AppDataRepository _repo;
  const ExportAppDataUseCase(this._repo);
  Future<File> call() => _repo.exportData();
}
