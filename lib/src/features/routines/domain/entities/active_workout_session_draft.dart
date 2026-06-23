import 'exercise.dart';
import 'plan_exercise_detail.dart';
import 'workout_log_entry.dart';
import 'workout_plan.dart';

class ActiveWorkoutSessionDraft {
  const ActiveWorkoutSessionDraft({
    required this.plan,
    required this.startedAt,
    required this.updatedAt,
    required this.details,
    required this.exercises,
    required this.setCountsByExercise,
    required this.logs,
    required this.restEndsAtByExercise,
    required this.notes,
    this.energy,
    this.mood,
    this.expandedExerciseId,
  });

  final WorkoutPlan plan;
  final DateTime startedAt;
  final DateTime updatedAt;
  final String notes;
  final String? energy;
  final String? mood;
  final int? expandedExerciseId;
  final List<PlanExerciseDetail> details;
  final List<Exercise> exercises;
  final Map<int, int> setCountsByExercise;
  final List<WorkoutLogEntry> logs;
  final Map<int, DateTime> restEndsAtByExercise;

  Map<String, Object?> toJson() {
    return {
      'plan': {
        'id': plan.id,
        'name': plan.name,
        'frequency': plan.frequency,
        'isActive': plan.isActive,
      },
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'energy': energy,
      'mood': mood,
      'expandedExerciseId': expandedExerciseId,
      'details': details.map(_detailToJson).toList(growable: false),
      'exercises': exercises.map(_exerciseToJson).toList(growable: false),
      'setCountsByExercise': {
        for (final entry in setCountsByExercise.entries)
          '${entry.key}': entry.value,
      },
      'logs': logs.map(_logToJson).toList(growable: false),
      'restEndsAtByExercise': {
        for (final entry in restEndsAtByExercise.entries)
          '${entry.key}': entry.value.toIso8601String(),
      },
    };
  }

  static ActiveWorkoutSessionDraft? fromJson(Map<String, Object?> json) {
    final planJson = _asMap(json['plan']);
    if (planJson == null) {
      return null;
    }

    final startedAt = DateTime.tryParse(_asString(json['startedAt']));
    final updatedAt = DateTime.tryParse(_asString(json['updatedAt']));
    if (startedAt == null || updatedAt == null) {
      return null;
    }

    final plan = WorkoutPlan(
      id: _asInt(planJson['id']),
      name: _asString(planJson['name']),
      frequency: _asString(planJson['frequency']),
      isActive: _asBool(planJson['isActive']),
    );

    final details = _asList(json['details'])
        .map(_asMap)
        .whereType<Map<String, Object?>>()
        .map(_detailFromJson)
        .whereType<PlanExerciseDetail>()
        .toList(growable: false);

    if (details.isEmpty) {
      return null;
    }

    return ActiveWorkoutSessionDraft(
      plan: plan,
      startedAt: startedAt,
      updatedAt: updatedAt,
      notes: _asString(json['notes']),
      energy: _asNullableString(json['energy']),
      mood: _asNullableString(json['mood']),
      expandedExerciseId: _asNullableInt(json['expandedExerciseId']),
      details: details,
      exercises: _asList(json['exercises'])
          .map(_asMap)
          .whereType<Map<String, Object?>>()
          .map(_exerciseFromJson)
          .whereType<Exercise>()
          .toList(growable: false),
      setCountsByExercise: _intMap(json['setCountsByExercise']),
      logs: _asList(json['logs'])
          .map(_asMap)
          .whereType<Map<String, Object?>>()
          .map(_logFromJson)
          .whereType<WorkoutLogEntry>()
          .toList(growable: false),
      restEndsAtByExercise: _dateTimeMap(json['restEndsAtByExercise']),
    );
  }

  static Map<String, Object?> _detailToJson(PlanExerciseDetail detail) {
    return {
      'exerciseId': detail.exerciseId,
      'name': detail.name,
      'description': detail.description,
      'sets': detail.sets,
      'reps': detail.reps,
      'weight': detail.weight,
      'restSeconds': detail.restSeconds,
      'rir': detail.rir,
      'tempo': detail.tempo,
    };
  }

  static PlanExerciseDetail? _detailFromJson(Map<String, Object?> json) {
    final exerciseId = _asInt(json['exerciseId']);
    if (exerciseId <= 0) {
      return null;
    }
    return PlanExerciseDetail(
      exerciseId: exerciseId,
      name: _asString(json['name']),
      description: _asString(json['description']),
      sets: _asInt(json['sets']),
      reps: _asInt(json['reps']),
      weight: _asDouble(json['weight']),
      restSeconds: _asInt(json['restSeconds']),
      rir: _asInt(json['rir']),
      tempo: _asString(json['tempo']),
    );
  }

  static Map<String, Object?> _exerciseToJson(Exercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'description': exercise.description,
      'category': exercise.category,
      'mainMuscleGroup': exercise.mainMuscleGroup,
    };
  }

  static Exercise? _exerciseFromJson(Map<String, Object?> json) {
    final id = _asInt(json['id']);
    if (id <= 0) {
      return null;
    }
    return Exercise(
      id: id,
      name: _asString(json['name']),
      description: _asString(json['description']),
      category: _asString(json['category']),
      mainMuscleGroup: _asString(json['mainMuscleGroup']),
    );
  }

  static Map<String, Object?> _logToJson(WorkoutLogEntry log) {
    return {
      'date': log.date.toIso8601String(),
      'planId': log.planId,
      'exerciseId': log.exerciseId,
      'setNumber': log.setNumber,
      'reps': log.reps,
      'weight': log.weight,
      'rir': log.rir,
      'completed': log.completed,
    };
  }

  static WorkoutLogEntry? _logFromJson(Map<String, Object?> json) {
    final date = DateTime.tryParse(_asString(json['date']));
    final planId = _asInt(json['planId']);
    final exerciseId = _asInt(json['exerciseId']);
    final setNumber = _asInt(json['setNumber']);
    if (date == null || planId <= 0 || exerciseId <= 0 || setNumber <= 0) {
      return null;
    }
    return WorkoutLogEntry(
      date: date,
      planId: planId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      reps: _asInt(json['reps']),
      weight: _asDouble(json['weight']),
      rir: _asInt(json['rir']),
      completed: _asBool(json['completed']),
    );
  }

  static Map<String, Object?>? _asMap(Object? value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }

  static List<Object?> _asList(Object? value) {
    if (value is List) {
      return value.cast<Object?>();
    }
    return const [];
  }

  static Map<int, int> _intMap(Object? value) {
    final map = _asMap(value);
    if (map == null) {
      return const {};
    }
    return {
      for (final entry in map.entries)
        if (int.tryParse(entry.key) != null)
          int.parse(entry.key): _asInt(entry.value),
    };
  }

  static Map<int, DateTime> _dateTimeMap(Object? value) {
    final map = _asMap(value);
    if (map == null) {
      return const {};
    }
    return {
      for (final entry in map.entries)
        if (int.tryParse(entry.key) != null &&
            DateTime.tryParse(_asString(entry.value)) != null)
          int.parse(entry.key): DateTime.parse(_asString(entry.value)),
    };
  }

  static String _asString(Object? value) => value?.toString() ?? '';

  static String? _asNullableString(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    return _asInt(value);
  }

  static double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    return value?.toString().toLowerCase() == 'true';
  }
}
