// -----------------------------------------------------------------------------
// Central place describing every table: column names and 1 demo row.
// -----------------------------------------------------------------------------
import '../var/exercise_samples.dart';
import '../var/workout_log_samples.dart';
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
    80.0,
    10.0,
    37.0,
    132.0,
    110.0,
    77.0,
    77.0,
    90.0,
    94.5,
    53.5,
    43.5,
    34.5,
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
    sample: const [
      [1, 'Barbell Overhead Press', 'Tempo 2-0-1-0 — Mantén core firme; empuja la barra en línea recta.'],
      [2, 'Incline Dumbbell Press', 'Tempo 2-0-1-0 — Codos a 45°, no bloquees arriba.'],
      ...kExerciseExtraSamples,
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
    // Rest time after each set (seconds)
    'rest_seconds',
    // Optional local image
    'image_path',
  ],
  sample: [
    [1, 1, 4, 8, 25.0, 150, ''],
    [1, 2, 4, 10, 45.0, 150, ''],
    [1, 3, 3, 10, 40.0, 150, ''],
    [1, 4, 3, 15, 15.0, 75, ''],
    [1, 5, 3, 12, 45.0, 75, ''],
    [1, 6, 2, 15, 20.0, 60, ''],
    [2, 7, 4, 8, 55.0, 180, ''],
    [2, 8, 4, 12, 30.0, 150, ''],
    [2, 9, 3, 15, 20.0, 75, ''],
    [2, 10, 4, 20, 25.0, 60, ''],
    [2, 11, 3, 20, 10.0, 60, ''],
    [3, 12, 4, 12, 55.0, 150, ''],
    [3, 13, 4, 15, 30.0, 150, ''],
    [3, 14, 4, 15, 30.0, 75, ''],
    [3, 15, 3, 20, 25.0, 60, ''],
    [3, 16, 4, 10, 40.0, 90, ''],
    [3, 17, 3, 12, 10.0, 75, ''],
    [3, 18, 3, 15, 10.0, 0, ''],
    [3, 34, 3, 15, 20.0, 0, ''],
    [3, 19, 3, 20, 25.0, 45, ''],
    [4, 20, 3, 12, 0.0, 120, ''],
    [4, 21, 3, 15, 0.0, 90, ''],
    [4, 22, 4, 15, 0.0, 60, ''],
    [4, 23, 3, 15, 0.0, 60, ''],
    [4, 24, 3, 12, 0.0, 75, ''],
    [4, 25, 3, 12, 0.0, 90, ''],
    [4, 26, 2, 15, 0.0, 60, ''],
    [4, 27, 3, 15, 0.0, 60, ''],
    [5, 28, 4, 10, 0.0, 180, ''],
    [5, 29, 4, 12, 0.0, 120, ''],
    [5, 30, 3, 15, 0.0, 60, ''],
    [5, 31, 3, 20, 0.0, 60, ''],
    [5, 32, 4, 15, 0.0, 60, ''],
    [5, 33, 3, 20, 0.0, 30, ''],
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
    // ─────────── 2025-04-28 ───────────
  [1, '2025-04-28', 1, 1, 1, 7, 25.0, 2],
  [2, '2025-04-28', 1, 1, 2, 7, 20.0, 2],
  ...kWorkoutLogExtraSamples,
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
    [1, '2025-04-28', 1, 4, 90, 3, 'Auto-gen'],
    [2, '2025-04-29', 2, 4, 90, 3, 'Auto-gen'],
    [3, '2025-04-30', 3, 4, 90, 3, 'Auto-gen'],
    [4, '2025-05-02', 4, 4, 90, 3, 'Auto-gen'],
    [5, '2025-05-03', 5, 4, 90, 3, 'Auto-gen'],
    [6, '2025-05-05', 1, 4, 90, 3, 'Auto-gen'],
    [7, '2025-05-06', 2, 4, 90, 3, 'Auto-gen'],
    [8, '2025-05-07', 3, 4, 90, 3, 'Auto-gen'],
    [9, '2025-05-09', 4, 4, 90, 3, 'Auto-gen'],
    [10, '2025-05-10', 5, 4, 90, 3, 'Auto-gen'],
    [11, '2025-05-12', 1, 4, 90, 3, 'Auto-gen'],
    [12, '2025-05-13', 2, 4, 90, 3, 'Auto-gen'],
    [13, '2025-05-14', 3, 4, 90, 3, 'Auto-gen'],
    [14, '2025-05-15', 4, 4, 90, 3, 'Auto-gen'],
    [15, '2025-05-16', 5, 4, 90, 3, 'Auto-gen'],
    [16, '2025-05-19', 1, 4, 90, 3, 'Auto-gen'],
    [17, '2025-05-20', 2, 4, 90, 3, 'Auto-gen'],
    [18, '2025-05-21', 3, 4, 90, 3, 'Auto-gen'],
    [19, '2025-05-23', 4, 4, 90, 3, 'Auto-gen'],
    [20, '2025-05-24', 5, 4, 90, 3, 'Auto-gen'],
    [21, '2025-05-26', 1, 4, 90, 3, 'Auto-gen'],
    [22, '2025-05-27', 2, 4, 90, 3, 'Auto-gen'],
    [23, '2025-05-28', 3, 4, 90, 3, 'Auto-gen'],
    [24, '2025-05-30', 4, 4, 90, 3, 'Auto-gen'],
    [25, '2025-05-31', 5, 4, 90, 3, 'Auto-gen'],
    [26, '2025-06-02', 1, 4, 90, 3, 'Auto-gen'],
    [27, '2025-06-03', 2, 4, 90, 3, 'Auto-gen'],
    [28, '2025-06-09', 1, 4, 90, 3, 'Auto-gen'],
    [29, '2025-06-04', 3, 4, 90, 3, 'Auto-gen'],
    [30, '2025-06-06', 4, 4, 90, 3, 'Auto-gen'],
    [31, '2025-06-07', 5, 4, 90, 3, 'Auto-gen'],
    [32, '2025-06-11', 3, 4, 90, 3, 'Auto-gen'],
    [33, '2025-06-13', 4, 4, 90, 3, 'Auto-gen'],
    [34, '2025-06-14', 5, 4, 90, 3, 'Auto-gen'],
    [35, '2025-06-16', 1, 4, 90, 3, 'Auto-gen'],
    [36, '2025-06-17', 2, 4, 90, 3, 'Auto-gen'],
    [37, '2025-06-18', 3, 4, 90, 3, 'Auto-gen'],
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
      // Wrist Curl
      [34, 12, 0.7], // Forearm Flexors
      [34, 13, 0.3], // Forearm Extensors

      // Glute bridge bar
      [36, 24, 0.7], [36, 31, 0.3],
      // Preacher Curl
      [38, 9, 0.6], [38, 10, 0.3], [38, 11, 0.1],
      // Cable Fly (lower chest)
      [39, 5, 0.8], [39, 4, 0.1], [39, 1, 0.1],
      // Cable Fly (inner chest)
      [40, 5, 0.8], [40, 4, 0.1], [40, 1, 0.1],
      // Sulek curl
      [41, 11, 0.4], [41, 9, 0.3], [41, 10, 0.3],
      // Triceps Rope Pushdown
      [42, 6, 0.4], [42, 7, 0.3], [42, 8, 0.3],
      // Romanian Deadlift straight bar
      [43, 31, 0.4], [43, 32, 0.3], [43, 24, 0.3],
      // Hip Adduction
      [43, 37, 0.8], [43, 25, 0.1], [43, 26, 0.1],
    ],
  ),


};
