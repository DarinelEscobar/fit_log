import 'package:fit_log/src/features/routines/presentation/widgets/exercise_definition_dialog.dart';
import 'package:fit_log/src/features/routines/services/routine_json_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? clipboardText;

  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final data = call.arguments as Map<dynamic, dynamic>;
          clipboardText = data['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return <String, dynamic>{'text': clipboardText};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('copy prompt is enabled after typing an exercise name', (
    tester,
  ) async {
    await _pumpExerciseDialog(tester);

    expect(_copyPromptButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('exercise-definition-name')),
      'Machine Press',
    );
    await tester.pump();

    expect(_copyPromptButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('exercise-definition-copy-prompt')));
    await tester.pump();

    expect(clipboardText, contains('Exercise name: "Machine Press"'));
    expect(clipboardText, contains('"mainMuscleGroup"'));
    expect(clipboardText, contains('Return valid JSON only'));
    expect(
      find.byKey(const Key('exercise-definition-paste-json')),
      findsOneWidget,
    );
  });

  testWidgets('paste JSON fills exercise fields from the clipboard', (
    tester,
  ) async {
    await _pumpExerciseDialog(tester);

    await tester.enterText(
      find.byKey(const Key('exercise-definition-name')),
      'Machine Press',
    );
    await tester.tap(find.byKey(const Key('exercise-definition-copy-prompt')));
    await tester.pump();

    clipboardText = '''
{
  "name": "Machine Press",
  "category": "Strength",
  "mainMuscleGroup": "Chest",
  "description": "Press the handles forward while keeping your shoulder blades stable. Control the return and keep tension on the chest."
}
''';

    await tester.tap(find.byKey(const Key('exercise-definition-paste-json')));
    await tester.pump();

    expect(_fieldText(tester, 'exercise-definition-name'), 'Machine Press');
    expect(_fieldText(tester, 'exercise-definition-category'), 'Strength');
    expect(_fieldText(tester, 'exercise-definition-muscle'), 'Chest');
    expect(
      _fieldText(tester, 'exercise-definition-description'),
      contains('Press the handles forward'),
    );
  });

  testWidgets('invalid JSON does not overwrite current field values', (
    tester,
  ) async {
    await _pumpExerciseDialog(tester);

    await tester.enterText(
      find.byKey(const Key('exercise-definition-name')),
      'Machine Press',
    );
    await tester.enterText(
      find.byKey(const Key('exercise-definition-category')),
      'Manual Category',
    );
    await tester.tap(find.byKey(const Key('exercise-definition-copy-prompt')));
    await tester.pump();

    clipboardText = '{"name": "Machine Press", "category": ""}';

    await tester.tap(find.byKey(const Key('exercise-definition-paste-json')));
    await tester.pump();

    expect(
      _fieldText(tester, 'exercise-definition-category'),
      'Manual Category',
    );
    expect(
      find.textContaining('Paste a valid exercise JSON'),
      findsOneWidget,
    );
  });

  test('exercise JSON parser accepts main muscle aliases', () {
    final codec = RoutineJsonCodec();

    final groupExercise = codec.parseExerciseJson('''
{
  "name": "Cable Fly",
  "description": "Bring the handles together with control.",
  "category": "Isolation",
  "mainMuscleGroup": "Chest"
}
''');
    final legacyExercise = codec.parseExerciseJson('''
{
  "name": "Cable Row",
  "description": "Pull to the torso while keeping the spine neutral.",
  "category": "Strength",
  "mainMuscle": "Back"
}
''');

    expect(groupExercise?.mainMuscleGroup, 'Chest');
    expect(legacyExercise?.mainMuscleGroup, 'Back');
  });
}

Future<void> _pumpExerciseDialog(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                key: const Key('open-exercise-dialog'),
                onPressed: () {
                  showDialog<ExerciseDefinitionInput>(
                    context: context,
                    builder: (_) => const ExerciseDefinitionDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('open-exercise-dialog')));
  await tester.pumpAndSettle();
}

OutlinedButton _copyPromptButton(WidgetTester tester) {
  return tester.widget<OutlinedButton>(
    find.byKey(const Key('exercise-definition-copy-prompt')),
  );
}

String _fieldText(WidgetTester tester, String keyValue) {
  final field = tester.widget<TextField>(find.byKey(Key(keyValue)));
  return field.controller?.text ?? '';
}
