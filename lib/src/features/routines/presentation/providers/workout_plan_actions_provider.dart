import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/set_plan_active_usecase.dart';
import 'workout_plan_provider.dart';

class WorkoutPlanActions {
  WorkoutPlanActions(this._ref)
      : _setPlanActiveUseCase =
            SetPlanActiveUseCase(WorkoutPlanRepositoryImpl());

  final Ref _ref;
  final SetPlanActiveUseCase _setPlanActiveUseCase;

  Future<void> toggleActive(int planId, bool isActive) async {
    await _setPlanActiveUseCase(planId, isActive);
    _ref.invalidate(workoutPlanProvider);
  }
}

final workoutPlanActionsProvider = Provider.autoDispose<WorkoutPlanActions>(
  WorkoutPlanActions.new,
);
