import 'dart:convert';
import '../domain/entities/exercise.dart';
import '../domain/entities/plan_exercise_detail.dart';

class RoutineJsonCodec {
  final JsonEncoder _encoder = const JsonEncoder.withIndent('  ');

  String detailJson(PlanExerciseDetail detail) => _encoder.convert({
        'sets': detail.sets,
        'reps': detail.reps,
        'kg': detail.weight,
        'rest': detail.restSeconds,
        'rir': detail.rir,
        'tempo': detail.tempo,
      });

  String exerciseJson(Exercise exercise) => _encoder.convert({
        'name': exercise.name,
        'description': exercise.description,
        'category': exercise.category,
        'mainMuscle': exercise.mainMuscleGroup,
      });

  PlanExerciseDetail? parseDetailJson(PlanExerciseDetail base, String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      return base.copyWith(
        sets: _asInt(decoded['sets']) ?? base.sets,
        reps: _asInt(decoded['reps']) ?? base.reps,
        weight: _asDouble(decoded['kg']) ?? base.weight,
        restSeconds: _asInt(decoded['rest']) ?? base.restSeconds,
        rir: _asInt(decoded['rir']) ?? base.rir,
        tempo: decoded['tempo']?.toString() ?? base.tempo,
      );
    } on FormatException {
      return null;
    }
  }

  Exercise? parseExerciseJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      final name = decoded['name']?.toString().trim() ?? '';
      final description = decoded['description']?.toString().trim() ?? '';
      final category = decoded['category']?.toString().trim() ?? '';
      final mainMuscle = decoded['mainMuscle']?.toString().trim() ?? '';
      if (name.isEmpty) return null;
      return Exercise(
        id: 0,
        name: name,
        description: description,
        category: category,
        mainMuscleGroup: mainMuscle,
      );
    } on FormatException {
      return null;
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
