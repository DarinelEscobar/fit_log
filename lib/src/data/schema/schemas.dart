// -----------------------------------------------------------------------------
// Central place describing every table: column names and 1 demo row.
// -----------------------------------------------------------------------------
class TableSchema {
  const TableSchema({
    required this.sheetName,
    required this.headers,
    required this.sample,
  });

  final String sheetName;
  final List<String> headers;
  final List<dynamic> sample;
}

const Map<String, TableSchema> kTableSchemas = {
  'user.xlsx': TableSchema(
    sheetName: 'User',
    headers: [
      // PK autoincrement
      'user_id',
      // Age (years)
      'age',
      // Male | Female | Other
      'gender',
      // Body-weight (kg)
      'weight',
      // Height (cm)
      'height',
      // Beginner | Intermediate | Advanced
      'experience_level',
      // Hypertrophy | Strength | …
      'goal',
    ],
    sample: [1, 25, 'Male', 75.0, 175.0, 'Intermediate', 'Hypertrophy'],
  ),

  'workout_plan.xlsx': TableSchema(
    sheetName: 'WorkoutPlan',
    headers: [
      // PK autoincrement
      'plan_id',
      // Friendly plan name
      'name',
      // e.g. “Mon-Wed-Fri”
      'frequency',
    ],
    sample: [1, 'PPL-3-Days', 'Mon-Wed-Fri'],
  ),

  'exercise.xlsx': TableSchema(
    sheetName: 'Exercise',
    headers: [
      // PK autoincrement
      'exercise_id',
      // Exercise label
      'name',
      // Short technique cues
      'description',
      // Compound | Isolation | Mobility | …
      'category',
      // Chest | Back | Legs | …
      'main_muscle_group',
    ],
    sample: [1, 'Bench Press', 'Barbell flat bench-press', 'Compound', 'Chest'],
  ),

  'plan_exercise.xlsx': TableSchema(
    sheetName: 'PlanExercise',
    headers: [
      // FK → WorkoutPlan.plan_id
      'plan_id',
      // FK → Exercise.exercise_id
      'exercise_id',
      // Sets / session
      'suggested_sets',
      // Target reps
      'suggested_reps',
      // Recommended kg
      'estimated_weight',
      // Optional local image
      'image_path',
    ],
    sample: [1, 1, 3, 10, 40.0, ''],
  ),

  'workout_log.xlsx': TableSchema(
    sheetName: 'WorkoutLog',
    headers: [
      // PK autoincrement
      'log_id',
      // yyyy-MM-dd
      'date',
      // FK → WorkoutPlan.plan_id
      'plan_id',
      // FK → Exercise.exercise_id
      'exercise_id',
      // 1-based set index
      'set_number',
      // Reps done
      'reps_completed',
      // Actual kg
      'weight_used',
      // Reps-in-reserve
      'RIR',
    ],
    sample: [1, '2025-04-25', 1, 1, 1, 10, 40.0, 2],
  ),

  'workout_session.xlsx': TableSchema(
    sheetName: 'WorkoutSession',
    headers: [
      // PK autoincrement
      'session_id',
      // yyyy-MM-dd
      'date',
      // FK → WorkoutPlan.plan_id
      'plan_id',
      // Easy | Normal | Exhausted
      'fatigue_level',
      // Minutes
      'duration_minutes',
      // Emoji / word
      'mood',
      // Free notes
      'notes',
    ],
    sample: [1, '2025-04-25', 1, 'Normal', 60, '🙂', 'Felt good – slept 7 h'],
  ),

  'muscle.xlsx': TableSchema(
    sheetName: 'Muscle',
    headers: [
      // PK autoincrement
      'muscle_id',
      // Anatomical muscle name
      'name',
      // Upper | Lower | Core | …
      'region',
    ],
    sample: [1, 'Pectoralis Major – Sternal', 'Upper Body'],
  ),

  'exercise_target.xlsx': TableSchema(
    sheetName: 'ExerciseTarget',
    headers: [
      // FK → Exercise.exercise_id
      'exercise_id',
      // FK → Muscle.muscle_id
      'muscle_id',
      // 0.0 – 1.0 emphasis
      'emphasis_percentage',
    ],
    sample: [1, 1, 0.7],
  ),
};
