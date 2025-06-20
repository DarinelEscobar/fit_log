import 'package:flutter_test/flutter_test.dart';
import 'package:fit_log/src/utils/tonnage.dart';
import 'package:fit_log/src/features/routines/domain/entities/set_entry.dart';

void main() {
  test('delta percent from 25 to 30 is +20%', () {
    final today = [SetEntry(reps: 1, weight: 30, rir: 0)];
    final last = [SetEntry(reps: 1, weight: 25, rir: 0)];
    final result = deltaPercent(tonnage(today), tonnage(last));
    expect(result, 20);
  });
}
