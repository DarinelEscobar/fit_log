import 'dart:io';
import 'package:flutter/foundation.dart';

abstract class AppDataRepository {
  /// Exports all application data into a zip file and returns the file.
  Future<File> exportData();

  /// Imports and merges the provided zip file into existing data.
  Future<void> importData(File file);
}
