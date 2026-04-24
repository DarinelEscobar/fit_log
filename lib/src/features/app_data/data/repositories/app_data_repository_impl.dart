import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../data/services/workout_storage_service.dart';
import '../../../../data/schema/schemas.dart';
import '../../../../features/routines/domain/entities/workout_log_entry.dart';
import '../../../../features/routines/domain/entities/workout_session.dart';
import '../../domain/repositories/app_data_repository.dart';

class AppDataRepositoryImpl implements AppDataRepository {
  AppDataRepositoryImpl({WorkoutStorageService? storageService})
      : _storageService = storageService ?? WorkoutStorageService();

  static const String _databaseFilename = 'fit_log.db';
  static const Set<String> _routineSpreadsheetFilenames = {
    'workout_plan.xlsx',
    'exercise.xlsx',
    'plan_exercise.xlsx',
  };

  final WorkoutStorageService _storageService;

  @override
  Future<File> exportData() async {
    final dir = await getApplicationDocumentsDirectory();
    final databaseDir = await getDatabasesPath();
    await _storageService.repairDataIntegrity();
    await _storageService.exportRoutineRuntimeToXlsxFiles(dir);
    await _syncWorkoutExports(dir);
    final archive = Archive();
    for (final filename in kTableSchemas.keys) {
      final file = File(p.join(dir.path, filename));
      await _addFileToArchive(archive, file, filename);
    }
    final databaseFile = File(p.join(databaseDir, _databaseFilename));
    await _addFileToArchive(
      archive,
      databaseFile,
      p.basename(databaseFile.path),
    );
    final encoder = ZipEncoder();
    final data = encoder.encode(archive);
    final outFile = File(p.join(dir.path, 'fitlog_backup.zip'));
    if (data != null) await outFile.writeAsBytes(data, flush: true);

    // Try to also copy the backup to external storage so the user can access it
    try {
      if (await Permission.storage.request().isGranted) {
        final downloads = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (downloads != null && downloads.isNotEmpty) {
          final extFile = File(
            p.join(downloads.first.path, 'fitlog_backup.zip'),
          );
          await outFile.copy(extFile.path);
          return extFile;
        }
      }
    } catch (e) {
      debugPrint('Failed to copy backup to external storage: $e');
    }

    return outFile;
  }

  @override
  Future<void> importData(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final databaseDir = await getDatabasesPath();
    final ext = p.extension(file.path).toLowerCase();

    if (ext == '.xlsx') {
      await _importSpreadsheet(file, dir, databaseDir);
      return;
    }

    if (ext != '.zip') {
      throw FormatException(
        'Unsupported import file: ${p.basename(file.path)}',
      );
    }

    final stagingDirectory = await Directory.systemTemp.createTemp(
      'fitlog_import_',
    );
    try {
      final stagedDocumentsDirectory = Directory(
        p.join(stagingDirectory.path, 'documents'),
      );
      await stagedDocumentsDirectory.create(recursive: true);

      File? stagedDatabase;
      final stagedSpreadsheets = <String, File>{};

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final archived in archive.files) {
        if (!archived.isFile) {
          continue;
        }

        final name = p.basename(archived.name);
        if (name == _databaseFilename) {
          stagedDatabase = File(p.join(stagingDirectory.path, name));
          await stagedDatabase.writeAsBytes(
            archived.content as List<int>,
            flush: true,
          );
          continue;
        }

        if (!kTableSchemas.containsKey(name)) {
          continue;
        }

        final stagedSpreadsheet = File(
          p.join(stagedDocumentsDirectory.path, name),
        );
        await stagedSpreadsheet.writeAsBytes(
          archived.content as List<int>,
          flush: true,
        );
        stagedSpreadsheets[name] = stagedSpreadsheet;
      }

      if (stagedDatabase == null && stagedSpreadsheets.isEmpty) {
        throw const FormatException(
          'Backup does not contain Fit Log data files.',
        );
      }

      if (stagedDatabase != null) {
        await _storageService.validateDatabaseFile(stagedDatabase);
      }
      for (final entry in stagedSpreadsheets.entries) {
        _validateSpreadsheetFile(entry.value, entry.key);
      }

      await _restoreStagedImport(
        documentsDirectory: dir,
        databaseDirectoryPath: databaseDir,
        stagedDatabase: stagedDatabase,
        stagedSpreadsheets: stagedSpreadsheets,
      );
    } finally {
      if (await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> _addFileToArchive(
    Archive archive,
    File file,
    String archiveName,
  ) async {
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(archiveName, bytes.length, bytes));
  }

  Future<void> _syncWorkoutExports(Directory directory) async {
    final logs = await _storageService.fetchAllLogs();
    final sessions = await _storageService.fetchAllSessions();
    await _writeWorkoutLogExport(directory, logs);
    await _writeWorkoutSessionExport(directory, sessions);
  }

  Future<void> _importSpreadsheet(
    File file,
    Directory directory,
    String databaseDirectoryPath,
  ) async {
    final filename = p.basename(file.path);
    if (!kTableSchemas.containsKey(filename)) {
      throw FormatException('Unsupported spreadsheet: $filename');
    }

    final stagingDirectory = await Directory.systemTemp.createTemp(
      'fitlog_spreadsheet_import_',
    );
    try {
      final stagedFile = File(p.join(stagingDirectory.path, filename));
      await stagedFile.writeAsBytes(await file.readAsBytes(), flush: true);
      _validateSpreadsheetFile(stagedFile, filename);

      await _restoreStagedImport(
        documentsDirectory: directory,
        databaseDirectoryPath: databaseDirectoryPath,
        stagedSpreadsheets: {filename: stagedFile},
      );
    } finally {
      if (await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> _restoreStagedImport({
    required Directory documentsDirectory,
    required String databaseDirectoryPath,
    File? stagedDatabase,
    required Map<String, File> stagedSpreadsheets,
  }) async {
    final rollbackDirectory = await Directory.systemTemp.createTemp(
      'fitlog_import_rollback_',
    );
    final databaseDirectory = Directory(databaseDirectoryPath);
    final activeDatabaseFile = File(
      p.join(databaseDirectory.path, _databaseFilename),
    );
    File? databaseRollbackFile;
    final spreadsheetRollbackFiles = <String, File?>{};

    Future<void> restoreFile(File target, File? rollbackFile) async {
      if (rollbackFile == null) {
        if (await target.exists()) {
          await target.delete();
        }
        return;
      }
      await target.parent.create(recursive: true);
      await rollbackFile.copy(target.path);
    }

    try {
      await databaseDirectory.create(recursive: true);
      await documentsDirectory.create(recursive: true);

      if (await activeDatabaseFile.exists()) {
        databaseRollbackFile = await activeDatabaseFile.copy(
          p.join(rollbackDirectory.path, _databaseFilename),
        );
      }

      for (final filename in kTableSchemas.keys) {
        final activeSpreadsheet = File(
          p.join(documentsDirectory.path, filename),
        );
        if (await activeSpreadsheet.exists()) {
          spreadsheetRollbackFiles[filename] = await activeSpreadsheet.copy(
            p.join(rollbackDirectory.path, filename),
          );
        } else {
          spreadsheetRollbackFiles[filename] = null;
        }
      }

      await _storageService.close();

      try {
        if (stagedDatabase != null) {
          await stagedDatabase.copy(activeDatabaseFile.path);
        }

        for (final entry in stagedSpreadsheets.entries) {
          await entry.value.copy(p.join(documentsDirectory.path, entry.key));
        }

        await _storageService.reopenIfNeeded();
        await _applyImportedSpreadsheets(
          stagedSpreadsheets.keys.toSet(),
          restoredDatabase: stagedDatabase != null,
        );
        await _storageService.repairDataIntegrity();
        await _regenerateSqliteExports(documentsDirectory);
      } catch (error, stackTrace) {
        await _storageService.close();
        await restoreFile(activeDatabaseFile, databaseRollbackFile);
        for (final entry in spreadsheetRollbackFiles.entries) {
          await restoreFile(
            File(p.join(documentsDirectory.path, entry.key)),
            entry.value,
          );
        }
        await _storageService.reopenIfNeeded();
        Error.throwWithStackTrace(error, stackTrace);
      }
    } finally {
      if (await rollbackDirectory.exists()) {
        await rollbackDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> _applyImportedSpreadsheets(
    Set<String> filenames, {
    required bool restoredDatabase,
  }) async {
    final restoredRoutineSheet = filenames.any(
      _routineSpreadsheetFilenames.contains,
    );
    final restoredLogSheet = filenames.contains('workout_log.xlsx');
    final restoredSessionSheet = filenames.contains('workout_session.xlsx');

    if (!restoredDatabase && restoredRoutineSheet) {
      await _storageService.warmUpRoutineRuntimeCache(force: true);
    }

    if (restoredLogSheet &&
        (!restoredDatabase || !await _storageService.hasUsableWorkoutLogs())) {
      await _storageService.replaceWorkoutLogsFromCurrentXlsxFiles();
    }

    if (restoredSessionSheet &&
        (!restoredDatabase ||
            !await _storageService.hasUsableWorkoutSessions())) {
      await _storageService.replaceWorkoutSessionsFromCurrentXlsxFiles();
    }
  }

  Future<void> _regenerateSqliteExports(Directory directory) async {
    await _storageService.exportRoutineRuntimeToXlsxFiles(directory);
    await _syncWorkoutExports(directory);
  }

  void _validateSpreadsheetFile(File file, String filename) {
    final schema = kTableSchemas[filename];
    if (schema == null) {
      throw FormatException('Unsupported spreadsheet: $filename');
    }
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw FormatException('Spreadsheet is missing or empty: $filename');
    }

    final excel = Excel.decodeBytes(file.readAsBytesSync());
    final sheet = excel.tables[schema.sheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      throw FormatException(
        'Spreadsheet $filename is missing sheet ${schema.sheetName}.',
      );
    }

    final headers = _spreadsheetHeaderSet(sheet.rows.first);
    final requiredHeaders = _requiredSpreadsheetHeaderGroups(filename, schema);
    final missingHeaders = <String>[];
    for (final entry in requiredHeaders.entries) {
      final hasHeader = entry.value.any(
        (header) => headers.contains(_normalizeHeaderName(header)),
      );
      if (!hasHeader) {
        missingHeaders.add(entry.key);
      }
    }

    if (missingHeaders.isNotEmpty) {
      throw FormatException(
        'Spreadsheet $filename is missing columns: '
        '${missingHeaders.join(', ')}.',
      );
    }
  }

  Map<String, List<String>> _requiredSpreadsheetHeaderGroups(
    String filename,
    TableSchema schema,
  ) {
    switch (filename) {
      case 'workout_plan.xlsx':
        return const {
          'plan_id': ['plan_id'],
          'name': ['name'],
          'frequency': ['frequency'],
        };
      case 'exercise.xlsx':
        return const {
          'exercise_id': ['exercise_id'],
          'name': ['name'],
          'description': ['description'],
          'category': ['category'],
          'main_muscle_group': ['main_muscle_group'],
        };
      case 'plan_exercise.xlsx':
        return const {
          'plan_id': ['plan_id'],
          'exercise_id': ['exercise_id'],
          'suggested_sets': ['suggested_sets'],
          'suggested_reps': ['suggested_reps'],
          'estimated_weight': ['estimated_weight'],
          'rest_seconds': ['rest_seconds'],
        };
      case 'workout_log.xlsx':
        return const {
          'date': ['date'],
          'plan_id': ['plan_id'],
          'exercise_id': ['exercise_id'],
          'set_number': ['set_number'],
          'reps_completed': ['reps_completed', 'reps'],
          'weight_used': ['weight_used', 'weight'],
          'RIR': ['rir'],
        };
      case 'workout_session.xlsx':
        return const {
          'date': ['date'],
          'plan_id': ['plan_id'],
          'fatigue_level': ['fatigue_level'],
          'duration_minutes': ['duration_minutes'],
          'mood': ['mood'],
          'notes': ['notes'],
        };
      default:
        return {
          for (final header in schema.headers) header: [header],
        };
    }
  }

  Set<String> _spreadsheetHeaderSet(List<Data?> headerRow) {
    return {
      for (final cell in headerRow)
        if (_cellText(cell).trim().isNotEmpty)
          _normalizeHeaderName(_cellText(cell)),
    };
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) {
      return '';
    }
    if (value is TextCellValue) {
      return value.value.toString();
    }
    if (value is IntCellValue) {
      return value.value.toString();
    }
    if (value is DoubleCellValue) {
      return value.value.toString();
    }
    if (value is BoolCellValue) {
      return value.value.toString();
    }
    return value.toString();
  }

  String _normalizeHeaderName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _writeWorkoutLogExport(
    Directory directory,
    List<WorkoutLogEntry> logs,
  ) async {
    final schema = kTableSchemas['workout_log.xlsx'];
    if (schema == null) return;
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, schema.sheetName);
    }
    final sheet = excel[schema.sheetName];
    sheet.appendRow(
      schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList(),
    );
    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(_formatDate(log.date)),
        IntCellValue(log.planId),
        IntCellValue(log.exerciseId),
        IntCellValue(log.setNumber),
        IntCellValue(log.reps),
        DoubleCellValue(log.weight),
        IntCellValue(log.rir),
      ]);
    }
    final bytes = excel.save();
    if (bytes == null) return;
    final file = File(p.join(directory.path, 'workout_log.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _writeWorkoutSessionExport(
    Directory directory,
    List<WorkoutSession> sessions,
  ) async {
    final schema = kTableSchemas['workout_session.xlsx'];
    if (schema == null) return;
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, schema.sheetName);
    }
    final sheet = excel[schema.sheetName];
    sheet.appendRow(
      schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList(),
    );
    for (var i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(_formatDate(session.date)),
        IntCellValue(session.planId),
        TextCellValue(session.fatigueLevel),
        IntCellValue(session.durationMinutes),
        TextCellValue(session.mood),
        TextCellValue(session.notes),
      ]);
    }
    final bytes = excel.save();
    if (bytes == null) return;
    final file = File(p.join(directory.path, 'workout_session.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
}
