import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/data/providers/workout_storage_service_provider.dart';
import 'src/app.dart';
import 'src/system_ui/fullscreen_controller.dart';
import 'src/utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await applyFullscreenSystemUi();
  runApp(const ProviderScope(
      child: FullscreenBootstrap(child: FitLogBootstrap())));
}

/// Paint the app before opening storage so startup never fails to a black screen.
class FitLogBootstrap extends ConsumerStatefulWidget {
  const FitLogBootstrap({super.key});
  @override
  ConsumerState<FitLogBootstrap> createState() => _FitLogBootstrapState();
}

class _FitLogBootstrapState extends ConsumerState<FitLogBootstrap> {
  late Future<void> _startup;
  @override
  void initState() {
    super.initState();
    _startup = _initialize();
  }

  Future<void> _initialize() async {
    await ref.read(workoutStorageServiceProvider).warmUpRoutineRuntimeCache();
    try {
      await NotificationService.init();
    } catch (error) {
      // Notification permission/plugin failures must not prevent data access.
      debugPrint('Notification initialization unavailable: $error');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _startup,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return const MyApp();
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                  child: Padding(
                padding: const EdgeInsets.all(28),
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storage_rounded, size: 36),
                          const SizedBox(height: 16),
                          const Text('Unable to open your saved data',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          const Text(
                              'Your data has been kept. Retry opening FitLog. Keep your backup; clearing app data is not required.',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: () =>
                                  setState(() => _startup = _initialize()),
                              child: const Text('Retry')),
                        ],
                      )
                    : const Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Opening your saved workouts…'),
                      ]),
              )),
            ),
          );
        },
      );
}
