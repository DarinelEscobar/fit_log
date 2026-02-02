import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../data/create/initialize_xlsx.dart';
import '../../../../data/schema/schemas.dart';
import '../../domain/repositories/app_data_repository.dart';

class AppDataRepositoryImpl implements AppDataRepository {
  @override
  Future<File> exportData() async {
    final dir = await getApplicationDocumentsDirectory();
    final databaseDir = await getDatabasesPath();
    await _syncSqliteExports(dir, databaseDir);
    final archive = Archive();
    for (final filename in kTableSchemas.keys) {
      final file = File(p.join(dir.path, filename));
      await _addFileToArchive(archive, file, filename);
    }
    final databaseFile = File(p.join(databaseDir, 'fit_log.db'));
    await _addFileToArchive(archive, databaseFile, p.basename(databaseFile.path));
    final encoder = ZipEncoder();
    final data = encoder.encode(archive);
    final outFile = File(p.join(dir.path, 'fitlog_backup.zip'));
    if (data != null) await outFile.writeAsBytes(data, flush: true);

    // Try to also copy the backup to external storage so the user can access it
    try {
      if (await Permission.storage.request().isGranted) {
        final downloads = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (downloads != null && downloads.isNotEmpty) {
          final extFile = File(p.join(downloads.first.path, 'fitlog_backup.zip'));
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
      final outFile = File(p.join(dir.path, p.basename(file.path)));
      await outFile.writeAsBytes(await file.readAsBytes(), flush: true);
      return;
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final archived in archive.files) {
      if (!archived.isFile) continue;
      final name = p.basename(archived.name);
      final outPath = name == 'fit_log.db' ? p.join(databaseDir, name) : p.join(dir.path, name);
      final outFile = File(outPath);
      await outFile.writeAsBytes(archived.content as List<int>, flush: true);
    }
  }

  Future<void> _addFileToArchive(Archive archive, File file, String archiveName) async {
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(archiveName, bytes.length, bytes));
  }

  Future<void> _syncSqliteExports(Directory dir, String databaseDir) async {
    final dbPath = p.join(databaseDir, 'fit_log.db');
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) return;

    await XlsxInitializer.ensureXlsxFilesExist();
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(readOnly: true),
    );

    try {
      await _writeLogsToExcel(db, dir);
      await _writeSessionsToExcel(db, dir);
    } finally {
      await db.close();
    }
  }

  Future<void> _writeLogsToExcel(Database db, Directory dir) async {
    final schema = kTableSchemas['workout_log.xlsx'];
    if (schema == null) return;
    final rows = await db.query('workout_logs', orderBy: 'id ASC');
    final excel = _buildExcelForSchema(schema, rows, [
      'id',
      'date',
      'plan_id',
      'exercise_id',
      'set_number',
      'reps',
      'weight',
      'rir',
    ]);
    final bytes = excel.save();
    if (bytes == null) return;
    final file = File(p.join(dir.path, 'workout_log.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _writeSessionsToExcel(Database db, Directory dir) async {
    final schema = kTableSchemas['workout_session.xlsx'];
    if (schema == null) return;
    final rows = await db.query('workout_sessions', orderBy: 'id ASC');
    final excel = _buildExcelForSchema(schema, rows, [
      'id',
      'date',
      'plan_id',
      'fatigue_level',
      'duration_minutes',
      'mood',
      'notes',
    ]);
    final bytes = excel.save();
    if (bytes == null) return;
    final file = File(p.join(dir.path, 'workout_session.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
  }

  Excel _buildExcelForSchema(
    TableSchema schema,
    List<Map<String, Object?>> rows,
    List<String> columnOrder,
  ) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, schema.sheetName);
    }
    final sheet = excel[schema.sheetName];
    final headerRow = schema.headers
        .map<CellValue?>((header) => TextCellValue(header))
        .toList();
    sheet.appendRow(headerRow);
    for (final row in rows) {
      final cells = columnOrder.map<CellValue?>((column) {
        return _toCellValue(row[column]);
      }).toList();
      sheet.appendRow(cells);
    }
    return excel;
  }

  CellValue _toCellValue(Object? value) {
    if (value == null) return const TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    return TextCellValue(value.toString());
  }
}
