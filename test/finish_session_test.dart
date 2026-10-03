import 'package:fit_log/src/features/routines/presentation/models/finish_session_summary_draft.dart';
import 'package:fit_log/src/features/routines/presentation/pages/finish_session_summary_screen.dart';
import 'package:fit_log/src/theme/kinetic_noir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pumpFinishScreen(
  WidgetTester tester, {
  required FinishSessionSummaryDraft draft,
  double textScale = 1.0,
  Size surfaceSize = const Size(375, 667),
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool disableAnimations = false,
  void Function(FinishSessionSummaryResult? result)? onResult,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: KineticNoirPalette.background,
        ),
        builder: (context, childWidget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
            disableAnimations: disableAnimations,
          ),
          child: childWidget!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: KineticNoirPalette.background,
            body: Center(
              child: ElevatedButton(
                key: const Key('open-finish-button'),
                onPressed: () async {
                  final res = await Navigator.of(context)
                      .push<FinishSessionSummaryResult>(
                    MaterialPageRoute(
                      builder: (_) => FinishSessionSummaryScreen(draft: draft),
                    ),
                  );
                  onResult?.call(res);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('open-finish-button')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testDraft = FinishSessionSummaryDraft(
    planName: 'Hypertrophy Day A',
    duration: Duration(minutes: 52),
    volumeKg: 1650,
    completedSets: 12,
    totalSets: 12,
    notes: '',
    energy: null,
    mood: null,
  );

  group('FinishSessionSummaryScreen - Visual, Layout & Accessibility', () {
    testWidgets(
        'fits summary, energy 1-10, mood 1-5 and action buttons in 375x667 normal viewport without scroll',
        (tester) async {
      await _pumpFinishScreen(tester, draft: testDraft);

      // Verify header and wordmark
      expect(find.byKey(const Key('finish-session-title')), findsOneWidget);
      expect(find.text('Session review'), findsOneWidget);
      expect(find.text('Hypertrophy Day A • Ready to save'), findsOneWidget);

      // Verify compact summary band
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('52'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('1.6k'), findsOneWidget);
      expect(find.text('SETS'), findsOneWidget);
      expect(find.text('12/12'), findsOneWidget);

      // Verify all 10 energy chips satisfy Android >= 48x48dp minimum hit target
      for (var i = 1; i <= 10; i++) {
        final chipFinder = find.byKey(Key('finish-energy-$i'));
        expect(chipFinder, findsOneWidget);
        final chipSize = tester.getSize(chipFinder);
        expect(chipSize.width, greaterThanOrEqualTo(48.0),
            reason: 'Energy chip $i width must be >= 48dp');
        expect(chipSize.height, greaterThanOrEqualTo(48.0),
            reason: 'Energy chip $i height must be >= 48dp');
      }

      // Verify all 5 mood buttons satisfy Android >= 48x48dp minimum hit target
      for (var i = 1; i <= 5; i++) {
        final moodFinder = find.byKey(Key('finish-mood-$i'));
        expect(moodFinder, findsOneWidget);
        final moodSize = tester.getSize(moodFinder);
        expect(moodSize.width, greaterThanOrEqualTo(48.0),
            reason: 'Mood button $i width must be >= 48dp');
        expect(moodSize.height, greaterThanOrEqualTo(48.0),
            reason: 'Mood button $i height must be >= 48dp');
      }

      // Verify required fields (summary, energy, mood, save button) fit without scrolling at 375x667
      final energy10Bottom =
          tester.getBottomRight(find.byKey(const Key('finish-energy-10'))).dy;
      final mood5Bottom =
          tester.getBottomRight(find.byKey(const Key('finish-mood-5'))).dy;
      final saveButtonBottom =
          tester.getBottomRight(find.byKey(const Key('finish-save-button'))).dy;

      expect(energy10Bottom, lessThanOrEqualTo(667.0),
          reason: 'Energy chips must fit within 375x667 viewport');
      expect(mood5Bottom, lessThanOrEqualTo(667.0),
          reason: 'Mood buttons must fit within 375x667 viewport');
      expect(saveButtonBottom, lessThanOrEqualTo(667.0),
          reason: 'Save button must fit within 375x667 viewport');
    });

    testWidgets(
        'progressive disclosure expands and collapses notes without overflowing',
        (tester) async {
      await _pumpFinishScreen(tester, draft: testDraft);

      // Notes should be initially collapsed
      expect(find.byKey(const Key('finish-expand-notes-button')), findsOneWidget);
      expect(find.byKey(const Key('finish-session-notes')), findsNothing);

      // Tap to expand notes
      await tester.tap(find.byKey(const Key('finish-expand-notes-button')));
      await tester.pumpAndSettle();

      // TextField is now visible
      expect(find.byKey(const Key('finish-session-notes')), findsOneWidget);
      expect(find.text('COLLAPSE'), findsOneWidget);

      // Enter notes
      await tester.enterText(
          find.byKey(const Key('finish-session-notes')), 'Great leg session');
      await tester.pump();

      // Collapse notes
      await tester.ensureVisible(find.text('COLLAPSE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('COLLAPSE'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('finish-expand-notes-button')), findsOneWidget);
      expect(find.byKey(const Key('finish-session-notes')), findsNothing);
    });

    testWidgets(
        'renders cleanly under 1.8x text scale and keyboard IME without overflow',
        (tester) async {
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        textScale: 1.8,
        viewInsets: const EdgeInsets.only(bottom: 240),
      );

      expect(find.byKey(const Key('finish-session-title')), findsOneWidget);
      expect(find.byKey(const Key('finish-save-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'respects reduced motion when animations are disabled',
        (tester) async {
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        disableAnimations: true,
      );

      // Select energy and mood
      await tester.tap(find.byKey(const Key('finish-energy-7')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('finish-mood-4')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('FinishSessionSummaryScreen - Discard Modal & Navigation Protection', () {
    testWidgets(
        'discard button opens warning sheet with KEEP WORKOUT and DISCARD options',
        (tester) async {
      FinishSessionSummaryResult? result;
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        onResult: (res) => result = res,
      );

      // Tap discard
      await tester.tap(find.byKey(const Key('finish-discard-button')));
      await tester.pumpAndSettle();

      // Verify modal contents
      expect(find.byKey(const Key('confirm-discard-title')), findsOneWidget);
      expect(find.text('Discard session?'), findsOneWidget);
      expect(find.byKey(const Key('confirm-discard-cancel')), findsOneWidget);
      expect(find.byKey(const Key('confirm-discard-confirm')), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets(
        'canceling discard sheet with KEEP WORKOUT preserves finish screen and session',
        (tester) async {
      FinishSessionSummaryResult? result;
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        onResult: (res) => result = res,
      );

      await tester.tap(find.byKey(const Key('finish-discard-button')));
      await tester.pumpAndSettle();

      // Tap KEEP WORKOUT
      await tester.tap(find.byKey(const Key('confirm-discard-cancel')));
      await tester.pumpAndSettle();

      // Modal closed, finish screen still open
      expect(find.byKey(const Key('confirm-discard-title')), findsNothing);
      expect(find.byKey(const Key('finish-session-title')), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets(
        'barrier dismissal of discard sheet does not discard and preserves session',
        (tester) async {
      FinishSessionSummaryResult? result;
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        onResult: (res) => result = res,
      );

      await tester.tap(find.byKey(const Key('finish-discard-button')));
      await tester.pumpAndSettle();

      // Tap outside sheet to dismiss barrier
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Modal dismissed, finish screen still open
      expect(find.byKey(const Key('confirm-discard-title')), findsNothing);
      expect(find.byKey(const Key('finish-session-title')), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets(
        'confirming discard sheet pops with discard action',
        (tester) async {
      FinishSessionSummaryResult? result;
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        onResult: (res) => result = res,
      );

      await tester.tap(find.byKey(const Key('finish-discard-button')));
      await tester.pumpAndSettle();

      // Confirm discard
      await tester.tap(find.byKey(const Key('confirm-discard-confirm')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.action, FinishSessionSummaryAction.discard);
    });

    testWidgets(
        'AppBar close button pops with resume action preserving entered notes',
        (tester) async {
      FinishSessionSummaryResult? result;
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        onResult: (res) => result = res,
      );

      // Select energy 8
      await tester.tap(find.byKey(const Key('finish-energy-8')));
      await tester.pump();

      // Expand notes and enter text
      await tester.tap(find.byKey(const Key('finish-expand-notes-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('finish-session-notes')), 'Notes to resume');
      await tester.pump();

      // Tap AppBar close ("X")
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.action, FinishSessionSummaryAction.resume);
      expect(result!.energy, '8');
      expect(result!.notes, 'Notes to resume');
    });

    testWidgets(
        'save and finish validates energy and mood selection before enabling save',
        (tester) async {
      FinishSessionSummaryResult? result;
      await _pumpFinishScreen(
        tester,
        draft: testDraft,
        onResult: (res) => result = res,
      );

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('finish-save-button')),
      );
      // Initially neither energy nor mood is selected: save must be disabled
      expect(saveButton.onPressed, isNull);

      // Select only energy
      await tester.tap(find.byKey(const Key('finish-energy-9')));
      await tester.pump();

      final saveButtonAfterEnergy = tester.widget<FilledButton>(
        find.byKey(const Key('finish-save-button')),
      );
      expect(saveButtonAfterEnergy.onPressed, isNull);

      // Select mood
      await tester.tap(find.byKey(const Key('finish-mood-5')));
      await tester.pump();

      final saveButtonReady = tester.widget<FilledButton>(
        find.byKey(const Key('finish-save-button')),
      );
      expect(saveButtonReady.onPressed, isNotNull);

      // Tap save
      await tester.tap(find.byKey(const Key('finish-save-button')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.action, FinishSessionSummaryAction.save);
      expect(result!.energy, '9');
      expect(result!.mood, '5');
    });
  });
}
