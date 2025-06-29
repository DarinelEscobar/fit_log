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
  List<Exercise>? _exerciseCache;
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
  Future<List<Exercise>> getAllExercises() async {
    if (_exerciseCache != null) return _exerciseCache!;

    final exFile = await _getOrCreateFile('exercise.xlsx');
    final exSheet =
        Excel.decodeBytes(await exFile.readAsBytes())[kTableSchemas['exercise.xlsx']!.sheetName];
    if (exSheet == null) return [];

    _exerciseCache = exSheet.rows
        .skip(1)
        .where((row) => row.isNotEmpty)
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
    return _exerciseCache!;
  }

  @override
  Future<List<Exercise>> getSimilarExercises(int exerciseId) async {
    final all = await getAllExercises();
    final base = all.firstWhere((e) => e.id == exerciseId, orElse: () => Exercise(id: 0, name: '', description: '', category: '', mainMuscleGroup: ''));
    if (base.id == 0) return [];
    return all
        .where((e) => e.id != exerciseId && (e.category == base.category || e.mainMuscleGroup == base.mainMuscleGroup))
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
  Future<void> addExerciseToPlan(int planId, PlanExerciseDetail detail) async {
    final file = await _getOrCreateFile('plan_exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['plan_exercise.xlsx']!.sheetName]!;

    sheet.appendRow([
      IntCellValue(planId),
      IntCellValue(detail.exerciseId),
      IntCellValue(detail.sets),
      IntCellValue(detail.reps),
      DoubleCellValue(detail.weight),
      IntCellValue(detail.restSeconds),
      TextCellValue(''),
    ]);

    await file.writeAsBytes(excel.save()!);
  }

  @override
  Future<void> updateExerciseInPlan(int planId, PlanExerciseDetail detail) async {
    final file = await _getOrCreateFile('plan_exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['plan_exercise.xlsx']!.sheetName]!;

    for (var row in sheet.rows.skip(1)) {
      if (row.isNotEmpty && _cast<int>(row[0]) == planId && _cast<int>(row[1]) == detail.exerciseId) {
        row[2]?.value = IntCellValue(detail.sets);
        row[3]?.value = IntCellValue(detail.reps);
        row[4]?.value = DoubleCellValue(detail.weight);
        row[5]?.value = IntCellValue(detail.restSeconds);
      }
    }

    await file.writeAsBytes(excel.save()!);
  }

  @override
  Future<void> deleteExerciseFromPlan(int planId, int exerciseId) async {
    final file = await _getOrCreateFile('plan_exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['plan_exercise.xlsx']!.sheetName]!;

    final rows = sheet.rows;
    for (var i = rows.length - 1; i >= 1; i--) {
      final r = rows[i];
      if (r.isNotEmpty && _cast<int>(r[0]) == planId && _cast<int>(r[1]) == exerciseId) {
        sheet.removeRow(i);
      }
    }

    await file.writeAsBytes(excel.save()!);
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
