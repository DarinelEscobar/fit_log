import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../data/schema/schemas.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/body_metric.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  Future<Excel?> _openSheet(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (!await file.exists()) return null;
    return Excel.decodeBytes(await file.readAsBytes());
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
  Future<UserProfile?> getUserProfile() async {
    final excel = await _openSheet('user.xlsx');
    if (excel == null) return null;
    final sheet = excel[kTableSchemas['user.xlsx']!.sheetName];
    if (sheet == null || sheet.rows.length < 2) return null;
    final row = sheet.rows[1];
    return UserProfile(
      id: _cast<int>(row[0]) ?? 0,
      age: _cast<int>(row[1]) ?? 0,
      gender: _cast<String>(row[2]) ?? '',
      weight: _cast<double>(row[3]) ?? 0,
      height: _cast<double>(row[4]) ?? 0,
      experienceLevel: _cast<String>(row[5]) ?? '',
      goal: _cast<String>(row[6]) ?? '',
      targetWeight: _cast<double>(row[7]) ?? 0,
      targetBodyFat: _cast<double>(row[8]) ?? 0,
      targetNeck: _cast<double>(row[9]) ?? 0,
      targetShoulders: _cast<double>(row[10]) ?? 0,
      targetChest: _cast<double>(row[11]) ?? 0,
      targetAbdomen: _cast<double>(row[12]) ?? 0,
      targetWaist: _cast<double>(row[13]) ?? 0,
      targetGlutes: _cast<double>(row[14]) ?? 0,
      targetThigh: _cast<double>(row[15]) ?? 0,
      targetCalf: _cast<double>(row[16]) ?? 0,
      targetArm: _cast<double>(row[17]) ?? 0,
      targetForearm: _cast<double>(row[18]) ?? 0,
    );
  }

  @override
  Future<List<BodyMetric>> getBodyMetrics() async {
    final excel = await _openSheet('body_metrics.xlsx');
    if (excel == null) return [];
    final sheet = excel[kTableSchemas['body_metrics.xlsx']!.sheetName];
    if (sheet == null) return [];
    return sheet.rows.skip(1).where((r) => r.isNotEmpty).map((r) {
      return BodyMetric(
        date: DateTime.tryParse(r[1]?.value.toString() ?? '') ?? DateTime.now(),
        weight: _cast<double>(r[2]) ?? 0,
        bodyFat: _cast<double>(r[3]) ?? 0,
        neck: _cast<double>(r[4]) ?? 0,
        shoulders: _cast<double>(r[5]) ?? 0,
        chest: _cast<double>(r[6]) ?? 0,
        abdomen: _cast<double>(r[7]) ?? 0,
        waist: _cast<double>(r[8]) ?? 0,
        glutes: _cast<double>(r[9]) ?? 0,
        thigh: _cast<double>(r[10]) ?? 0,
        calf: _cast<double>(r[11]) ?? 0,
        arm: _cast<double>(r[12]) ?? 0,
        forearm: _cast<double>(r[13]) ?? 0,
        age: _cast<int>(r[14]) ?? 0,
      );
    }).toList();
  }
}
