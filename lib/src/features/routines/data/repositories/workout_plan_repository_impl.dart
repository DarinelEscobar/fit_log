import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workout_plan_repository.dart';
import '../../../../data/schema/schemas.dart';

class WorkoutPlanRepositoryImpl implements WorkoutPlanRepository {
  Future<File> _getOrCreateFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');

    if (!await file.exists()) {
      final schema = kTableSchemas[filename]!;
      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.rename(defaultSheet, schema.sheetName);
      }
      excel[schema.sheetName]!.appendRow(
        schema.headers.map<CellValue?>((e) => TextCellValue(e)).toList(),
      );
      final bytes = excel.save();
      if (bytes != null) await file.writeAsBytes(bytes);
    }
    return file;
  }

  int _getLastId(Sheet sheet) {
    for (var i = sheet.rows.length - 1; i >= 1; i--) {
      final val = sheet.rows[i][0]?.value;
      if (val != null) return int.tryParse(val.toString()) ?? 0;
    }
    return 0;
  }
  T? _cast<T>(Data? cell) {
    final v = cell?.value;
    if (v == null) return null;
    if (v is T) return v as T;
    if (T == int) return int.tryParse(v.toString()) as T?;
    if (T == double) return double.tryParse(v.toString()) as T?;
    if (T == String) return v.toString() as T;
    return null;
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    final file = await _getOrCreateFile('workout_plan.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_plan.xlsx']!.sheetName];
    if (sheet == null) return [];

    return sheet.rows
        .skip(1)
        .where((row) => row.isNotEmpty)
        .map((row) {
          final id = int.tryParse(row[0]?.value.toString() ?? '0') ?? 0;
          final name = row[1]?.value.toString() ?? '';
          final frequency = row[2]?.value.toString() ?? '';
          return WorkoutPlan(id: id, name: name, frequency: frequency);
        })
        .toList();
  }

  @override
  Future<void> createWorkoutPlan(String name, String frequency) async {
    final file = await _getOrCreateFile('workout_plan.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_plan.xlsx']!.sheetName]!;

    sheet.appendRow([
      IntCellValue(_getLastId(sheet) + 1),
      TextCellValue(name),
      TextCellValue(frequency),
    ]);
    await file.writeAsBytes(excel.save()!);
  }

  @override
  Future<List<Exercise>> getExercisesForPlan(int planId) async {
    final peFile = await _getOrCreateFile('plan_exercise.xlsx');
    final exFile = await _getOrCreateFile('exercise.xlsx');

    final peSheet = Excel.decodeBytes(await peFile.readAsBytes())[
        kTableSchemas['plan_exercise.xlsx']!.sheetName];
    final exSheet = Excel.decodeBytes(await exFile.readAsBytes())[
        kTableSchemas['exercise.xlsx']!.sheetName];

    if (peSheet == null || exSheet == null) return [];

    final exerciseIdsForPlan = peSheet.rows
        .skip(1)
        .where((row) => row.isNotEmpty && _cast<int>(row[0]) == planId)
        .map((row) => _cast<int>(row[1]))
        .whereType<int>()
        .toSet();

    return exSheet.rows
        .skip(1)
        .where((row) =>
            row.isNotEmpty &&
            exerciseIdsForPlan
                .contains(int.tryParse(row[0]?.value.toString() ?? '')))
        .map(
          (row) => Exercise(
            id: _cast<int>(row[0]) ?? 0,
            name: _cast<String>(row[1]) ?? '',
            description: _cast<String>(row[2]) ?? '',
            category: _cast<String>(row[3]) ?? '',
            mainMuscleGroup: _cast<String>(row[4]) ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId) async {
    final peFile = await _getOrCreateFile('plan_exercise.xlsx');
    final exFile = await _getOrCreateFile('exercise.xlsx');

    final peSheet = Excel.decodeBytes(await peFile.readAsBytes())[
        kTableSchemas['plan_exercise.xlsx']!.sheetName];
    final exSheet = Excel.decodeBytes(await exFile.readAsBytes())[
        kTableSchemas['exercise.xlsx']!.sheetName];

    if (peSheet == null || exSheet == null) return [];

    final mapIdName = {
      for (var r in exSheet.rows.skip(1))
        if (r.isNotEmpty) _cast<int>(r[0])!: r[1]?.value.toString() ?? '',
    };
    final mapIdDescription = {
      for (var r in exSheet.rows.skip(1))
        if (r.isNotEmpty) _cast<int>(r[0])!: r[2]?.value.toString() ?? '',
    };

    return peSheet.rows
        .skip(1)
        .where((r) =>
            r.isNotEmpty &&
            _cast<int>(r[0]) == planId)
        .map((r) {
          final id = _cast<int>(r[1]) ?? 0;
          return PlanExerciseDetail(
            exerciseId: id,
            name: mapIdName[id] ?? 'Unknown',
            description: mapIdDescription[id] ?? '',
            sets: _cast<int>(r[2]) ?? 0,
            reps: _cast<int>(r[3]) ?? 0,
            weight: _cast<double>(r[4]) ?? 0,
            restSeconds: _cast<int>(r[5]) ?? 0,
          );
        })
        .toList();
  }


  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {
    if (logs.isEmpty) return;

    final file = await _getOrCreateFile('workout_log.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_log.xlsx']!.sheetName]!;

    var id = _getLastId(sheet) + 1;
    for (final l in logs) {
      sheet.appendRow([
        IntCellValue(id++),
        TextCellValue(l.date.toIso8601String().split('T').first),
        IntCellValue(l.planId),
        IntCellValue(l.exerciseId),
        IntCellValue(l.setNumber),
        IntCellValue(l.reps),
        DoubleCellValue(l.weight),
        IntCellValue(l.rir),
      ]);
    }
    await file.writeAsBytes(excel.save()!);
  }

  @override
  Future<void> saveWorkoutSession(WorkoutSession s) async {
    final file = await _getOrCreateFile('workout_session.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_session.xlsx']!.sheetName]!;

    sheet.appendRow([
      IntCellValue(_getLastId(sheet) + 1),
      TextCellValue(s.date.toIso8601String().split('T').first),
      IntCellValue(s.planId),
      TextCellValue(s.fatigueLevel),
      IntCellValue(s.durationMinutes),
      TextCellValue(s.mood),
      TextCellValue(s.notes),
    ]);
    await file.writeAsBytes(excel.save()!);
  }
}
