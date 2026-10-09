import 'package:fit_log/src/features/routines/presentation/widgets/add_routine_button.dart';
import 'package:fit_log/src/theme/kinetic_noir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the app primary color and a circular shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(floatingActionButton: AddRoutineButton()),
        ),
      ),
    );

    final button = tester.widget<FloatingActionButton>(
      find.byKey(const Key('add-routine-button')),
    );

    expect(button.shape, isA<CircleBorder>());
    expect(button.backgroundColor, KineticNoirPalette.primary);
    expect(button.foregroundColor, KineticNoirPalette.onPrimary);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
