import 'package:flutter/material.dart';

import 'navigation/main_scaffold.dart';

import 'system_ui/fullscreen_controller.dart';

import 'theme/kinetic_noir.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: KineticNoirPalette.primary,
      onPrimary: KineticNoirPalette.onPrimary,
      secondary: KineticNoirPalette.primary,
      onSecondary: KineticNoirPalette.onPrimary,
      error: KineticNoirPalette.error,
      onError: Color(0xFF0F0F10),
      surface: KineticNoirPalette.surface,
      onSurface: KineticNoirPalette.onSurface,
      onSurfaceVariant: KineticNoirPalette.onSurfaceVariant,
      outline: Color(0xFF323232),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E6E6),
      onInverseSurface: Color(0xFF141414),
      inversePrimary: Color(0xFF5854D6),
      surfaceTint: Colors.transparent,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fit Log',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: KineticNoirPalette.background,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: KineticNoirPalette.onSurface,
              displayColor: KineticNoirPalette.onSurface,
              fontFamily: KineticNoirTypography.body(size: 14).fontFamily,
            ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle:
                KineticNoirTypography.body(size: 13, weight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: KineticNoirPalette.onSurface,
            side: const BorderSide(color: KineticNoirPalette.outlineVariant),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: KineticNoirPalette.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          barrierColor: Colors.black.withValues(alpha: 0.65),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.4)),
          ),
          titleTextStyle: KineticNoirTypography.headline(size: 22),
          contentTextStyle: KineticNoirTypography.body(size: 14, height: 1.5),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: KineticNoirPalette.surface,
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: KineticNoirPalette.surface,
          modalBarrierColor: Color(0xA6000000),
          showDragHandle: false,
          constraints: BoxConstraints(maxWidth: 640),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: KineticNoirPalette.surfaceLow,
          selectedColor: KineticNoirPalette.primary.withValues(alpha: 0.18),
          checkmarkColor: KineticNoirPalette.primary,
          labelStyle:
              KineticNoirTypography.body(size: 12, weight: FontWeight.w700),
          side: BorderSide(
              color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.35)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: KineticNoirPalette.surfaceBright,
          contentTextStyle: KineticNoirTypography.body(size: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: KineticNoirPalette.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: kineticFullscreenOverlayStyle,
          titleTextStyle: TextStyle(
            color: Color(0xFFF2F2F2),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          iconColor: Color(0xFF9E9E9E),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          indicatorColor: const Color(0xFF2A2A2A),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFF9A9A9A),
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFF8A8A8A),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: KineticNoirPalette.primary,
          foregroundColor: KineticNoirPalette.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222222),
          hintStyle:
              const TextStyle(color: KineticNoirPalette.onSurfaceVariant),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: KineticNoirPalette.primary, width: 1.2),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2E2E2E),
          thickness: 1,
          space: 24,
        ),
      ),
      home: const MainScaffold(),
    );
  }
}
