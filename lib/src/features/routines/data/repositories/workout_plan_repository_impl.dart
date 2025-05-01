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
  // ───────────────────────── helpers internos ────────────────────────
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
      excel[schema.sheetName]!.appendRow(schema.headers);
      final bytes = excel.save();
      if (bytes != null) await file.writeAsBytes(bytes);
    }
    return file;
  }

  int _getLastId(Sheet sheet) {
    // Busca desde la última fila válida hacia arriba y devuelve el último id
    for (var i = sheet.rows.length - 1; i >= 1; i--) {
      final val = sheet.rows[i][0]?.value;
      if (val != null) return int.tryParse(val.toString()) ?? 0;
    }
    return 0;
  }

  // ────────────────────────── Workout Plans ──────────────────────────
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

    sheet.appendRow([_getLastId(sheet) + 1, name, frequency]);
    await file.writeAsBytes(excel.save()!);
  }

  // ────────────────────────── Exercises x Plan ───────────────────────
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
        .where((row) => row.isNotEmpty && (row[0]?.value == planId))
        .map((row) => row[1]?.value as int)
        .toSet();

    return exSheet.rows
        .skip(1)
        .where((row) =>
            row.isNotEmpty && exerciseIdsForPlan.contains(row[0]?.value))
        .map(
          (row) => Exercise(
            id: row[0]?.value as int,
            name: row[1]?.value.toString() ?? '',
            description: row[2]?.value.toString() ?? '',
            category: row[3]?.value.toString() ?? '',
            mainMuscleGroup: row[4]?.value.toString() ?? '',
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
        if (r.isNotEmpty) r[0]!.value as int: r[1]!.value.toString(),
    };

    return peSheet.rows
        .skip(1)
        .where((r) => r.isNotEmpty && r[0]!.value == planId)
        .map((r) {
          final id = r[1]!.value as int;
          return PlanExerciseDetail(
            exerciseId: id,
            name: mapIdName[id] ?? 'Unknown',
            sets: r[2]!.value as int,
            reps: r[3]!.value as int,
            weight: (r[4]!.value as num).toDouble(),
          );
        })
        .toList();
  }

  // ──────────────────────────── Logs y Sesiones ──────────────────────
  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {
    if (logs.isEmpty) return;

    final file = await _getOrCreateFile('workout_log.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_log.xlsx']!.sheetName]!;

    var id = _getLastId(sheet) + 1;
    for (final l in logs) {
      sheet.appendRow([
        id++,
        l.date.toIso8601String().split('T').first,
        l.planId,
        l.exerciseId,
        l.setNumber,
        l.reps,
        l.weight,
        l.rir,
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
      _getLastId(sheet) + 1,
      s.date.toIso8601String().split('T').first,
      s.planId,
      s.fatigueLevel,
      s.durationMinutes,
      s.mood,
      s.notes,
    ]);
    await file.writeAsBytes(excel.save()!);
  }
}
