import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../data/schema/schemas.dart';
import '../../domain/repositories/app_data_repository.dart';

class AppDataRepositoryImpl implements AppDataRepository {
  @override
  Future<File> exportData() async {
    final dir = await getApplicationDocumentsDirectory();
    final databaseDir = await getDatabasesPath();
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
}
