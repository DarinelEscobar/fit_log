import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    return outFile;
  }

  @override
  Future<void> importData(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final archived in archive.files) {
      if (!archived.isFile) continue;
      final outPath = p.join(dir.path, archived.name);
      final outFile = File(outPath);
      await outFile.writeAsBytes(archived.content as List<int>, flush: true);
    }
  }
}
