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
    var maxId = 0;
    for (var i = 1; i < sheet.rows.length; i++) {
      final val = sheet.rows[i][0]?.value;
      final id = int.tryParse(val?.toString() ?? '');
      if (id != null && id > maxId) maxId = id;
    }
    return maxId;
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

  int _findInsertIndex(Sheet sheet, int planId, int position) {
    int insertIndex = sheet.rows.length;
    int current = 0;
    for (var i = 1; i < sheet.rows.length; i++) {
      final r = sheet.rows[i];
      if (r.isNotEmpty && _cast<int>(r[0]) == planId) {
        if (current == position) {
          insertIndex = i;
          break;
        }
        current++;
      }
    }
    return insertIndex;
  }

  Future<void> _normalizeExerciseIds() async {
    final file = await _getOrCreateFile('exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['exercise.xlsx']!.sheetName]!;

    final seen = <int>{};
    var maxId = _getLastId(sheet);
    var changed = false;

    for (var i = 1; i < sheet.rows.length; i++) {
      final id = _cast<int>(sheet.rows[i][0]);
      if (id == null) continue;
      if (seen.contains(id)) {
        maxId++;
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i),
          IntCellValue(maxId),
        );
        changed = true;
      } else {
        seen.add(id);
        if (id > maxId) maxId = id;
      }
    }

    if (changed) {
      await file.writeAsBytes(excel.save()!);
      _exerciseCache = null;
    }
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
    await _normalizeExerciseIds();
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

    await _normalizeExerciseIds();
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
  Future<void> createExercise(
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) async {
    await _normalizeExerciseIds();
    final exFile = await _getOrCreateFile('exercise.xlsx');
    final excel = Excel.decodeBytes(await exFile.readAsBytes());
    final sheet = excel[kTableSchemas['exercise.xlsx']!.sheetName]!;

    sheet.appendRow([
      IntCellValue(_getLastId(sheet) + 1),
      TextCellValue(name),
      TextCellValue(description),
      TextCellValue(category),
      TextCellValue(mainMuscleGroup),
    ]);

    await exFile.writeAsBytes(excel.save()!);
    _exerciseCache = null; // reset cache
  }

  @override
  Future<void> updateExercise(
    int id,
    String name,
    String description,
    String category,
    String mainMuscleGroup,
  ) async {
    await _normalizeExerciseIds();
    final file = await _getOrCreateFile('exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['exercise.xlsx']!.sheetName]!;

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isNotEmpty && _cast<int>(row[0]) == id) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i),
          TextCellValue(name),
        );
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i),
          TextCellValue(description),
        );
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i),
          TextCellValue(category),
        );
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i),
          TextCellValue(mainMuscleGroup),
        );
        break;
      }
    }

    await file.writeAsBytes(excel.save()!);
    _exerciseCache = null; // reset cache
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
    await _normalizeExerciseIds();
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
  Future<void> addExerciseToPlan(
    int planId,
    PlanExerciseDetail detail, {
    int? position,
  }) async {
    final file = await _getOrCreateFile('plan_exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['plan_exercise.xlsx']!.sheetName]!;

    // Collect current rows for this plan and remember the first index
    final planRows = <List<Data?>>[];
    int? firstIndex;
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isNotEmpty && _cast<int>(row[0]) == planId) {
        firstIndex ??= i;
        planRows.add(row);
      }
    }

    // Remove existing plan rows
    for (var i = sheet.rows.length - 1; i >= 1; i--) {
      final row = sheet.rows[i];
      if (row.isNotEmpty && _cast<int>(row[0]) == planId) {
        sheet.removeRow(i);
      }
    }

    // Convert to detail objects
    final details = planRows
        .map(
          (r) => PlanExerciseDetail(
            exerciseId: _cast<int>(r[1]) ?? 0,
            name: '',
            description: '',
            sets: _cast<int>(r[2]) ?? 0,
            reps: _cast<int>(r[3]) ?? 0,
            weight: _cast<double>(r[4]) ?? 0,
            restSeconds: _cast<int>(r[5]) ?? 0,
          ),
        )
        .toList();

    final existingIndex =
        details.indexWhere((d) => d.exerciseId == detail.exerciseId);
    if (existingIndex != -1) {
      details[existingIndex] = detail;
      if (position != null) {
        final item = details.removeAt(existingIndex);
        details.insert(position.clamp(0, details.length), item);
      }
    } else {
      final insertPos = (position ?? details.length).clamp(0, details.length);
      details.insert(insertPos, detail);
    }

    final newRows = details
        .map(
          (d) => [
            IntCellValue(planId),
            IntCellValue(d.exerciseId),
            IntCellValue(d.sets),
            IntCellValue(d.reps),
            DoubleCellValue(d.weight),
            IntCellValue(d.restSeconds),
            TextCellValue(''),
          ],
        )
        .toList();

    final start = firstIndex ?? sheet.rows.length;
    for (var i = 0; i < newRows.length; i++) {
      sheet.insertRowIterables(newRows[i], start + i);
    }

    await file.writeAsBytes(excel.save()!);
  }

  @override
  Future<void> updateExerciseInPlan(int planId, PlanExerciseDetail detail) async {
    final file = await _getOrCreateFile('plan_exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['plan_exercise.xlsx']!.sheetName]!;

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isNotEmpty &&
          _cast<int>(row[0]) == planId &&
          _cast<int>(row[1]) == detail.exerciseId) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i),
          IntCellValue(detail.sets),
        );
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i),
          IntCellValue(detail.reps),
        );
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i),
          DoubleCellValue(detail.weight),
        );
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i),
          IntCellValue(detail.restSeconds),
        );
        break;
      }
    }

    await file.writeAsBytes(excel.save()!);
  }

  @override
  Future<void> deleteExerciseFromPlan(int planId, int exerciseId) async {
    final file = await _getOrCreateFile('plan_exercise.xlsx');
    final excel = Excel.decodeBytes(await file.readAsBytes());
    final sheet = excel[kTableSchemas['plan_exercise.xlsx']!.sheetName]!;

    for (var i = sheet.rows.length - 1; i >= 1; i--) {
      final r = sheet.rows[i];
      if (r.isNotEmpty &&
          _cast<int>(r[0]) == planId &&
          _cast<int>(r[1]) == exerciseId) {
        sheet.removeRow(i);
        break;
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
