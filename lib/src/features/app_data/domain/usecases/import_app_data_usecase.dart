import '../repositories/app_data_repository.dart';
import 'dart:io';

class ImportAppDataUseCase {
  final AppDataRepository _repo;
  const ImportAppDataUseCase(this._repo);
  Future<void> call(File file) => _repo.importData(file);
}
