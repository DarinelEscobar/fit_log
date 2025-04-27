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
  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/workout_plan.xlsx');

    if (!await file.exists()) return [];

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel[kTableSchemas['workout_plan.xlsx']!.sheetName];

    if (sheet == null) return [];

    return sheet.rows.skip(1).where((row) => row.isNotEmpty).map(
      (row) {
        final id = row[0]?.value.toString() ?? '0';
        final name = row[1]?.value.toString() ?? '';
        final frequency = row[2]?.value.toString() ?? '';
        return WorkoutPlan(id: int.tryParse(id) ?? 0, name: name, frequency: frequency);
      },
    ).toList();
  }

  @override
  Future<List<Exercise>> getExercisesForPlan(int planId) async {
    final dir = await getApplicationDocumentsDirectory();

    final planExerciseFile = File('${dir.path}/plan_exercise.xlsx');
    final exerciseFile = File('${dir.path}/exercise.xlsx');

    if (!await planExerciseFile.exists() || !await exerciseFile.exists()) return [];

    final planExerciseBytes = await planExerciseFile.readAsBytes();
    final exerciseBytes = await exerciseFile.readAsBytes();

    final planExerciseExcel = Excel.decodeBytes(planExerciseBytes);
    final exerciseExcel = Excel.decodeBytes(exerciseBytes);

    final planExerciseSheet = planExerciseExcel[kTableSchemas['plan_exercise.xlsx']!.sheetName];
    final exerciseSheet = exerciseExcel[kTableSchemas['exercise.xlsx']!.sheetName];

    if (planExerciseSheet == null || exerciseSheet == null) return [];

    final exerciseIdsForPlan = planExerciseSheet.rows.skip(1)
      .where((row) => row.isNotEmpty && (row[0]?.value == planId))
      .map((row) => row[1]?.value as int)
      .toSet();

    return exerciseSheet.rows.skip(1)
      .where((row) => row.isNotEmpty && exerciseIdsForPlan.contains(row[0]?.value))
      .map((row) {
        return Exercise(
          id: row[0]?.value as int,
          name: row[1]?.value.toString() ?? '',
          description: row[2]?.value.toString() ?? '',
          category: row[3]?.value.toString() ?? '',
          mainMuscleGroup: row[4]?.value.toString() ?? '',
        );
      }).toList();
  }

  @override
  Future<void> createWorkoutPlan(String name, String frequency) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/workout_plan.xlsx');

    if (!await file.exists()) {
      throw Exception('El archivo workout_plan.xlsx no existe');
    }

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel[kTableSchemas['workout_plan.xlsx']!.sheetName];

    if (sheet == null) {
      throw Exception('La hoja WorkoutPlan no existe');
    }

    final ids = sheet.rows.skip(1)
      .where((row) => row.isNotEmpty && row[0]?.value != null)
      .map((row) => row[0]!.value as int)
      .toList();

    final nextId = ids.isEmpty ? 1 : (ids.reduce((a, b) => a > b ? a : b) + 1);

    sheet.appendRow([nextId, name, frequency]);

    final newFileBytes = excel.save();
    if (newFileBytes != null) {
      await file.writeAsBytes(newFileBytes);
    }
  }


  @override
  Future<List<PlanExerciseDetail>> getPlanExerciseDetails(int planId) async {
    final dir = await getApplicationDocumentsDirectory();
    final peFile = File('${dir.path}/plan_exercise.xlsx');
    final exFile = File('${dir.path}/exercise.xlsx');
    if (!await peFile.exists() || !await exFile.exists()) return [];
    final peSheet =
        Excel.decodeBytes(await peFile.readAsBytes())[kTableSchemas['plan_exercise.xlsx']!.sheetName];
    final exSheet =
        Excel.decodeBytes(await exFile.readAsBytes())[kTableSchemas['exercise.xlsx']!.sheetName];
    if (peSheet == null || exSheet == null) return [];
    final mapIdName = {
      for (var r in exSheet.rows.skip(1))
        if (r.isNotEmpty) r[0]!.value as int: r[1]!.value.toString()
    };
    return peSheet.rows.skip(1).where((r) => r.isNotEmpty && r[0]!.value == planId).map((r) {
      final id = r[1]!.value as int;
      return PlanExerciseDetail(
        exerciseId: id,
        name: mapIdName[id] ?? 'Unknown',
        sets: r[2]!.value as int,
        reps: r[3]!.value as int,
        weight: (r[4]!.value as num).toDouble(),
      );
    }).toList();
  }


  @override
  Future<void> saveWorkoutLogs(List<WorkoutLogEntry> logs) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/workout_log.xlsx');
    if (!await file.exists()) throw Exception('workout_log.xlsx not found');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_log.xlsx']!.sheetName];
    if (sheet == null) throw Exception('sheet missing');
    final ids = sheet.rows.skip(1).where((r) => r.isNotEmpty).map((r) => r[0]!.value as int);
    var nextId = ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
    for (final l in logs) {
      sheet.appendRow([
        nextId++,
        '${l.date.year}-${l.date.month.toString().padLeft(2, '0')}-${l.date.day.toString().padLeft(2, '0')}',
        l.planId,
        l.exerciseId,
        l.setNumber,
        l.reps,
        l.weight,
        l.rir
      ]);
    }
    await file.writeAsBytes(excel.save()!);
  }

  @override
  Future<void> saveWorkoutSession(WorkoutSession s) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/workout_session.xlsx');
    if (!await file.exists()) throw Exception('workout_session.xlsx not found');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['workout_session.xlsx']!.sheetName];
    if (sheet == null) throw Exception('sheet missing');
    final ids = sheet.rows.skip(1).where((r) => r.isNotEmpty).map((r) => r[0]!.value as int);
    final sessionId = ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
    sheet.appendRow([
      sessionId,
      '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}',
      s.planId,
      s.fatigueLevel,
      s.durationMinutes,
      s.mood,
      s.notes
    ]);
    await file.writeAsBytes(excel.save()!);
  }

}
