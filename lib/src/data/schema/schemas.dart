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
      // Desired body-weight (kg)
      'target_weight',
      // Desired body fat %
      'target_body_fat',
      'target_neck',
      'target_shoulders',
      'target_chest',
      'target_abdomen',
      'target_waist',
      'target_glutes',
      'target_thigh',
      'target_calf',
      'target_arm',
      'target_forearm',
    ],
    sample: [
      1,
      21,
      'Male',
      70.0,
      170.0,
      'Intermediate',
      'Hypertrophy',
      73.9,
      10.0,
      42.5,
      121.0,
      121.0,
      78.2,
      74.8,
      83.0,
      69.8,
      40.0,
      42.5,
      34.0,
    ],
  ),

  'body_metrics.xlsx': TableSchema(
    sheetName: 'BodyMetrics',
    headers: [
      // PK autoincrement
      'metric_id',
      // Date of the measurement
      'date',
      // Weight (kg)
      'weight',
      // Body Fat %
      'body_fat',
      // Neck circumference (cm)
      'neck',
      // Shoulder circumference (cm)
      'shoulders',
      // Chest circumference (cm)
      'chest',
      // Abdomen circumference (cm)
      'abdomen',
      // Waist circumference (cm)
      'waist',
      // Glutes circumference (cm)
      'glutes',
      // Thigh circumference (cm)
      'thigh',
      // Calf circumference (cm)
      'calf',
      // Arm circumference (cm)
      'arm',
      // Forearm circumference (cm)
      'forearm',
      // Age (years)
      'age',
    ],
    sample: [
      [1, '2024-07-13', 70.0, null, 37.0, 122.0, 100.0, 80.0, 80.0, 96.0, 57.0, 35.0, 35.0, 28.0, 20],
      [2, '2024-07-30', 70.0, null, 39.0, 120.0, 100.0, 81.0, 80.0, 96.0, 57.0, 34.0, 34.0, 28.0, 20],
      [3, '2024-08-21', 68.0, null, 40.0, 119.0, 95.0, 80.0, 80.0, 94.0, 55.0, 34.0, 37.0, 28.0, 20],
      [4, '2024-10-07', 68.0, null, 36.0, 118.0, 98.0, 76.0, 81.0, 92.0, 55.0, 33.0, 35.0, 29.0, 20],
      [5, '2024-11-10', 67.0, null, 37.0, 119.0, 98.0, 78.0, 78.0, 93.0, 57.0, 35.0, 33.0, 28.0, 20],
      [6, '2024-11-25', 66.0, null, 37.0, 119.0, 91.0, 79.0, 78.0, 96.0, 57.0, 34.0, 33.0, 28.0, 20],
      [7, '2025-01-14', 66.0, null, 38.0, 120.0, 98.0, 79.0, 81.0, 92.0, 57.0, 33.5, 32.0, 27.0, 21],
      [8, '2025-04-06', 68.0, null, 38.0, 116.0, 99.0, 77.0, 81.0, 93.0, 57.0, 34.0, 34.0, 27.0, 21],
      [9, '2025-06-14', 70.0, 20.0, 38.0, 123.0, 99.0, 80.0, 82.0, 97.0, 59.0, 36.0, 33.0, 28.0, 21],
    ],
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
      [34, 'Wrist Curl', 'Seated dumbbell wrist flexion', 'Isolation', 'Forearms'],
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
    // Target reps (highest in range)
    'suggested_reps',
    // Recommended kg (sample values)
    'estimated_weight',
    // Optional local image
    'image_path',
  ],
  sample: [
    // ── Day 1 ─ Upper Push (plan_id 1) ────────────────────────────────────────
    [1, 1, 4,  8, 25.0, ''], // Barbell Overhead Press
    [1, 2, 4, 10, 45.0, ''], // Incline Dumbbell Press
    [1, 3, 3, 10, 40.0, ''], // Flat Barbell Press
    [1, 4, 3, 15, 15.0, ''], // Cable / Machine Fly
    [1, 5, 3, 12, 45.0, ''], // V-Bar Push-down
    [1, 6, 2, 15, 20.0, ''], // Overhead Rope Extension

    // ── Day 2 ─ Lower A (plan_id 2) ───────────────────────────────────────────
    [2, 7, 4,  8, 55.0, ''], // Back Squat
    [2, 8, 4, 12, 30.0, ''], // Leg Press
    [2, 9, 3, 15, 20.0, ''], // Leg Extension (1½ reps)
    [2,10, 4, 20, 25.0, ''], // Seated Calf Raise
    [2,11, 3, 20, 10.0, ''], // Tibialis Raise (opt.)

    // ── Day 3 ─ Upper Pull (plan_id 3) ────────────────────────────────────────
    [3, 12, 4, 12, 55.0, ''], // Wide-grip Lat Pulldown
    [3, 13, 4, 15, 30.0, ''], // Seated Cable Row (close)
    [3, 14, 4, 15, 30.0, ''], // Straight-arm Pulldown
    [3, 15, 3, 20, 25.0, ''], // Face Pull
    [3, 16, 4, 10, 40.0, ''], // Barbell Curl
    [3, 17, 3, 12, 10.0, ''], // Incline DB Curl
    [3, 18, 3, 15, 10.0, ''], // Wrist / Reverse Curl superset
    [3, 34, 3, 15, 20.0, ''], // Wrist Curl
    [3, 19, 3, 20, 25.0, ''], // Cable Crunch

    // ── Day 5 ─ Push-Pull Hybrid (plan_id 4) ─────────────────────────────────
    [4,20, 3, 12,  0.0, ''], // Decline Barbell Press
    [4,21, 3, 15,  0.0, ''], // Chest-Supported Row (light)
    [4,22, 4, 15,  0.0, ''], // Cable Lateral Raise
    [4,23, 3, 15,  0.0, ''], // Reverse Cable Fly
    [4,24, 3, 12,  0.0, ''], // Hammer Curl
    [4,25, 3, 12,  0.0, ''], // Parallel-bar Dips
    [4,26, 2, 15,  0.0, ''], // Concentration Curl
    [4,27, 3, 15,  0.0, ''], // Hanging Leg Raise

    // ── Day 6 ─ Lower B (plan_id 5) ───────────────────────────────────────────
    [5,28, 4, 10,  0.0, ''], // Romanian Deadlift
    [5,29, 4, 12,  0.0, ''], // Seated Leg Curl
    [5,30, 3, 15,  0.0, ''], // Glute Kick-back Machine
    [5,31, 3, 20,  0.0, ''], // Hip Abduction
    [5,32, 4, 15,  0.0, ''], // Standing Calf Raise
    [5,33, 3, 20,  0.0, ''], // Side-plank Hip Dips
  ],
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
  sample: [
    // ─────────── Day 1 – Upper Push (2025-04-28) ───────────
    [ 1, '2025-04-28', 1,  1, 1,  7, 25.0, 2], // OHP
    [ 2, '2025-04-28', 1,  1, 2,  7, 20.0, 2],
    [ 3, '2025-04-28', 1,  1, 3,  8, 20.0, 1],
    [ 4, '2025-04-28', 1,  1, 4,  8, 20.0, 1],

    [ 5, '2025-04-28', 1,  2, 1,  8, 45.0, 2], // Incline DB Press
    [ 6, '2025-04-28', 1,  2, 2,  6, 45.0, 2],
    [ 7, '2025-04-28', 1,  2, 3,  6, 40.0, 2],
    [ 8, '2025-04-28', 1,  2, 4,  6, 35.0, 2],

    [ 9, '2025-04-28', 1,  3, 1,  8, 25.0, 2], // Flat Barbell Press
    [10, '2025-04-28', 1,  3, 2, 10, 35.0, 1],
    [11, '2025-04-28', 1,  3, 3,  8, 40.0, 1],

    [12, '2025-04-28', 1,  4, 1, 13, 15.0, 2], // Cable Fly
    [13, '2025-04-28', 1,  4, 2, 15, 15.0, 1],
    [14, '2025-04-28', 1,  4, 3, 15, 15.0, 1],
    [15, '2025-04-28', 1,  4, 4, 10, 15.0, 2],

    [16, '2025-04-28', 1,  5, 1, 10, 45.0, 2], // V-Bar Push-down
    [17, '2025-04-28', 1,  5, 2,  9, 40.0, 2],
    [18, '2025-04-28', 1,  5, 3, 15, 30.0, 1],

    [19, '2025-04-28', 1,  6, 1,  6, 20.0, 2], // Overhead Rope Ext.
    [20, '2025-04-28', 1,  6, 2, 15, 10.0, 3],
    [21, '2025-04-28', 1,  6, 3, 18, 15.0, 2],
    [22, '2025-04-28', 1,  6, 4, 15, 15.0, 2],

    // ─────────── Day 2 – Lower A (2025-04-29) ───────────
    [23, '2025-04-29', 2,  7, 1, 10, 45.0, 2], // Back Squat
    [24, '2025-04-29', 2,  7, 2,  8, 55.0, 2],
    [25, '2025-04-29', 2,  7, 3,  7, 55.0, 2],
    [26, '2025-04-29', 2,  7, 4,  6, 55.0, 3],

    [27, '2025-04-29', 2,  8, 1, 12, 50.0, 2], // Leg Press
    [28, '2025-04-29', 2,  8, 2, 13, 60.0, 2],
    [29, '2025-04-29', 2,  8, 3, 14, 60.0, 2],
    [30, '2025-04-29', 2,  8, 4, 14, 60.0, 2],

    [31, '2025-04-29', 2,  9, 1, 15, 20.0, 1], // Leg Extension
    [32, '2025-04-29', 2,  9, 2, 15, 15.0, 1],
    [33, '2025-04-29', 2,  9, 3, 15, 15.0, 1],

    [34, '2025-04-29', 2, 10, 1, 15, 25.0, 2], // Seated Calf Raise
    [35, '2025-04-29', 2, 10, 2, 14, 25.0, 2],
    [36, '2025-04-29', 2, 10, 3, 14, 17.0, 2],
    [37, '2025-04-29', 2, 10, 4, 13, 17.0, 3],

    [38, '2025-04-29', 2, 11, 1, 15, 60.0, 2], // Tibialis Raise (Induction)
    [39, '2025-04-29', 2, 11, 2, 15, 60.0, 2],
    [40, '2025-04-29', 2, 11, 3, 15, 60.0, 2],

    [41, '2025-04-29', 2, 31, 1, 15, 60.0, 2], // Hip Abduction
    [42, '2025-04-29', 2, 31, 2, 15, 60.0, 2],
    [43, '2025-04-29', 2, 31, 3, 15, 60.0, 2],
    // ─────────── Day 3 – (2025-04-30) ───────────
    // id  date        plan ex  set reps  kg   RIR
    [44, '2025-04-30', 3, 12, 1, 10, 55.0, 2],
    [45, '2025-04-30', 3, 12, 2,  8, 55.0, 2],
    [46, '2025-04-30', 3, 12, 3, 10, 45.0, 2],
    [47, '2025-04-30', 3, 12, 4, 12, 40.0, 1],

    [48, '2025-04-30', 3, 13, 1, 13, 30.0, 2],
    [49, '2025-04-30', 3, 13, 2, 15, 25.0, 2],
    [50, '2025-04-30', 3, 13, 3, 15, 25.0, 2],
    [51, '2025-04-30', 3, 13, 4, 15, 25.0, 2],

    [52, '2025-04-30', 3, 14, 1, 15, 30.0, 1],
    [53, '2025-04-30', 3, 14, 2, 12, 30.0, 2],
    [54, '2025-04-30', 3, 14, 3, 15, 25.0, 1],
    [55, '2025-04-30', 3, 14, 4, 15, 25.0, 1],

    [56, '2025-04-30', 3, 15, 1, 15, 25.0, 2],
    [57, '2025-04-30', 3, 15, 2, 15, 25.0, 2],
    [58, '2025-04-30', 3, 15, 3, 20, 20.0, 1],

    [59, '2025-04-30', 3, 16, 1,  7, 40.0, 2],
    [60, '2025-04-30', 3, 16, 2,  8, 20.0, 2],
    [61, '2025-04-30', 3, 16, 3,  7, 20.0, 2],
    [62, '2025-04-30', 3, 16, 4, 10, 10.0, 1],

    [63, '2025-04-30', 3, 17, 1, 10, 10.0, 2],
    [64, '2025-04-30', 3, 17, 2, 25,  5.0, 1],
    [65, '2025-04-30', 3, 17, 3,  9,  7.0, 2],

    [66, '2025-04-30', 3, 18, 1, 10, 10.0, 2], // Wrist / Rev Curl
    [67, '2025-04-30', 3, 18, 2,  8, 10.0, 2],
    [68, '2025-04-30', 3, 18, 3,  9, 10.0, 2],

    [69, '2025-04-30', 3, 34, 1, 15, 20.0, 2], // Wrist Curl
    [70, '2025-04-30', 3, 34, 2, 10, 20.0, 3],
    [71, '2025-04-30', 3, 34, 3, 15, 10.0, 3],

    [72, '2025-04-30', 3, 19, 1, 10, 25.0, 2], // Cable Crunch
    [73, '2025-04-30', 3, 19, 2,  9, 25.0, 3],
  ],
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
    // 1 (very fresh) – 5 (exhausted)
    'fatigue_level',
    // Minutes
    'duration_minutes',
    // 1 (very bad) – 5 (excellent)
    'mood',
    // Free notes
    'notes',
  ],
  sample: [
    [1, '2025-04-28', 1, 3, 75, 4, 'Solid upper-push—energy good'],
    [2, '2025-04-29', 2, 4, 80, 3, 'Leg day felt heavy but completed all sets'],
    [3, '2025-04-30', 3, 4, 75, 3, 'Upper-pull session; grip strength taxed'],
  ],
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
    // Wrist Curl'
    [34, 12, 0.7], // Forearm Flexors
    [34, 13, 0.3], // Forearm Extensors
  ],
  ),

};
