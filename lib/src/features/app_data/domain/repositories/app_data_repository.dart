import 'dart:io';

import '../entities/export_models.dart';

abstract class AppDataRepository {
  /// Returns the available workout dates and the next automatic export range.
  Future<ExportAvailability> getExportAvailability();

  /// Exports the selected date range into a zip file and returns the file.
  Future<File> exportData(
      {ExportRequest request = const ExportRequest.automatic()});

  /// Imports and merges the provided zip file into existing data.
  Future<void> importData(File file);
}
