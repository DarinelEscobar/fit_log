import 'package:flutter/material.dart';
import 'navigation/main_scaffold.dart';

import 'system_ui/fullscreen_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8E8CF8),
      onPrimary: Color(0xFF0F0F10),
      secondary: Color(0xFF3DD6C6),
      onSecondary: Color(0xFF0F0F10),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF0F0F10),
      surface: Color(0xFF1A1A1A),
      onSurface: Color(0xFFE6E6E6),
      outline: Color(0xFF323232),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E6E6),
      onInverseSurface: Color(0xFF141414),
      inversePrimary: Color(0xFF5854D6),
      surfaceTint: Color(0xFF8E8CF8),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fit Log',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF141414),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B1B1B),
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
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (states) => TextStyle(
              color: states.contains(MaterialState.selected)
                  ? Colors.white
                  : const Color(0xFF9A9A9A),
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? Colors.white
                  : const Color(0xFF8A8A8A),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8E8CF8),
          foregroundColor: Color(0xFF0F0F10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222222),
          hintStyle: const TextStyle(color: Color(0xFF8A8A8A)),
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
            borderSide: const BorderSide(color: Color(0xFF8E8CF8), width: 1.2),
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
