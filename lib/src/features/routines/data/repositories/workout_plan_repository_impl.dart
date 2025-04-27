import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_plan.dart';
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

}
