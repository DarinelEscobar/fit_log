import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fit_log/src/features/app_data/presentation/pages/data_screen.dart';

void main() {
  testWidgets('Data screen shows backup actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DataScreen(),
        ),
      ),
    );

    expect(find.text('Exportar Datos'), findsOneWidget);
    expect(find.text('Compartir Backup'), findsOneWidget);
    expect(find.text('Importar Datos'), findsOneWidget);
  });
}
