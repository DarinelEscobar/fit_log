import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout_plan.dart';
import '../../domain/repositories/workout_plan_repository.dart';
import '../../domain/usecases/get_workout_plans_usecase.dart';
import '../../domain/usecases/set_workout_plan_active_usecase.dart';
import 'workout_plan_repository_provider.dart';

final workoutPlanProvider =
    StateNotifierProvider<WorkoutPlanController, AsyncValue<List<WorkoutPlan>>>(
        (ref) {
  return WorkoutPlanController(
    ref,
    ref.watch(workoutPlanRepositoryProvider),
  );
});

final routinePlanBusyIdsProvider = StateProvider<Set<int>>((_) => <int>{});
final routineLibraryMetadataEpochProvider = StateProvider<int>((_) => 0);

class WorkoutPlanController
    extends StateNotifier<AsyncValue<List<WorkoutPlan>>> {
  WorkoutPlanController(this._ref, WorkoutPlanRepository repo)
      : _getPlans = GetWorkoutPlansUseCase(repo),
        _setPlanActive = SetWorkoutPlanActiveUseCase(repo),
        super(const AsyncLoading()) {
    _bootstrap();
  }

  final Ref _ref;
  final GetWorkoutPlansUseCase _getPlans;
  final SetWorkoutPlanActiveUseCase _setPlanActive;

  Future<void> _bootstrap() async {
    await _loadPlans();
  }

  Future<void> refresh({bool silent = false}) async {
    await _loadPlans(silent: silent);
  }

  Future<void> _loadPlans({bool silent = false}) async {
    final previous = state.valueOrNull;
    if (!silent || previous == null) {
      state = const AsyncLoading();
    }

    try {
      final plans = await _getPlans();
      state = AsyncData(plans);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
        return;
      }
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setPlanActive(int planId, bool isActive) async {
    final previous = state.valueOrNull;
    _setBusy(planId, true);

    try {
      await _setPlanActive(planId, isActive);
      await _loadPlans(silent: true);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    } finally {
      _setBusy(planId, false);
    }
  }

  void _setBusy(int planId, bool isBusy) {
    final notifier = _ref.read(routinePlanBusyIdsProvider.notifier);
    final next = {...notifier.state};
    if (isBusy) {
      next.add(planId);
    } else {
      next.remove(planId);
    }
    notifier.state = next;
  }
}
