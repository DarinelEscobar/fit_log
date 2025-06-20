part of 'start_routine_screen.dart';

String _fmt(Duration d) =>
    '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

List<WorkoutLogEntry> _lastLogs(List<WorkoutLogEntry> logs) {
  if (logs.isEmpty) return [];
  logs.sort((a, b) => a.date.compareTo(b.date));
  final lastDate = logs.last.date;
  return logs
      .where((l) => l.date.isAtSameMomentAs(lastDate))
      .toList()
    ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
}

List<WorkoutLogEntry> _bestLogs(List<WorkoutLogEntry> logs) {
  if (logs.isEmpty) return [];

  final grouped = <DateTime, List<WorkoutLogEntry>>{};
  for (final l in logs) {
    grouped.putIfAbsent(l.date, () => []).add(l);
  }

  double tonnage(List<WorkoutLogEntry> ls) =>
      ls.fold(0, (sum, e) => sum + e.reps * e.weight);

  DateTime bestDate = grouped.keys.first;
  double bestTon = tonnage(grouped[bestDate]!);
  grouped.forEach((date, ls) {
    final t = tonnage(ls);
    if (t > bestTon) {
      bestTon = t;
      bestDate = date;
    }
  });

  final bestLogs = grouped[bestDate]!;
  bestLogs.sort((a, b) => a.setNumber.compareTo(b.setNumber));
  return bestLogs;
}
