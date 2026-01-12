import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';

final workoutPlanRepositoryProvider =
    Provider<WorkoutPlanRepositoryImpl>((ref) => WorkoutPlanRepositoryImpl());
