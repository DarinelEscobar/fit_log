import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../../../routines/domain/entities/workout_session.dart';
import '../../../../data/schema/schemas.dart';
import '../../domain/repositories/workout_history_repository.dart';

class WorkoutHistoryRepositoryImpl implements WorkoutHistoryRepository {
  Future<Excel?> _openSheet(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (!await file.exists()) return null;
    return Excel.decodeBytes(await file.readAsBytes());
  }

  @override
  Future<List<WorkoutSession>> getAllSessions() async {
    final excel = await _openSheet('workout_session.xlsx');
    if (excel == null) return [];
    final sheet = excel[kTableSchemas['workout_session.xlsx']!.sheetName];
    if (sheet == null) return [];
    return sheet.rows.skip(1).where((r) => r.isNotEmpty).map((r) {
      return WorkoutSession(
        planId: int.tryParse(r[2]?.value.toString() ?? '0') ?? 0,
        date: DateTime.tryParse(r[1]?.value.toString() ?? '') ?? DateTime.now(),
        fatigueLevel: r[3]?.value.toString() ?? '',
        durationMinutes: int.tryParse(r[4]?.value.toString() ?? '0') ?? 0,
        mood: r[5]?.value.toString() ?? '',
        notes: r[6]?.value.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<List<WorkoutLogEntry>> getAllLogs() async {
    final excel = await _openSheet('workout_log.xlsx');
    if (excel == null) return [];
    final sheet = excel[kTableSchemas['workout_log.xlsx']!.sheetName];
    if (sheet == null) return [];
    return sheet.rows.skip(1).where((r) => r.isNotEmpty).map((r) {
      return WorkoutLogEntry(
        date: DateTime.tryParse(r[1]?.value.toString() ?? '') ?? DateTime.now(),
        planId: int.tryParse(r[2]?.value.toString() ?? '0') ?? 0,
        exerciseId: int.tryParse(r[3]?.value.toString() ?? '0') ?? 0,
        setNumber: int.tryParse(r[4]?.value.toString() ?? '0') ?? 0,
        reps: int.tryParse(r[5]?.value.toString() ?? '0') ?? 0,
        weight: (double.tryParse(r[6]?.value.toString() ?? '0') ?? 0.0),
        rir: int.tryParse(r[7]?.value.toString() ?? '0') ?? 0,
      );
    }).toList();
  }
}
