import 'package:flutter/material.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';

class RoutineEditorDraft {
  RoutineEditorDraft({
    required this.originalExercise,
    required this.originalDetail,
  })  : nameController = TextEditingController(text: originalExercise.name),
        categoryController =
            TextEditingController(text: originalExercise.category),
        mainMuscleController =
            TextEditingController(text: originalExercise.mainMuscleGroup),
        descriptionController =
            TextEditingController(text: originalExercise.description),
        setsController =
            TextEditingController(text: originalDetail.sets.toString()),
        repsController =
            TextEditingController(text: originalDetail.reps.toString()),
        weightController =
            TextEditingController(text: _formatWeight(originalDetail.weight)),
        restController =
            TextEditingController(text: originalDetail.restSeconds.toString()),
        rirController =
            TextEditingController(text: originalDetail.rir.toString()),
        tempoController = TextEditingController(text: originalDetail.tempo);

  final Exercise originalExercise;
  final PlanExerciseDetail originalDetail;

  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController mainMuscleController;
  final TextEditingController descriptionController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController restController;
  final TextEditingController rirController;
  final TextEditingController tempoController;

  int get exerciseId => originalDetail.exerciseId;

  Exercise buildExercise() {
    return Exercise(
      id: originalExercise.id,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      category: categoryController.text.trim(),
      mainMuscleGroup: mainMuscleController.text.trim(),
    );
  }

  PlanExerciseDetail buildDetail() {
    return originalDetail.copyWith(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      sets: _parseInt(setsController.text, originalDetail.sets),
      reps: _parseInt(repsController.text, originalDetail.reps),
      weight: _parseDouble(weightController.text, originalDetail.weight),
      restSeconds: _parseInt(restController.text, originalDetail.restSeconds),
      rir: _parseInt(rirController.text, originalDetail.rir),
      tempo: tempoController.text.trim(),
    );
  }

  bool get hasExerciseChanges {
    final updated = buildExercise();
    return updated.name != originalExercise.name ||
        updated.description != originalExercise.description ||
        updated.category != originalExercise.category ||
        updated.mainMuscleGroup != originalExercise.mainMuscleGroup;
  }

  bool get hasDetailChanges {
    final updated = buildDetail();
    return updated.name != originalDetail.name ||
        updated.description != originalDetail.description ||
        updated.sets != originalDetail.sets ||
        updated.reps != originalDetail.reps ||
        updated.weight != originalDetail.weight ||
        updated.restSeconds != originalDetail.restSeconds ||
        updated.rir != originalDetail.rir ||
        updated.tempo != originalDetail.tempo;
  }

  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    mainMuscleController.dispose();
    descriptionController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    restController.dispose();
    rirController.dispose();
    tempoController.dispose();
  }

  static int _parseInt(String value, int fallback) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  static double _parseDouble(String value, double fallback) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  static String _formatWeight(double weight) {
    final hasDecimals = weight % 1 != 0;
    return hasDecimals ? weight.toString() : weight.toStringAsFixed(0);
  }
}
