import '../features/routines/domain/entities/set_entry.dart';

/// Returns the sum of reps * weight of each set.
double tonnage(List<SetEntry> sets) =>
    sets.fold(0, (sum, e) => sum + e.reps * e.weight);

/// Returns the percent difference between [today] and [last].
/// Example: 25 -> 30 gives +20%.
int deltaPercent(double today, double last) {
  if (last == 0) return today == 0 ? 0 : 100;
  return (((today - last) / last) * 100).round();
}
