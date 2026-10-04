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
  static const String _exportSignaturesKey = 'successful_export_signatures_v2';
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
      nextMissingRange: await _findChangedRange(logs, sessions),
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
    final selectedRange = switch (request.mode) {
      ExportRangeMode.automatic => availability.nextMissingRange ??
          (!availability.hasWorkoutData && !availability.hasExportHistory
              ? ExportDateRange(DateTime.now(), DateTime.now())
              : null),
      ExportRangeMode.full => request.range ??
          (availability.hasWorkoutData
              ? ExportDateRange(availability.firstDate!, availability.lastDate!)
              : ExportDateRange(DateTime.now(), DateTime.now())),
      ExportRangeMode.custom => request.range,
    };
    if (selectedRange == null) {
      if (request.mode == ExportRangeMode.automatic) {
        throw StateError(
          'No new workout data to export. Choose a custom date range to export again.',
        );
      } else {
        throw StateError('No date range specified for export.');
      }
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

    final archive = Archive();
    final historyExport =
        await Directory.systemTemp.createTemp('fitlog_export_history_');
    try {
      await _syncWorkoutExports(historyExport, logs: logs, sessions: sessions);
      for (final filename in kTableSchemas.keys) {
        final source =
            filename == 'workout_log.xlsx' || filename == 'workout_session.xlsx'
                ? historyExport
                : dir;
        final file = File(p.join(source.path, filename));
        await _addFileToArchive(archive, file, filename);
      }
    } finally {
      await historyExport.delete(recursive: true);
    }
    final isCompleteBackup = request.mode == ExportRangeMode.full ||
        (request.mode == ExportRangeMode.automatic &&
            !availability.hasExportHistory);
    if (isCompleteBackup) {
      final databaseFile = File(p.join(databaseDir, _databaseFilename));
      await _addFileToArchive(
        archive,
        databaseFile,
        p.basename(databaseFile.path),
      );
    }
    final manifest = jsonEncode({
      'format': 'fitlog-range-export-v1',
      'historyMode': isCompleteBackup ? 'complete' : 'incremental',
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
    await _recordSignatures(logs, sessions);

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
      await compute(_validateImportSheets, {
        for (final entry in stagedSpreadsheets.entries)
          entry.key: entry.value.path
      });

      await _restoreStagedImport(
        documentsDirectory: dir,
        databaseDirectoryPath: databaseDir,
        stagedDatabase: stagedDatabase,
        stagedSpreadsheets: stagedSpreadsheets,
        incrementalHistory: incrementalHistory,
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
      await compute(_validateImportSheets, {filename: stagedFile.path});

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
    final sourceDirectory = stagedSpreadsheets.isEmpty
        ? await Directory.systemTemp.createTemp('fitlog_empty_sheets_')
        : stagedSpreadsheets.values.first.parent;
    final previousFiles = <String, List<int>?>{};
    try {
      final prepared = <String, List<int>>{};
      for (final entry in stagedSpreadsheets.entries) {
        if (_routineSpreadsheetFilenames.contains(entry.key) ||
            entry.key == 'workout_log.xlsx' ||
            entry.key == 'workout_session.xlsx') {
          continue;
        }
        final target = File(p.join(documentsDirectory.path, entry.key));
        final bytes = await compute(_mergeAncillarySheet, {
          'filename': entry.key,
          'incoming': entry.value.path,
          'local': target.path,
        });
        if (bytes != null) prepared[target.path] = bytes;
      }
      for (final entry in prepared.entries) {
        final target = File(entry.key);
        previousFiles[entry.key] =
            await target.exists() ? await target.readAsBytes() : null;
        final pending = File('${target.path}.pending');
        await pending.writeAsBytes(entry.value, flush: true);
        await pending.rename(target.path);
      }
      await _storageService.mergeBackup(sourceDirectory,
          database: stagedDatabase);
      // SQLite is authoritative. Failure to refresh compatibility sheets must
      // not undo a successful history merge or replace the live database.
      try {
        await _regenerateSqliteExports(documentsDirectory);
      } catch (error) {
        debugPrint(
            'Imported data saved; spreadsheet refresh can retry: $error');
      }
    } catch (_) {
      for (final entry in previousFiles.entries) {
        final target = File(entry.key);
        if (entry.value == null) {
          if (await target.exists()) await target.delete();
        } else {
          await target.writeAsBytes(entry.value!, flush: true);
        }
      }
      rethrow;
    } finally {
      if (stagedSpreadsheets.isEmpty) {
        await sourceDirectory.delete(recursive: true);
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

  Map<String, String> _dailySignatures(
      List<WorkoutLogEntry> logs, List<WorkoutSession> sessions) {
    final rows = <String, List<String>>{};
    for (final log in logs) {
      rows.putIfAbsent(_formatDate(log.date), () => []).add(jsonEncode([
            'log',
            log.storageSessionId,
            log.planId,
            log.exerciseId,
            log.setNumber,
            log.reps,
            log.weight,
            log.rir,
          ]));
    }
    for (final session in sessions) {
      rows.putIfAbsent(_formatDate(session.date), () => []).add(jsonEncode([
            'session',
            session.storageSessionId,
            session.planId,
            session.fatigueLevel,
            session.durationMinutes,
            session.mood,
            session.notes,
          ]));
    }
    return {
      for (final entry in rows.entries)
        entry.key: jsonEncode(entry.value..sort())
    };
  }

  Future<Map<String, String>> _readSignatures() async {
    final raw = await _storageService.readMetadata(_exportSignaturesKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry('$key', '$value'))
          : {};
    } on FormatException {
      return {};
    }
  }

  Future<ExportDateRange?> _findChangedRange(
      List<WorkoutLogEntry> logs, List<WorkoutSession> sessions) async {
    final exported = await _readSignatures();
    final current = _dailySignatures(logs, sessions);
    final changed = current.keys
        .where((day) => current[day] != exported[day])
        .toList()
      ..sort();
    if (changed.isEmpty) return null;
    return ExportDateRange(
        DateTime.parse(changed.first), DateTime.parse(changed.last));
  }

  Future<void> _recordSignatures(
      List<WorkoutLogEntry> logs, List<WorkoutSession> sessions) async {
    final signatures = await _readSignatures();
    signatures.addAll(_dailySignatures(logs, sessions));
    await _storageService.writeMetadata(
        _exportSignaturesKey, jsonEncode(signatures));
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

  static void _validateSpreadsheetFile(File file, String filename) {
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

  static Map<String, List<String>> _requiredSpreadsheetHeaderGroups(
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

  static Set<String> _spreadsheetHeaderSet(List<Data?> headerRow) {
    return {
      for (final cell in headerRow)
        if (_cellText(cell).trim().isNotEmpty)
          _normalizeHeaderName(_cellText(cell)),
    };
  }

  static String _cellText(Data? cell) {
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

  static String _normalizeHeaderName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _writeWorkoutLogExport(
      Directory directory, List<WorkoutLogEntry> logs) async {
    final bytes = await compute(_encodeLogWorkbook, logs);
    await File(p.join(directory.path, 'workout_log.xlsx'))
        .writeAsBytes(bytes, flush: true);
  }

  Future<void> _writeWorkoutSessionExport(
      Directory directory, List<WorkoutSession> sessions) async {
    final bytes = await compute(_encodeSessionWorkbook, sessions);
    await File(p.join(directory.path, 'workout_session.xlsx'))
        .writeAsBytes(bytes, flush: true);
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
}

void _validateImportSheets(Map<String, String> files) {
  for (final entry in files.entries) {
    AppDataRepositoryImpl._validateSpreadsheetFile(
        File(entry.value), entry.key);
  }
}

List<int> _encodeWorkbook(String filename, List<List<CellValue?>> rows) {
  final schema = kTableSchemas[filename]!;
  final excel = Excel.createExcel();
  excel.rename(excel.getDefaultSheet()!, schema.sheetName);
  final sheet = excel[schema.sheetName];
  sheet.appendRow([
    ...schema.headers.map((h) => TextCellValue(h)),
    TextCellValue('workout_session_key')
  ]);
  for (final row in rows) {
    sheet.appendRow(row);
  }
  return excel.save()!;
}

List<int> _encodeLogWorkbook(List<WorkoutLogEntry> logs) =>
    _encodeWorkbook('workout_log.xlsx', [
      for (var i = 0; i < logs.length; i++)
        [
          IntCellValue(i + 1),
          TextCellValue(logs[i].date.toIso8601String().split('T').first),
          IntCellValue(logs[i].planId),
          IntCellValue(logs[i].exerciseId),
          IntCellValue(logs[i].setNumber),
          IntCellValue(logs[i].reps),
          DoubleCellValue(logs[i].weight),
          IntCellValue(logs[i].rir),
          TextCellValue(logs[i].storageSessionId),
        ],
    ]);

List<int> _encodeSessionWorkbook(List<WorkoutSession> sessions) =>
    _encodeWorkbook('workout_session.xlsx', [
      for (var i = 0; i < sessions.length; i++)
        [
          IntCellValue(i + 1),
          TextCellValue(sessions[i].date.toIso8601String().split('T').first),
          IntCellValue(sessions[i].planId),
          TextCellValue(sessions[i].fatigueLevel),
          IntCellValue(sessions[i].durationMinutes),
          TextCellValue(sessions[i].mood),
          TextCellValue(sessions[i].notes),
          TextCellValue(sessions[i].storageSessionId),
        ],
    ]);

List<int>? _mergeAncillarySheet(Map<String, String> paths) {
  final incoming = File(paths['incoming']!);
  final local = File(paths['local']!);
  if (!local.existsSync()) return incoming.readAsBytesSync();
  final schema = kTableSchemas[paths['filename']]!;
  final existingBook = Excel.decodeBytes(local.readAsBytesSync());
  final incomingBook = Excel.decodeBytes(incoming.readAsBytesSync());
  final existing = existingBook[schema.sheetName];
  final existingRows = existing.rows;
  final incomingRows = incomingBook[schema.sheetName].rows;
  final populated = existingRows
      .skip(1)
      .where((row) => row.any((cell) =>
          cell?.value != null && cell!.value.toString().trim().isNotEmpty))
      .toList();
  if (paths['filename'] == 'user.xlsx' && populated.isNotEmpty) return null;
  final signatures = populated
      .map((row) => row
          .skip(1)
          .map((cell) => cell?.value.toString() ?? '')
          .join('\u001f'))
      .toSet();
  var nextId = populated.fold<int>(0, (maxId, row) {
    final id = int.tryParse(row.first?.value.toString() ?? '') ?? 0;
    return id > maxId ? id : maxId;
  });
  final usedIds =
      populated.map((row) => row.first?.value.toString() ?? '').toSet();
  for (final row in incomingRows.skip(1)) {
    if (row.every((cell) =>
        cell?.value == null || cell!.value.toString().trim().isEmpty)) {
      continue;
    }
    final signature =
        row.skip(1).map((cell) => cell?.value.toString() ?? '').join('\u001f');
    if (!signatures.add(signature)) continue;
    final id = row.first?.value.toString() ?? '';
    if (paths['filename'] != 'body_metrics.xlsx' && usedIds.contains(id)) {
      continue;
    }
    final first =
        usedIds.contains(id) ? IntCellValue(++nextId) : row.first?.value;
    usedIds.add(first.toString());
    existing.appendRow([first, ...row.skip(1).map((cell) => cell?.value)]);
  }
  return existingBook.save();
}
