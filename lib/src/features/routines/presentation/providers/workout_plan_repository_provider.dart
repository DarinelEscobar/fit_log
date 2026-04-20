import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/workout_plan_repository.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';

final workoutPlanRepositoryProvider =
    Provider<WorkoutPlanRepository>((ref) => WorkoutPlanRepositoryImpl());
