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

  final WorkoutStorageService _storageService;

  @override
  Future<File> exportData() async {
    final dir = await getApplicationDocumentsDirectory();
    final databaseDir = await getDatabasesPath();
    await _storageService.exportRoutineRuntimeToXlsxFiles(dir);
    await _syncWorkoutExports(dir);
    final archive = Archive();
    for (final filename in kTableSchemas.keys) {
      final file = File(p.join(dir.path, filename));
      await _addFileToArchive(archive, file, filename);
    }
    final databaseFile = File(p.join(databaseDir, 'fit_log.db'));
    await _addFileToArchive(
        archive, databaseFile, p.basename(databaseFile.path));
    final encoder = ZipEncoder();
    final data = encoder.encode(archive);
    final outFile = File(p.join(dir.path, 'fitlog_backup.zip'));
    if (data != null) await outFile.writeAsBytes(data, flush: true);

    // Try to also copy the backup to external storage so the user can access it
    try {
      if (await Permission.storage.request().isGranted) {
        final downloads = await getExternalStorageDirectories(
            type: StorageDirectory.downloads);
        if (downloads != null && downloads.isNotEmpty) {
          final extFile =
              File(p.join(downloads.first.path, 'fitlog_backup.zip'));
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
      await _importSpreadsheet(file, dir);
      return;
    }

    await _storageService.close();

    var restoredDatabase = false;
    var restoredRoutineSheet = false;
    var restoredLogSheet = false;
    var restoredSessionSheet = false;

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final archived in archive.files) {
      if (!archived.isFile) {
        continue;
      }

      final name = p.basename(archived.name);
      final outPath = name == 'fit_log.db'
          ? p.join(databaseDir, name)
          : p.join(dir.path, name);
      final outFile = File(outPath);
      await outFile.writeAsBytes(
        archived.content as List<int>,
        flush: true,
      );

      if (name == 'fit_log.db') {
        restoredDatabase = true;
      } else if (name == 'workout_plan.xlsx' ||
          name == 'exercise.xlsx' ||
          name == 'plan_exercise.xlsx') {
        restoredRoutineSheet = true;
      } else if (name == 'workout_log.xlsx') {
        restoredLogSheet = true;
      } else if (name == 'workout_session.xlsx') {
        restoredSessionSheet = true;
      }
    }

    await _storageService.reopenIfNeeded();

    if (!restoredDatabase) {
      if (restoredLogSheet) {
        await _storageService.replaceWorkoutLogsFromCurrentXlsxFiles();
      }
      if (restoredSessionSheet) {
        await _storageService.replaceWorkoutSessionsFromCurrentXlsxFiles();
      }
    }

    if (restoredRoutineSheet || restoredDatabase) {
      await _storageService.warmUpRoutineRuntimeCache(
        force: !restoredDatabase,
      );
      await _storageService.exportRoutineRuntimeToXlsxFiles(dir);
    }
  }

  Future<void> _addFileToArchive(
      Archive archive, File file, String archiveName) async {
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

  Future<void> _importSpreadsheet(File file, Directory directory) async {
    final filename = p.basename(file.path);
    final outFile = File(p.join(directory.path, filename));
    await outFile.writeAsBytes(await file.readAsBytes(), flush: true);

    switch (filename) {
      case 'workout_plan.xlsx':
      case 'exercise.xlsx':
      case 'plan_exercise.xlsx':
        await _storageService.warmUpRoutineRuntimeCache(force: true);
        await _storageService.exportRoutineRuntimeToXlsxFiles(directory);
        return;
      case 'workout_log.xlsx':
        await _storageService.replaceWorkoutLogsFromCurrentXlsxFiles();
        return;
      case 'workout_session.xlsx':
        await _storageService.replaceWorkoutSessionsFromCurrentXlsxFiles();
        return;
      default:
        return;
    }
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
        schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList());
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
        schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList());
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
