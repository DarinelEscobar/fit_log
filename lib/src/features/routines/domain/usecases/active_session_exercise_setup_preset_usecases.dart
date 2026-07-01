import '../entities/active_session_exercise_setup_preset.dart';
import '../repositories/workout_plan_repository.dart';

class GetActiveSessionExerciseSetupPresetUseCase {
  const GetActiveSessionExerciseSetupPresetUseCase(this._repo);

  final WorkoutPlanRepository _repo;

  Future<ActiveSessionExerciseSetupPreset?> call(int exerciseId) {
    return _repo.getActiveSessionExerciseSetupPreset(exerciseId);
  }
}

class SaveActiveSessionExerciseSetupPresetUseCase {
  const SaveActiveSessionExerciseSetupPresetUseCase(this._repo);

  final WorkoutPlanRepository _repo;

  Future<void> call(ActiveSessionExerciseSetupPreset preset) {
    return _repo.saveActiveSessionExerciseSetupPreset(preset);
  }
}
