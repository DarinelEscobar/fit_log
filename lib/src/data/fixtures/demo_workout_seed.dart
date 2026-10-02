import '../../features/routines/domain/entities/exercise.dart';
import '../../features/routines/domain/entities/plan_exercise_detail.dart';
import '../../features/routines/domain/entities/warm_up_step.dart';
import '../../features/routines/domain/entities/workout_log_entry.dart';
import '../../features/routines/domain/entities/workout_plan.dart';
import '../../features/routines/domain/entities/workout_session.dart';
import '../services/workout_storage_service.dart';

/// Populates realistic demo workout data for UI and emulator review.
///
/// Idempotent: seeds data ONLY if the database contains NO plans,
/// NO logs, and NO sessions. If any existing plans, logs, or sessions
/// are detected, this function returns `false` without making any changes.
///
/// Returns `true` if demo data was successfully seeded, `false` otherwise.
Future<bool> seedDemoWorkoutDataIfNeeded(
  WorkoutStorageService storageService, {
  DateTime? referenceDate,
}) async {
  // Guard check: only seed if no plans, no logs, and no sessions exist.
  final existingPlans = await storageService.fetchWorkoutPlans();
  if (existingPlans.isNotEmpty) {
    return false;
  }

  final existingLogs = await storageService.fetchAllLogs();
  if (existingLogs.isNotEmpty) {
    return false;
  }

  final existingSessions = await storageService.fetchAllSessions();
  if (existingSessions.isNotEmpty) {
    return false;
  }

  // 1. Fetch or create realistic exercises
  final exercises = await storageService.fetchAllExercises();
  final exerciseByName = <String, Exercise>{
    for (final exercise in exercises) exercise.name.toLowerCase(): exercise,
  };

  Future<Exercise> ensureExercise({
    required String name,
    required String description,
    required String category,
    required String mainMuscleGroup,
  }) async {
    final key = name.toLowerCase();
    final existing = exerciseByName[key];
    if (existing != null) {
      return existing;
    }

    await storageService.createExercise(
      name,
      description,
      category,
      mainMuscleGroup,
    );
    final refreshed = await storageService.fetchAllExercises();
    for (final exercise in refreshed) {
      exerciseByName[exercise.name.toLowerCase()] = exercise;
    }
    return exerciseByName[key]!;
  }

  final benchPress = await ensureExercise(
    name: 'Barbell Bench Press',
    description: 'Retract shoulder blades and maintain stable bar path.',
    category: 'Compound',
    mainMuscleGroup: 'Chest',
  );
  final barbellRow = await ensureExercise(
    name: 'Barbell Row',
    description: 'Keep torso hinged and drive elbows back toward hips.',
    category: 'Compound',
    mainMuscleGroup: 'Back',
  );
  final overheadPress = await ensureExercise(
    name: 'Standing Overhead Press',
    description: 'Brace core and press vertically overhead.',
    category: 'Compound',
    mainMuscleGroup: 'Shoulders',
  );
  final squat = await ensureExercise(
    name: 'Barbell Back Squat',
    description: 'Drive through mid-foot and keep torso braced.',
    category: 'Compound',
    mainMuscleGroup: 'Legs',
  );
  final rdl = await ensureExercise(
    name: 'Romanian Deadlift',
    description: 'Hinge at hips with neutral spine and soft knees.',
    category: 'Compound',
    mainMuscleGroup: 'Hamstrings',
  );
  final calfRaise = await ensureExercise(
    name: 'Standing Calf Raise',
    description: 'Full stretch at bottom with deliberate peak contraction.',
    category: 'Isolation',
    mainMuscleGroup: 'Calves',
  );

  // 2. Create the two workout routines: Upper body and Lower body
  await storageService.createWorkoutPlan('Upper Body', 'Upper / Lower Split');
  await storageService.createWorkoutPlan('Lower Body', 'Upper / Lower Split');

  final createdPlans = await storageService.fetchWorkoutPlans();
  final upperPlan = createdPlans.firstWhere((p) => p.name == 'Upper Body');
  final lowerPlan = createdPlans.firstWhere((p) => p.name == 'Lower Body');

  // 3. Configure Upper Body exercises (3 sets x 8-12 reps, RIR 2, tempo 3-1-1, rest 60s)
  await storageService.addExerciseToPlan(
    upperPlan.id,
    PlanExerciseDetail(
      exerciseId: benchPress.id,
      name: benchPress.name,
      description: benchPress.description,
      sets: 3,
      reps: 10,
      weight: 75.0,
      restSeconds: 60,
      rir: 2,
      tempo: '3-1-1',
    ),
  );
  await storageService.addExerciseToPlan(
    upperPlan.id,
    PlanExerciseDetail(
      exerciseId: barbellRow.id,
      name: barbellRow.name,
      description: barbellRow.description,
      sets: 3,
      reps: 10,
      weight: 65.0,
      restSeconds: 60,
      rir: 2,
      tempo: '3-1-1',
    ),
  );
  await storageService.addExerciseToPlan(
    upperPlan.id,
    PlanExerciseDetail(
      exerciseId: overheadPress.id,
      name: overheadPress.name,
      description: overheadPress.description,
      sets: 3,
      reps: 10,
      weight: 45.0,
      restSeconds: 60,
      rir: 2,
      tempo: '3-1-1',
    ),
  );

  // 4. Upper Body short 2-step warm-up
  await storageService.replaceWarmUpSteps(
    upperPlan.id,
    const [
      WarmUpStep(
        name: 'Arm Circles & Dynamic Shoulder Rotations',
        notes: 'Gentle mobility and rotator cuff prep',
        sets: 1,
        workSeconds: 45,
        restSeconds: 15,
      ),
      WarmUpStep(
        name: 'Band Pull-Aparts',
        notes: 'Scapular retractors and rear delt activation',
        sets: 1,
        workSeconds: 45,
        restSeconds: 15,
      ),
    ],
  );

  // 5. Configure Lower Body exercises (3 sets x 8-12 reps, RIR 2, tempo 3-1-1, rest 60s)
  await storageService.addExerciseToPlan(
    lowerPlan.id,
    PlanExerciseDetail(
      exerciseId: squat.id,
      name: squat.name,
      description: squat.description,
      sets: 3,
      reps: 10,
      weight: 90.0,
      restSeconds: 60,
      rir: 2,
      tempo: '3-1-1',
    ),
  );
  await storageService.addExerciseToPlan(
    lowerPlan.id,
    PlanExerciseDetail(
      exerciseId: rdl.id,
      name: rdl.name,
      description: rdl.description,
      sets: 3,
      reps: 10,
      weight: 80.0,
      restSeconds: 60,
      rir: 2,
      tempo: '3-1-1',
    ),
  );
  await storageService.addExerciseToPlan(
    lowerPlan.id,
    PlanExerciseDetail(
      exerciseId: calfRaise.id,
      name: calfRaise.name,
      description: calfRaise.description,
      sets: 3,
      reps: 12,
      weight: 50.0,
      restSeconds: 60,
      rir: 2,
      tempo: '3-1-1',
    ),
  );

  // 6. Lower Body short 2-step warm-up
  await storageService.replaceWarmUpSteps(
    lowerPlan.id,
    const [
      WarmUpStep(
        name: 'Hip 90/90 & Leg Swings',
        notes: 'Dynamic hip capsule and adductor mobility',
        sets: 1,
        workSeconds: 45,
        restSeconds: 15,
      ),
      WarmUpStep(
        name: 'Bodyweight Squats & Ankle Mobilization',
        notes: 'Groove movement pattern and warm up knee joints',
        sets: 1,
        workSeconds: 45,
        restSeconds: 15,
      ),
    ],
  );

  // 7. Recent history: 5 sessions across the last 2 weeks for charts
  final now = referenceDate ?? DateTime.now();
  final baseDate = DateTime(now.year, now.month, now.day);

  final sessionConfigs = [
    _DemoSessionConfig(
      daysAgo: 12,
      plan: upperPlan,
      duration: 52,
      fatigue: '2',
      mood: '4',
      notes: 'Good bar speed on all bench sets.',
      exerciseWeights: {
        benchPress.id: 72.5,
        barbellRow.id: 62.5,
        overheadPress.id: 42.5,
      },
    ),
    _DemoSessionConfig(
      daysAgo: 9,
      plan: lowerPlan,
      duration: 58,
      fatigue: '3',
      mood: '4',
      notes: 'Clean squat depth, knees tracked well.',
      exerciseWeights: {
        squat.id: 87.5,
        rdl.id: 77.5,
        calfRaise.id: 47.5,
      },
    ),
    _DemoSessionConfig(
      daysAgo: 7,
      plan: upperPlan,
      duration: 50,
      fatigue: '2',
      mood: '5',
      notes: 'Felt strong, slight weight increase on rows.',
      exerciseWeights: {
        benchPress.id: 75.0,
        barbellRow.id: 65.0,
        overheadPress.id: 45.0,
      },
    ),
    _DemoSessionConfig(
      daysAgo: 4,
      plan: lowerPlan,
      duration: 55,
      fatigue: '3',
      mood: '4',
      notes: 'RDLs felt controlled, solid posterior chain work.',
      exerciseWeights: {
        squat.id: 90.0,
        rdl.id: 80.0,
        calfRaise.id: 50.0,
      },
    ),
    _DemoSessionConfig(
      daysAgo: 1,
      plan: upperPlan,
      duration: 54,
      fatigue: '2',
      mood: '5',
      notes: 'Completed all 3 sets with target tempo and RIR.',
      exerciseWeights: {
        benchPress.id: 75.0,
        barbellRow.id: 65.0,
        overheadPress.id: 45.0,
      },
    ),
  ];

  for (final config in sessionConfigs) {
    final sessionDate = baseDate.subtract(Duration(days: config.daysAgo));
    final session = WorkoutSession(
      planId: config.plan.id,
      date: sessionDate,
      fatigueLevel: config.fatigue,
      durationMinutes: config.duration,
      mood: config.mood,
      notes: config.notes,
    );
    await storageService.saveWorkoutSession(session);

    final sessionLogs = <WorkoutLogEntry>[];
    for (final entry in config.exerciseWeights.entries) {
      final exerciseId = entry.key;
      final weight = entry.value;
      for (var setNum = 1; setNum <= 3; setNum++) {
        sessionLogs.add(
          WorkoutLogEntry(
            date: sessionDate,
            planId: config.plan.id,
            exerciseId: exerciseId,
            setNumber: setNum,
            reps: 10,
            weight: weight,
            rir: 2,
            completed: true,
          ),
        );
      }
    }
    await storageService.saveWorkoutLogs(sessionLogs);
  }

  return true;
}

class _DemoSessionConfig {
  const _DemoSessionConfig({
    required this.daysAgo,
    required this.plan,
    required this.duration,
    required this.fatigue,
    required this.mood,
    required this.notes,
    required this.exerciseWeights,
  });

  final int daysAgo;
  final WorkoutPlan plan;
  final int duration;
  final String fatigue;
  final String mood;
  final String notes;
  final Map<int, double> exerciseWeights;
}
