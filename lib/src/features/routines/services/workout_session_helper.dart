import '../domain/entities/workout_log_entry.dart';

class WorkoutSessionHelper {
  static String formatDuration(Duration duration) =>
      '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
      '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  static List<WorkoutLogEntry> lastLogs(List<WorkoutLogEntry> logs) {
    if (logs.isEmpty) return [];
    logs.sort((a, b) => a.date.compareTo(b.date));
    final lastDate = logs.last.date;
    return logs
        .where((l) => l.date.isAtSameMomentAs(lastDate))
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
  }

  static List<WorkoutLogEntry> bestLogs(List<WorkoutLogEntry> logs) {
    if (logs.isEmpty) return [];
    final grouped = <DateTime, List<WorkoutLogEntry>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.date, () => []).add(log);
    }

    double tonnage(List<WorkoutLogEntry> entries) =>
        entries.fold(0, (sum, e) => sum + e.reps * e.weight);

    DateTime bestDate = grouped.keys.first;
    double bestTon = tonnage(grouped[bestDate]!);
    grouped.forEach((date, entries) {
      final total = tonnage(entries);
      if (total > bestTon) {
        bestTon = total;
        bestDate = date;
      }
    });

    final bestLogs = grouped[bestDate]!;
    bestLogs.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return bestLogs;
  }
}
