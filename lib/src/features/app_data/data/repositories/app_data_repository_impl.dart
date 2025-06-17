import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../data/schema/schemas.dart';
import '../../domain/repositories/app_data_repository.dart';

class AppDataRepositoryImpl implements AppDataRepository {
  @override
  Future<File> exportData() async {
    final dir = await getApplicationDocumentsDirectory();
    final archive = Archive();
    for (final filename in kTableSchemas.keys) {
      final file = File(p.join(dir.path, filename));
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(filename, bytes.length, bytes));
      }
    }
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
    } catch (_) {
      // Ignore issues and return the internal file path
    }

    return outFile;
  }

  @override
  Future<void> importData(File file) async {
    final dir = await getApplicationDocumentsDirectory();
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
      final outPath = p.join(dir.path, name);
      final outFile = File(outPath);
      await outFile.writeAsBytes(archived.content as List<int>, flush: true);
    }
  }
}
