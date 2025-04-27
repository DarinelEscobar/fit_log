import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
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
        final id = row[0]?.value is SharedString ? (row[0]!.value as SharedString).toString() : row[0]?.value.toString();
        final name = row[1]?.value.toString() ?? '';
        final frequency = row[2]?.value.toString() ?? '';
        return WorkoutPlan(id: int.tryParse(id ?? '0') ?? 0, name: name, frequency: frequency);
      },
    ).toList();
  }
}
