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
    sample: [1, 25, 'Male', 68.0, 170.0, 'Intermediate', 'Hypertrophy'],
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
    sample: [
      [1, 'Upper Push (Strength)', 'Weekly Monday'],
      [2, 'Lower A (Quads)', 'Weekly Tuesday'],
      [3, 'Upper Pull (Width)', 'Weekly wensday'],
      [4, 'Push-Pull Hybrid (Pump)', 'Weekly Friday '],
      [5, 'Lower B (Posterior Chain)', 'Weekly saturda'],
    ],
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
    sample: [
      [1, 'Barbell Overhead Press', 'Standing shoulder press with barbell', 'Compound', 'Shoulders'],
      [2, 'Incline Dumbbell Press', 'Dumbbell bench press on incline', 'Compound', 'Chest'],
      [3, 'Flat Barbell Press', 'Flat bench barbell press', 'Compound', 'Chest'],
      [4, 'Cable / Machine Fly', 'Chest fly using cable or machine', 'Isolation', 'Chest'],
      [5, 'V-Bar Push-down', 'Triceps extension using v-bar cable', 'Isolation', 'Triceps'],
      [6, 'Overhead Rope Extension', 'Overhead rope triceps extension', 'Isolation', 'Triceps'],
      [7, 'Back Squat', 'Barbell squat targeting quads', 'Compound', 'Quads'],
      [8, 'Leg Press', '45-degree sled leg press', 'Compound', 'Quads'],
      [9, 'Leg Extension (1½ reps)', 'Machine leg extensions with extra half rep', 'Isolation', 'Quads'],
      [10, 'Seated Calf Raise', 'Calf raise on seated machine', 'Isolation', 'Calves'],
      [11, 'Tibialis Raise', 'Dorsiflexion for shin using tib bar or setup', 'Isolation', 'Tibialis Anterior'],
      [12, 'Wide-grip Lat Pulldown', 'Pulldown with wide grip for lats', 'Compound', 'Back'],
      [13, 'Seated Cable Row (close)', 'Row with close-grip attachment', 'Compound', 'Back'],
      [14, 'Straight-arm Pulldown', 'Lats-focused pulldown with straight arms', 'Isolation', 'Back'],
      [15, 'Face Pull', 'Rear delt rope pull to face height', 'Isolation', 'Shoulders'],
      [16, 'Barbell Curl', 'Standard barbell curl for biceps', 'Isolation', 'Biceps'],
      [17, 'Incline DB Curl', 'Biceps curl on incline bench', 'Isolation', 'Biceps'],
      [18, 'Wrist / Reverse Curl superset', 'Wrist curl and reverse curl superset', 'Isolation', 'Forearms'],
      [19, 'Cable Crunch', 'Cable-based ab crunches', 'Isolation', 'Abs'],
      [20, 'Decline Barbell Press', 'Barbell press on decline bench', 'Compound', 'Chest'],
      [21, 'Chest-Supported Row (light)', 'Machine or incline bench chest-supported row', 'Compound', 'Back'],
      [22, 'Cable Lateral Raise', 'Side raise with cable', 'Isolation', 'Shoulders'],
      [23, 'Reverse Cable Fly', 'Rear delt fly using cables', 'Isolation', 'Shoulders'],
      [24, 'Hammer Curl', 'Neutral grip dumbbell curl', 'Isolation', 'Biceps'],
      [25, 'Parallel-bar Dips', 'Bodyweight triceps/chest dips', 'Compound', 'Triceps'],
      [26, 'Concentration Curl', 'Single-arm isolated curl seated', 'Isolation', 'Biceps'],
      [27, 'Hanging Leg Raise', 'Hanging abs raise with control', 'Isolation', 'Abs'],
      [28, 'Romanian Deadlift', 'Hip hinge barbell movement for hamstrings', 'Compound', 'Hamstrings'],
      [29, 'Seated Leg Curl', 'Hamstring curl using seated machine', 'Isolation', 'Hamstrings'],
      [30, 'Glute Kick-back Machine', 'Single-leg glute extension machine', 'Isolation', 'Glutes'],
      [31, 'Hip Abduction', 'Outer thigh machine abduction', 'Isolation', 'Glutes'],
      [32, 'Standing Calf Raise', 'Calf raise while standing with weight', 'Isolation', 'Calves'],
      [33, 'Side-plank Hip Dips', 'Oblique dips from side plank position', 'Mobility', 'Obliques'],
    ],
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
    sample: [
    [1, 'Deltoid – Anterior', 'Upper Body'],
    [2, 'Deltoid – Lateral', 'Upper Body'],
    [3, 'Deltoid – Posterior', 'Upper Body'],
    [4, 'Pectoralis Major – Clavicular', 'Upper Body'],
    [5, 'Pectoralis Major – Sternal', 'Upper Body'],
    [6, 'Triceps Brachii – Long Head', 'Upper Body'],
    [7, 'Triceps Brachii – Lateral Head', 'Upper Body'],
    [8, 'Triceps Brachii – Medial Head', 'Upper Body'],
    [9, 'Biceps Brachii – Short Head', 'Upper Body'],
    [10, 'Biceps Brachii – Long Head', 'Upper Body'],
    [11, 'Brachialis', 'Upper Body'],
    [12, 'Forearm Flexors', 'Upper Body'],
    [13, 'Forearm Extensors', 'Upper Body'],
    [14, 'Latissimus Dorsi', 'Upper Body'],
    [15, 'Teres Major', 'Upper Body'],
    [16, 'Rhomboids', 'Upper Body'],
    [17, 'Trapezius – Upper', 'Upper Body'],
    [18, 'Trapezius – Middle', 'Upper Body'],
    [19, 'Trapezius – Lower', 'Upper Body'],
    [20, 'Erector Spinae', 'Core'],
    [21, 'Rectus Abdominis', 'Core'],
    [22, 'Obliques – Internal', 'Core'],
    [23, 'Obliques – External', 'Core'],
    [24, 'Gluteus Maximus', 'Lower Body'],
    [25, 'Gluteus Medius', 'Lower Body'],
    [26, 'Gluteus Minimus', 'Lower Body'],
    [27, 'Quadriceps – Rectus Femoris', 'Lower Body'],
    [28, 'Quadriceps – Vastus Lateralis', 'Lower Body'],
    [29, 'Quadriceps – Vastus Medialis', 'Lower Body'],
    [30, 'Quadriceps – Vastus Intermedius', 'Lower Body'],
    [31, 'Hamstrings – Biceps Femoris', 'Lower Body'],
    [32, 'Hamstrings – Semitendinosus', 'Lower Body'],
    [33, 'Hamstrings – Semimembranosus', 'Lower Body'],
    [34, 'Calves – Gastrocnemius', 'Lower Body'],
    [35, 'Calves – Soleus', 'Lower Body'],
    [36, 'Tibialis Anterior', 'Lower Body'],
    [37, 'Adductors', 'Lower Body'],
    [38, 'Hip Abductors', 'Lower Body']
  ],
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
  sample: [
    // Barbell Overhead Press
    [1, 1, 0.5], [1, 2, 0.3], [1, 6, 0.2],
    // Incline Dumbbell Press
    [2, 4, 0.6], [2, 5, 0.2], [2, 1, 0.2],
    // Flat Barbell Press
    [3, 5, 0.6], [3, 4, 0.25], [3, 6, 0.15],
    // Cable / Machine Fly
    [4, 5, 0.7], [4, 4, 0.2], [4, 1, 0.1],
    // V-Bar Push-down
    [5, 7, 0.5], [5, 8, 0.3], [5, 6, 0.2],
    // Overhead Rope Extension
    [6, 6, 0.55], [6, 8, 0.25], [6, 7, 0.2],
    // Back Squat
    [7, 27, 0.4], [7, 28, 0.3], [7, 29, 0.3],
    // Leg Press
    [8, 27, 0.35], [8, 28, 0.3], [8, 29, 0.25], [8, 24, 0.1],
    // Leg Extension (1½ reps)
    [9, 27, 0.4], [9, 28, 0.3], [9, 29, 0.3],
    // Seated Calf Raise
    [10, 35, 0.7], [10, 34, 0.3],
    // Tibialis Raise
    [11, 36, 1.0],
    // Wide-grip Lat Pulldown
    [12, 14, 0.5], [12, 15, 0.15], [12, 10, 0.2], [12, 16, 0.15],
    // Seated Cable Row (close)
    [13, 14, 0.3], [13, 16, 0.3], [13, 18, 0.2], [13, 9, 0.2],
    // Straight-arm Pulldown
    [14, 14, 0.7], [14, 15, 0.2], [14, 3, 0.1],
    // Face Pull
    [15, 3, 0.4], [15, 17, 0.35], [15, 16, 0.25],
    // Barbell Curl
    [16, 9, 0.5], [16, 10, 0.35], [16, 11, 0.15],
    // Incline DB Curl
    [17, 10, 0.55], [17, 9, 0.25], [17, 11, 0.2],
    // Wrist / Reverse Curl superset
    [18, 12, 0.5], [18, 13, 0.5],
    // Cable Crunch
    [19, 21, 0.7], [19, 22, 0.15], [19, 23, 0.15],
    // Decline Barbell Press
    [20, 5, 0.65], [20, 4, 0.15], [20, 6, 0.2],
    // Chest-Supported Row (light)
    [21, 14, 0.35], [21, 16, 0.35], [21, 18, 0.3],
    // Cable Lateral Raise
    [22, 2, 0.8], [22, 1, 0.1], [22, 3, 0.1],
    // Reverse Cable Fly
    [23, 3, 0.6], [23, 16, 0.2], [23, 18, 0.2],
    // Hammer Curl
    [24, 11, 0.4], [24, 9, 0.3], [24, 10, 0.3],
    // Parallel-bar Dips
    [25, 6, 0.35], [25, 5, 0.35], [25, 1, 0.3],
    // Concentration Curl
    [26, 9, 0.6], [26, 10, 0.3], [26, 11, 0.1],
    // Hanging Leg Raise
    [27, 21, 0.6], [27, 23, 0.4],
    // Romanian Deadlift
    [28, 31, 0.4], [28, 32, 0.3], [28, 24, 0.3],
    // Seated Leg Curl
    [29, 31, 0.35], [29, 32, 0.35], [29, 33, 0.3],
    // Glute Kick-back Machine
    [30, 24, 0.6], [30, 25, 0.3], [30, 31, 0.1],
    // Hip Abduction
    [31, 25, 0.5], [31, 26, 0.3], [31, 38, 0.2],
    // Standing Calf Raise
    [32, 34, 0.7], [32, 35, 0.3],
    // Side-plank Hip Dips
    [33, 23, 0.4], [33, 22, 0.4], [33, 25, 0.2],
  ],
  ),

};
