import 'package:fit_log/src/features/performance/domain/models/active_exercise_progress.dart';
import 'package:fit_log/src/features/performance/domain/services/active_exercise_progress_calculator.dart';
import 'package:fit_log/src/features/routines/domain/entities/workout_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActiveExerciseProgressCalculator', () {
    test('backoff and dropset volume does not inflate comparable strength', () {
      final summary = ActiveExerciseProgressCalculator.buildSessionSummary([
        _log(setNumber: 1, weight: 100, reps: 5),
        _log(setNumber: 2, weight: 98, reps: 5),
        _log(setNumber: 3, weight: 95, reps: 5),
        _log(setNumber: 4, weight: 60, reps: 20),
        _log(setNumber: 5, weight: 50, reps: 20),
      ])!;

      expect(summary.setCount, 5);
      expect(summary.volumeKg, 100 * 5 + 98 * 5 + 95 * 5 + 60 * 20 + 50 * 20);
      expect(
        summary.comparableStrengthKg,
        closeTo(
          (100 * (1 + 5 / 30) + 98 * (1 + 5 / 30) + 95 * (1 + 5 / 30)) / 3,
          0.01,
        ),
      );
      expect(
        summary.workingSets.map((set) => set.setNumber),
        [1, 2, 3],
      );
    });

    test('more total volume does not beat stronger working sets', () {
      final stronger = ActiveExerciseProgressCalculator.buildSessionSummary([
        _log(setNumber: 1, weight: 100, reps: 5),
        _log(setNumber: 2, weight: 100, reps: 5),
        _log(setNumber: 3, weight: 100, reps: 5),
      ])!;
      final moreVolume = ActiveExerciseProgressCalculator.buildSessionSummary([
        _log(setNumber: 1, weight: 90, reps: 5),
        _log(setNumber: 2, weight: 90, reps: 5),
        _log(setNumber: 3, weight: 90, reps: 5),
        _log(setNumber: 4, weight: 90, reps: 5),
        _log(setNumber: 5, weight: 90, reps: 5),
      ])!;

      expect(moreVolume.volumeKg, greaterThan(stronger.volumeKg));
      expect(
        stronger.comparableStrengthKg,
        greaterThan(moreVolume.comparableStrengthKg),
      );
    });

    test('recent baseline uses median so one bad day does not dominate', () {
      final currentDate = DateTime(2024, 2, 10);
      final logs = [
        _logForEstimatedOneRm(100, date: DateTime(2024, 2, 1)),
        _logForEstimatedOneRm(100, date: DateTime(2024, 2, 2)),
        _logForEstimatedOneRm(102, date: DateTime(2024, 2, 3)),
        _logForEstimatedOneRm(60, date: DateTime(2024, 2, 4)),
        _logForEstimatedOneRm(101, date: DateTime(2024, 2, 5)),
      ];

      final insight = ActiveExerciseProgressCalculator.buildInsight(
        logs: logs,
        currentSessionDate: currentDate,
      );

      expect(insight.recentBaseline?.sessionCount, 5);
      expect(insight.recentBaseline?.comparableStrengthKg, closeTo(100, 0.01));
      expect(insight.confidence, ActiveExerciseProgressConfidence.high);
    });

    test('current unsaved completed sets update live delta', () {
      const baseline = ActiveExerciseProgressBaseline(
        comparableStrengthKg: 100,
        sessionCount: 5,
      );
      final holdingSession =
          ActiveExerciseProgressCalculator.buildCurrentSession([
        _logForEstimatedOneRm(102, date: DateTime(2024, 2, 10)),
      ]);
      final holdingDelta =
          ActiveExerciseProgressCalculator.compareCurrentToBaseline(
        currentSession: holdingSession,
        baseline: baseline,
      );

      final aheadSession =
          ActiveExerciseProgressCalculator.buildCurrentSession([
        _logForEstimatedOneRm(108, date: DateTime(2024, 2, 10)),
      ]);
      final aheadDelta =
          ActiveExerciseProgressCalculator.compareCurrentToBaseline(
        currentSession: aheadSession,
        baseline: baseline,
      );

      expect(holdingDelta.status, ActiveExerciseProgressDeltaStatus.holding);
      expect(aheadDelta.status, ActiveExerciseProgressDeltaStatus.ahead);
      expect(aheadDelta.deltaKg, closeTo(8, 0.01));
    });

    test('empty history and zero-kg logs produce stable fallback data', () {
      final emptyInsight = ActiveExerciseProgressCalculator.buildInsight(
        logs: const [],
        currentSessionDate: DateTime(2024, 2, 10),
      );
      expect(emptyInsight.hasHistory, isFalse);
      expect(emptyInsight.recentBaseline, isNull);

      final zeroKgInsight = ActiveExerciseProgressCalculator.buildInsight(
        logs: [
          _log(date: DateTime(2024, 2, 1), weight: 0, reps: 15),
          _log(date: DateTime(2024, 2, 1), setNumber: 2, weight: 0, reps: 12),
        ],
        currentSessionDate: DateTime(2024, 2, 10),
      );
      final currentZeroKg =
          ActiveExerciseProgressCalculator.buildCurrentSession([
        _log(date: DateTime(2024, 2, 10), weight: 0, reps: 20),
      ]);
      final zeroDelta =
          ActiveExerciseProgressCalculator.compareCurrentToBaseline(
        currentSession: currentZeroKg,
        baseline: zeroKgInsight.recentBaseline,
      );

      expect(zeroKgInsight.hasHistory, isTrue);
      expect(zeroKgInsight.lastSession?.comparableStrengthKg, 0);
      expect(zeroKgInsight.recentBaseline?.comparableStrengthKg, 0);
      expect(currentZeroKg?.comparableStrengthKg, 0);
      expect(zeroDelta.status, ActiveExerciseProgressDeltaStatus.noBaseline);
    });
  });
}

WorkoutLogEntry _log({
  DateTime? date,
  int planId = 1,
  int exerciseId = 1,
  int setNumber = 1,
  required double weight,
  required int reps,
  int rir = 2,
  bool completed = true,
}) {
  return WorkoutLogEntry(
    date: date ?? DateTime(2024, 2, 1),
    planId: planId,
    exerciseId: exerciseId,
    setNumber: setNumber,
    reps: reps,
    weight: weight,
    rir: rir,
    completed: completed,
  );
}

WorkoutLogEntry _logForEstimatedOneRm(
  double estimatedOneRm, {
  required DateTime date,
}) {
  return _log(
    date: date,
    weight: estimatedOneRm / 2,
    reps: 30,
  );
}
