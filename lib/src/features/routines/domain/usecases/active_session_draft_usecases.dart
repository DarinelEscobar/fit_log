import '../entities/active_workout_session_draft.dart';
import '../repositories/workout_plan_repository.dart';

class GetActiveSessionDraftUseCase {
  const GetActiveSessionDraftUseCase(this._repo);

  final WorkoutPlanRepository _repo;

  Future<ActiveWorkoutSessionDraft?> call() => _repo.getActiveSessionDraft();
}

class SaveActiveSessionDraftUseCase {
  const SaveActiveSessionDraftUseCase(this._repo);

  final WorkoutPlanRepository _repo;

  Future<void> call(ActiveWorkoutSessionDraft draft) =>
      _repo.saveActiveSessionDraft(draft);
}

class ClearActiveSessionDraftUseCase {
  const ClearActiveSessionDraftUseCase(this._repo);

  final WorkoutPlanRepository _repo;

  Future<void> call() => _repo.clearActiveSessionDraft();
}
