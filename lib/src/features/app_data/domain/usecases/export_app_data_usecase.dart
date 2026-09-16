import 'dart:io';

import '../entities/export_models.dart';
import '../repositories/app_data_repository.dart';

class ExportAppDataUseCase {
  final AppDataRepository _repo;
  const ExportAppDataUseCase(this._repo);
  Future<File> call(
          {ExportRequest request = const ExportRequest.automatic()}) =>
      _repo.exportData(request: request);
}
