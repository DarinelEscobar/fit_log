import 'dart:async';
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
  static const page = EdgeInsets.symmetric(horizontal: 20);
  static const floatingNav = EdgeInsets.fromLTRB(16, 0, 16, 12);
}

/// Short, event-driven motion; respects the device accessibility setting.
final class KineticMotion {
  static const feedbackMs = 120;
  static const revealMs = 220;
  static const replaceMs = 180;
  static const routeMs = 260;
  static const exitMs = 170;
  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
  static const stateCurve = Curves.easeInOutCubic;

  static Duration duration(BuildContext context, [int milliseconds = 200]) =>
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: milliseconds);
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
          color: KineticNoirPalette.shadow.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, -6),
        ),
      ],
    );


/// Discrete, one-time screen or section entrance respecting reduced motion.
/// Does not replay on parent widget rebuilds or periodic timer updates.
class KineticEntrance extends StatefulWidget {
  const KineticEntrance({
    required this.child,
    this.delayMs = 0,
    this.durationMs = KineticMotion.revealMs,
    this.offset = const Offset(0, 0.04),
    super.key,
  });

  final Widget child;
  final int delayMs;
  final int durationMs;
  final Offset offset;

  @override
  State<KineticEntrance> createState() => _KineticEntranceState();
}

class _KineticEntranceState extends State<KineticEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: KineticMotion.enterCurve,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: KineticMotion.enterCurve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else if (widget.delayMs > 0) {
      _delayTimer = Timer(Duration(milliseconds: widget.delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
