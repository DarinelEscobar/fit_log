import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:fit_log/src/features/app_data/domain/entities/export_models.dart';
import 'package:fit_log/src/features/app_data/domain/repositories/app_data_repository.dart';
import 'package:fit_log/src/features/app_data/presentation/pages/data_screen.dart';
import 'package:fit_log/src/features/app_data/presentation/providers/app_data_providers.dart';
import 'package:fit_log/src/navigation/widgets/kinetic_bottom_nav_bar.dart';
import 'package:fit_log/src/theme/kinetic_noir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class _FakeBackupShareService implements BackupShareService {
  ShareResultStatus resultStatus = ShareResultStatus.success;
  bool shouldThrow = false;
  File? lastSharedFile;
  int shareCallCount = 0;

  @override
  Future<ShareResult> shareBackupFile(File file) async {
    shareCallCount++;
    lastSharedFile = file;
    if (shouldThrow) {
      throw Exception('Share sheet failed to initialize');
    }
    return ShareResult('fake_raw', resultStatus);
  }
}

class _FakeAppDataRepository implements AppDataRepository {
  _FakeAppDataRepository({
    this.availability = const ExportAvailability(
      firstDate: null,
      lastDate: null,
      nextMissingRange: null,
      lastExportedDate: null,
      hasExportHistory: false,
    ),
    required this.fileToReturn,
  });

  ExportAvailability availability;
  final File fileToReturn;
  ExportRequest? lastExportRequest;
  int exportCallCount = 0;
  bool exportShouldThrow = false;
  Completer<void>? importGate;
  int importCallCount = 0;

  @override
  Future<ExportAvailability> getExportAvailability() async => availability;

  @override
  Future<File> exportData({
    ExportRequest request = const ExportRequest.automatic(),
  }) async {
    exportCallCount++;
    lastExportRequest = request;
    if (exportShouldThrow) {
      throw StateError('Disk write error during export');
    }
    return fileToReturn;
  }

  @override
  Future<void> importData(File file) async {
    importCallCount++;
    await importGate?.future;
  }
}

class _TestFilePicker extends FilePicker {
  _TestFilePicker(this.file);
  final File file;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      FilePickerResult([
        PlatformFile(name: p.basename(file.path), path: file.path, size: 3)
      ]);
}

class _TestAssetManifest implements AssetManifest {
  static const fontAssets = [
    'google_fonts/SpaceGrotesk-Regular.ttf',
    'google_fonts/SpaceGrotesk-Bold.ttf',
    'google_fonts/SpaceGrotesk-Medium.ttf',
    'google_fonts/SpaceGrotesk-SemiBold.ttf',
    'google_fonts/SpaceGrotesk-Light.ttf',
    'google_fonts/Manrope-Regular.ttf',
    'google_fonts/Manrope-Bold.ttf',
    'google_fonts/Manrope-Medium.ttf',
    'google_fonts/Manrope-SemiBold.ttf',
    'google_fonts/Manrope-ExtraBold.ttf',
    'google_fonts/Manrope-Light.ttf',
    'google_fonts/Manrope-ExtraLight.ttf',
  ];

  @override
  List<String> listAssets() => fontAssets;

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  late Directory tempDocsDir;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    google_fonts_base.assetManifest = _TestAssetManifest();
    final fontFile = File(
      r'C:\src\flutter\bin\cache\artifacts\material_fonts\roboto-bold.ttf',
    );
    if (fontFile.existsSync()) {
      final fontBytes = fontFile.readAsBytesSync();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        return ByteData.view(fontBytes.buffer);
      });
    }
  });

  setUp(() {
    tempDocsDir = Directory.systemTemp.createTempSync('data_test_docs_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getTemporaryDirectory':
        case 'getApplicationSupportDirectory':
          return tempDocsDir.path;
        default:
          return tempDocsDir.path;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    try {
      if (tempDocsDir.existsSync()) {
        tempDocsDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('DataScreen Unified Export and Share Backup Tests', () {
    testWidgets('shows unified Export & Share Backup action and Import Backup',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
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
            home: const Scaffold(body: DataScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export & Share Backup'), findsOneWidget);
      expect(find.byKey(const Key('export-share-backup-card')), findsOneWidget);
      expect(find.text('Import Backup'), findsOneWidget);
      expect(find.byType(KineticBottomNavBar), findsNothing);
    });

    testWidgets('cancels export when range dialog is dismissed',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyFile = File(p.join(tempDocsDir.path, 'fitlog_backup.zip'));
      dummyFile.writeAsBytesSync([1, 2, 3]);

      final fakeShare = _FakeBackupShareService();
      final fakeRepo = _FakeAppDataRepository(
        availability: ExportAvailability(
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 1, 15),
          nextMissingRange: ExportDateRange(
            DateTime(2026, 1, 10),
            DateTime(2026, 1, 15),
          ),
          lastExportedDate: DateTime(2026, 1, 9),
          hasExportHistory: true,
        ),
        fileToReturn: dummyFile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDataRepositoryProvider.overrideWithValue(fakeRepo),
            backupShareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: KineticNoirPalette.background,
            ),
            home: const Scaffold(body: DataScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-share-backup-card')));
      await tester.pumpAndSettle();

      expect(find.text('Choose export range'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Choose export range'), findsNothing);
      expect(fakeRepo.exportCallCount, 0);
      expect(fakeShare.shareCallCount, 0);
    });

    testWidgets('generates backup and automatically opens share sheet',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyFile = File(p.join(tempDocsDir.path, 'fitlog_backup.zip'));
      dummyFile.writeAsBytesSync([1, 2, 3]);

      final fakeShare = _FakeBackupShareService();
      final fakeRepo = _FakeAppDataRepository(
        availability: ExportAvailability(
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 1, 15),
          nextMissingRange: ExportDateRange(
            DateTime(2026, 1, 10),
            DateTime(2026, 1, 15),
          ),
          lastExportedDate: DateTime(2026, 1, 9),
          hasExportHistory: true,
        ),
        fileToReturn: dummyFile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDataRepositoryProvider.overrideWithValue(fakeRepo),
            backupShareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: KineticNoirPalette.background,
            ),
            home: const Scaffold(body: DataScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-share-backup-card')));
      await tester.pumpAndSettle();

      expect(find.text('SELECTED RANGE'), findsOneWidget);
      expect(find.text('AUTOMATIC INCREMENTAL'), findsOneWidget);

      await tester.tap(find.text('Export & Share'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.exportCallCount, 1);
      expect(fakeRepo.lastExportRequest?.mode, ExportRangeMode.automatic);
      expect(fakeShare.shareCallCount, 1);
      expect(fakeShare.lastSharedFile?.path, dummyFile.path);
      expect(find.text('Backup exported and shared'), findsOneWidget);
    });

    testWidgets('does not announce as shared when share sheet is dismissed',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyFile = File(p.join(tempDocsDir.path, 'fitlog_backup.zip'));
      dummyFile.writeAsBytesSync([1, 2, 3]);

      final fakeShare = _FakeBackupShareService()
        ..resultStatus = ShareResultStatus.dismissed;
      final fakeRepo = _FakeAppDataRepository(
        availability: ExportAvailability(
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 1, 15),
          nextMissingRange: ExportDateRange(
            DateTime(2026, 1, 10),
            DateTime(2026, 1, 15),
          ),
          lastExportedDate: DateTime(2026, 1, 9),
          hasExportHistory: true,
        ),
        fileToReturn: dummyFile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDataRepositoryProvider.overrideWithValue(fakeRepo),
            backupShareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: KineticNoirPalette.background,
            ),
            home: const Scaffold(body: DataScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-share-backup-card')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export & Share'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.exportCallCount, 1);
      expect(fakeShare.shareCallCount, 1);
      expect(find.text('Backup exported and shared'), findsNothing);
      expect(find.text('Backup saved locally'), findsOneWidget);
      expect(find.textContaining('Sharing was cancelled.'), findsOneWidget);
    });

    testWidgets('export failure shows error and does not call share',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyFile = File(p.join(tempDocsDir.path, 'fitlog_backup.zip'));

      final fakeShare = _FakeBackupShareService();
      final fakeRepo = _FakeAppDataRepository(
        availability: ExportAvailability(
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 1, 15),
          nextMissingRange: ExportDateRange(
            DateTime(2026, 1, 10),
            DateTime(2026, 1, 15),
          ),
          lastExportedDate: DateTime(2026, 1, 9),
          hasExportHistory: true,
        ),
        fileToReturn: dummyFile,
      )..exportShouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDataRepositoryProvider.overrideWithValue(fakeRepo),
            backupShareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: KineticNoirPalette.background,
            ),
            home: const Scaffold(body: DataScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-share-backup-card')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export & Share'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.exportCallCount, 1);
      expect(fakeShare.shareCallCount, 0);
      expect(find.text('Export failed'), findsOneWidget);
      expect(find.text('Backup exported and shared'), findsNothing);
      expect(find.text('Backup saved locally'), findsNothing);
    });

    testWidgets(
        'full backup preset updates range preview and submits full request',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyFile = File(p.join(tempDocsDir.path, 'fitlog_backup.zip'));
      dummyFile.writeAsBytesSync([1, 2, 3]);

      final fakeShare = _FakeBackupShareService();
      final fakeRepo = _FakeAppDataRepository(
        availability: ExportAvailability(
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 1, 15),
          nextMissingRange: ExportDateRange(
            DateTime(2026, 1, 10),
            DateTime(2026, 1, 15),
          ),
          lastExportedDate: DateTime(2026, 1, 9),
          hasExportHistory: true,
        ),
        fileToReturn: dummyFile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDataRepositoryProvider.overrideWithValue(fakeRepo),
            backupShareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: KineticNoirPalette.background,
            ),
            home: const Scaffold(body: DataScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-share-backup-card')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Full backup (all history)'));
      await tester.pumpAndSettle();

      expect(find.text('FULL BACKUP'), findsOneWidget);
      expect(find.textContaining('Full DB & spreadsheets'), findsWidgets);

      await tester.tap(find.text('Export & Share'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.exportCallCount, 1);
      expect(fakeRepo.lastExportRequest?.mode, ExportRangeMode.full);
      expect(fakeShare.shareCallCount, 1);
    });

    testWidgets(
        'import blocks other actions and system back until data has refreshed',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final file = File(p.join(tempDocsDir.path, 'restore.zip'))
        ..writeAsBytesSync([1, 2, 3]);
      final originalPicker = _TestFilePicker(file);
      FilePicker.platform = _TestFilePicker(file);
      addTearDown(() => FilePicker.platform = originalPicker);
      final gate = Completer<void>();
      final repo = _FakeAppDataRepository(fileToReturn: file)
        ..importGate = gate;
      await tester.pumpWidget(ProviderScope(
          overrides: [appDataRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: DataScreen())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-backup-card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Import').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.importCallCount, 1);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const Key('export-share-backup-card')),
          warnIfMissed: false);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(repo.exportCallCount, 0);
      expect(find.byType(DataScreen), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Data imported'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('busy state prevents double export on multiple taps',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dummyFile = File(p.join(tempDocsDir.path, 'fitlog_backup.zip'));
      dummyFile.writeAsBytesSync([1, 2, 3]);

      final fakeShare = _FakeBackupShareService();
      final fakeRepo = _FakeAppDataRepository(
        availability: const ExportAvailability(
          firstDate: null,
          lastDate: null,
          nextMissingRange: null,
          lastExportedDate: null,
          hasExportHistory: false,
        ),
        fileToReturn: dummyFile,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDataRepositoryProvider.overrideWithValue(fakeRepo),
            backupShareServiceProvider.overrideWithValue(fakeShare),
          ],
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: KineticNoirPalette.background,
            ),
            home: const Scaffold(body: DataScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-share-backup-card')));
      await tester.pumpAndSettle();

      expect(find.text('Choose export range'), findsOneWidget);

      await tester.tap(find.text('Export & Share'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('export-share-backup-card')),
          warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.exportCallCount, 1);
      expect(fakeShare.shareCallCount, 1);
    });
  });
}
