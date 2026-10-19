import 'package:fit_log/src/features/check_in/data/check_in_repository.dart';
import 'package:fit_log/src/features/check_in/presentation/check_in_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRepository extends CheckInRepository {
  final rows = <Map<String, String>>[];
  @override
  Future<void> save(Map<String, String> observation) async {
    CheckInRepository.validate(observation);
    rows.add(Map.of(observation));
  }
}

void main() {
  testWidgets(
      'morning capture accepts decimal comma without inventing fasting or measurements',
      (tester) async {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _RecordingRepository();
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            home: CheckInForm(kind: 'morning', repository: repository))));
    await tester.enterText(find.byType(TextFormField).first, '75,3');
    await tester.enterText(find.byType(TextFormField).at(5), '0');
    await tester.ensureVisible(find.text('Guardar registro'));
    await tester.tap(find.text('Guardar registro'));
    await tester.pumpAndSettle();
    expect(repository.rows, hasLength(1));
    expect(repository.rows.single['weight_kg'], '75.3');
    expect(repository.rows.single['water_ml'], '0');
    expect(repository.rows.single['fasted'] ?? '', '');
    expect(repository.rows.single['abdomen_upper_cm'], '');
    expect(tester.takeException(), isNull);
  });
}
