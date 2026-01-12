import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/usecases/get_workout_plans_usecase.dart';
import '../../domain/usecases/set_workout_plan_active_usecase.dart';
import '../../domain/repositories/workout_plan_repository.dart';
import 'workout_plan_repository_provider.dart';

final workoutPlanProvider = StateNotifierProvider<WorkoutPlanController,
    AsyncValue<List<WorkoutPlan>>>((ref) {
  return WorkoutPlanController(ref.watch(workoutPlanRepositoryProvider));
});

class WorkoutPlanController extends StateNotifier<AsyncValue<List<WorkoutPlan>>> {
  final GetWorkoutPlansUseCase _getPlans;
  final SetWorkoutPlanActiveUseCase _setPlanActive;

  WorkoutPlanController(WorkoutPlanRepository repo)
      : _getPlans = GetWorkoutPlansUseCase(repo),
        _setPlanActive = SetWorkoutPlanActiveUseCase(repo),
        super(const AsyncLoading()) {
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _getPlans();
      state = AsyncData(plans);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setPlanActive(int planId, bool isActive) async {
    state = const AsyncLoading();
    await _setPlanActive(planId, isActive);
    await _loadPlans();
  }
}
