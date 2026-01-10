import 'dart:convert';

class RoutineJsonPayload {
  final String? name;
  final List<RoutineJsonExercise> exercises;

  const RoutineJsonPayload({this.name, required this.exercises});
}

class RoutineJsonExercise {
  final String name;
  final int? sets;
  final int? reps;
  final int? rir;
  final double? weight;
  final int? restSeconds;

  const RoutineJsonExercise({
    required this.name,
    this.sets,
    this.reps,
    this.rir,
    this.weight,
    this.restSeconds,
  });
}

class RoutineJsonParser {
  RoutineJsonParser._();

  static RoutineJsonPayload parse(String source) {
    final decoded = jsonDecode(source);

    if (decoded is List) {
      return RoutineJsonPayload(exercises: _parseExercises(decoded));
    }

    if (decoded is Map<String, dynamic>) {
      final name = _readString(decoded, ['name', 'routine', 'title']);
      final exercisesRaw =
          decoded['exercises'] ?? decoded['workout'] ?? decoded['items'];
      if (exercisesRaw is! List) {
        throw const FormatException('Missing "exercises" array.');
      }
      return RoutineJsonPayload(
        name: name?.trim().isEmpty ?? true ? null : name,
        exercises: _parseExercises(exercisesRaw),
      );
    }

    throw const FormatException('JSON must be an object or array.');
  }

  static List<RoutineJsonExercise> _parseExercises(List<dynamic> items) {
    if (items.isEmpty) {
      throw const FormatException('The exercises list cannot be empty.');
    }

    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Each exercise must be an object.');
      }
      final name = _readString(item, ['name', 'exercise']);
      if (name == null || name.trim().isEmpty) {
        throw const FormatException('Each exercise needs a "name".');
      }
      return RoutineJsonExercise(
        name: name.trim(),
        sets: _readInt(item, ['sets', 'set']),
        reps: _readInt(item, ['reps', 'rep']),
        rir: _readInt(item, ['rir']),
        weight: _readDouble(item, ['kg', 'weight', 'load']),
        restSeconds: _readInt(item, ['restSeconds', 'rest', 'rest_seconds']),
      );
    }).toList();
  }

  static String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is double) return value.round();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }
}
