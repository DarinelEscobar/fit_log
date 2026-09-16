import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../data/create/initialize_xlsx.dart';
import '../../../../data/services/workout_storage_service.dart';
import '../../../../data/schema/schemas.dart';
import '../../../../features/routines/domain/entities/workout_log_entry.dart';
import '../../../../features/routines/domain/entities/workout_session.dart';
import '../../domain/repositories/app_data_repository.dart';
import '../../domain/entities/export_models.dart';

class AppDataRepositoryImpl implements AppDataRepository {
  AppDataRepositoryImpl({WorkoutStorageService? storageService})
      : _storageService = storageService ?? WorkoutStorageService();

  static const String _databaseFilename = 'fit_log.db';
  static const String _manifestFilename = 'export_manifest.json';
  static const String _exportHistoryKey = 'successful_export_date_ranges_v1';
  static const Set<String> _routineSpreadsheetFilenames = {
    'workout_plan.xlsx',
    'exercise.xlsx',
    'plan_exercise.xlsx',
    'warm_up_step.xlsx',
  };

  final WorkoutStorageService _storageService;

  @override
  Future<ExportAvailability> getExportAvailability() async {
    final logs = await _storageService.fetchAllLogs();
    final sessions = await _storageService.fetchAllSessions();
    final dates = [
      ...logs.map((log) => _dateOnly(log.date)),
      ...sessions.map((session) => _dateOnly(session.date)),
    ]..sort();
    final ranges = await _readExportRanges();
    final firstDate = dates.isEmpty ? null : dates.first;
    final lastDate = dates.isEmpty ? null : dates.last;
    return ExportAvailability(
      firstDate: firstDate,
      lastDate: lastDate,
      nextMissingRange: _findNextMissingRange(dates, ranges),
      lastExportedDate: ranges.isEmpty
          ? null
          : ranges.map((range) => range.endDate).reduce(
                (current, value) => value.isAfter(current) ? value : current,
              ),
      hasExportHistory: ranges.isNotEmpty,
    );
  }

  @override
  Future<File> exportData({
    ExportRequest request = const ExportRequest.automatic(),
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final databaseDir = await getDatabasesPath();
    await XlsxInitializer.ensureXlsxFilesExist(includeSampleRows: false);
    await _storageService.repairDataIntegrity();
    await _storageService.exportRoutineRuntimeToXlsxFiles(dir);

    final availability = await getExportAvailability();
    final history = await _readExportRanges();
    final selectedRange = request.mode == ExportRangeMode.automatic
        ? availability.nextMissingRange ??
            (!availability.hasWorkoutData && !availability.hasExportHistory
                ? ExportDateRange(DateTime.now(), DateTime.now())
                : null)
        : request.range;
    if (selectedRange == null) {
      throw StateError(
        'No new workout data to export. Choose a custom date range to export again.',
      );
    }

    final logs = await _storageService.fetchWorkoutLogs(
      startDate: selectedRange.startDate,
      endDate: selectedRange.endDate,
    );
    final sessions = await _storageService.fetchWorkoutSessions(
      startDate: selectedRange.startDate,
      endDate: selectedRange.endDate,
    );
    if (logs.isEmpty && sessions.isEmpty && availability.hasWorkoutData) {
      throw StateError('No workout data exists in the selected date range.');
    }

    await _syncWorkoutExports(dir, logs: logs, sessions: sessions);
    final archive = Archive();
    for (final filename in kTableSchemas.keys) {
      final file = File(p.join(dir.path, filename));
      await _addFileToArchive(archive, file, filename);
    }
    final isFirstAutomaticExport =
        request.mode == ExportRangeMode.automatic && history.isEmpty;
    if (isFirstAutomaticExport) {
      final databaseFile = File(p.join(databaseDir, _databaseFilename));
      await _addFileToArchive(
        archive,
        databaseFile,
        p.basename(databaseFile.path),
      );
    }
    final manifest = jsonEncode({
      'format': 'fitlog-range-export-v1',
      'historyMode': isFirstAutomaticExport ? 'complete' : 'incremental',
      'startDate': selectedRange.startIso,
      'endDate': selectedRange.endIso,
      'createdAt': DateTime.now().toIso8601String(),
      'workoutLogCount': logs.length,
      'workoutSessionCount': sessions.length,
    });
    _addBytesToArchive(
      archive,
      _manifestFilename,
      utf8.encode(manifest),
    );
    final encoder = ZipEncoder();
    final data = encoder.encode(archive);
    if (data == null) {
      throw StateError('The backup archive could not be created.');
    }
    final outputName =
        'fitlog_backup_${selectedRange.startIso}_to_${selectedRange.endIso}.zip';
    final outFile = await _nextAvailableFile(dir, outputName);
    await outFile.writeAsBytes(data, flush: true);
    await _recordExportRange(selectedRange);

    // Try to also copy the backup to external storage so the user can access it
    try {
      if (await Permission.storage.request().isGranted) {
        final downloads = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (downloads != null && downloads.isNotEmpty) {
          final extFile = File(
            p.join(downloads.first.path, p.basename(outFile.path)),
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
      var incrementalHistory = false;
      ExportDateRange? importedRange;

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final archived in archive.files) {
        if (!archived.isFile) {
          continue;
        }

        final name = p.basename(archived.name);
        if (name == _manifestFilename) {
          final manifest = jsonDecode(
            utf8.decode(archived.content as List<int>),
          );
          if (manifest is Map &&
              manifest['format'] == 'fitlog-range-export-v1') {
            incrementalHistory = manifest['historyMode'] == 'incremental';
            importedRange = ExportDateRange.tryParse(manifest);
          }
          continue;
        }
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
      if (incrementalHistory && stagedDatabase != null) {
        throw const FormatException(
          'Incremental backups must not contain a full database file.',
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
        incrementalHistory: incrementalHistory,
      );
      if (importedRange != null) {
        await _recordExportRange(importedRange);
      }
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

  void _addBytesToArchive(Archive archive, String filename, List<int> bytes) {
    archive.addFile(ArchiveFile(filename, bytes.length, bytes));
  }

  Future<void> _syncWorkoutExports(
    Directory directory, {
    required List<WorkoutLogEntry> logs,
    required List<WorkoutSession> sessions,
  }) async {
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
    bool incrementalHistory = false,
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
          incrementalHistory: incrementalHistory,
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
    required bool incrementalHistory,
  }) async {
    final restoredRoutineSheet = filenames.any(
      _routineSpreadsheetFilenames.contains,
    );
    final restoredLogSheet = filenames.contains('workout_log.xlsx');
    final restoredSessionSheet = filenames.contains('workout_session.xlsx');

    if (!restoredDatabase && restoredRoutineSheet) {
      await _storageService.warmUpRoutineRuntimeCache(force: true);
    }

    if (incrementalHistory) {
      await _storageService.mergeWorkoutHistoryFromCurrentXlsxFiles(
        includeLogs: restoredLogSheet,
        includeSessions: restoredSessionSheet,
      );
    } else {
      if (restoredLogSheet &&
          (!restoredDatabase ||
              !await _storageService.hasUsableWorkoutLogs())) {
        await _storageService.replaceWorkoutLogsFromCurrentXlsxFiles();
      }

      if (restoredSessionSheet &&
          (!restoredDatabase ||
              !await _storageService.hasUsableWorkoutSessions())) {
        await _storageService.replaceWorkoutSessionsFromCurrentXlsxFiles();
      }
    }
  }

  Future<void> _regenerateSqliteExports(Directory directory) async {
    await _storageService.exportRoutineRuntimeToXlsxFiles(directory);
    await _syncWorkoutExports(
      directory,
      logs: await _storageService.fetchAllLogs(),
      sessions: await _storageService.fetchAllSessions(),
    );
  }

  Future<List<ExportDateRange>> _readExportRanges() async {
    final raw = await _storageService.readMetadata(_exportHistoryKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(ExportDateRange.tryParse)
          .whereType<ExportDateRange>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> _recordExportRange(ExportDateRange range) async {
    final ranges = [...await _readExportRanges(), range]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final merged = <ExportDateRange>[];
    for (final current in ranges) {
      if (merged.isEmpty) {
        merged.add(current);
        continue;
      }
      final previous = merged.last;
      final joinsPrevious = !current.startDate.isAfter(
        _nextDay(previous.endDate),
      );
      if (joinsPrevious) {
        merged[merged.length - 1] = ExportDateRange(
          previous.startDate,
          current.endDate.isAfter(previous.endDate)
              ? current.endDate
              : previous.endDate,
        );
      } else {
        merged.add(current);
      }
    }
    await _storageService.writeMetadata(
      _exportHistoryKey,
      jsonEncode(merged.map((value) => value.toJson()).toList()),
    );
  }

  ExportDateRange? _findNextMissingRange(
    List<DateTime> availableDates,
    List<ExportDateRange> ranges,
  ) {
    final dates = availableDates.toSet().toList()..sort();
    for (var index = 0; index < dates.length; index++) {
      if (ranges.any((range) => range.contains(dates[index]))) {
        continue;
      }
      final start = dates[index];
      var end = start;
      while (index + 1 < dates.length &&
          !ranges.any((range) => range.contains(dates[index + 1]))) {
        index++;
        end = dates[index];
      }
      return ExportDateRange(start, end);
    }
    return null;
  }

  Future<File> _nextAvailableFile(Directory directory, String filename) async {
    final extension = p.extension(filename);
    final stem = filename.substring(0, filename.length - extension.length);
    var candidate = File(p.join(directory.path, filename));
    var suffix = 2;
    while (await candidate.exists()) {
      candidate = File(p.join(directory.path, '${stem}_$suffix$extension'));
      suffix++;
    }
    return candidate;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _nextDay(DateTime date) => date.add(const Duration(days: 1));

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
      case 'warm_up_step.xlsx':
        return const {
          'plan_id': ['plan_id'],
          'name': ['name'],
          'sets': ['sets'],
          'work_seconds': ['work_seconds'],
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
