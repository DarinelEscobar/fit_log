import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/workout_storage_service.dart';

final workoutStorageServiceProvider = Provider<WorkoutStorageService>((ref) {
  final service = WorkoutStorageService();
  ref.onDispose(() {
    service.close();
  });
  return service;
});
