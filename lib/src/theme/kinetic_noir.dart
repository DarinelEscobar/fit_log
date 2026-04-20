import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final class KineticNoirPalette {
  static const background = Color(0xFF0E0E0F);
  static const surface = Color(0xFF1A191B);
  static const surfaceLow = Color(0xFF131314);
  static const surfaceBright = Color(0xFF2C2C2D);
  static const outlineVariant = Color(0xFF484849);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFADAAAB);
  static const primary = Color(0xFFCC97FF);
  static const primaryDim = Color(0xFF9C48EA);
  static const onPrimary = Color(0xFF47007C);
  static const error = Color(0xFFFF6E84);
  static const shadow = Color(0xFF842CD3);
}

final class KineticNoirSpacing {
  static const page = EdgeInsets.symmetric(horizontal: 24);
  static const floatingNav = EdgeInsets.fromLTRB(16, 0, 16, 12);
}

final class KineticNoirTypography {
  static TextStyle headline({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = KineticNoirPalette.onSurface,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w500,
    Color color = KineticNoirPalette.onSurface,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

LinearGradient get kineticPrimaryGradient => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        KineticNoirPalette.primary,
        Color(0xFFB77AF3),
      ],
    );

BoxDecoration get kineticFloatingNavDecoration => BoxDecoration(
      color: KineticNoirPalette.surface.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.15),
      ),
      boxShadow: [
        BoxShadow(
          color: KineticNoirPalette.shadow.withValues(alpha: 0.06),
          blurRadius: 32,
          offset: const Offset(0, -12),
        ),
      ],
    );
