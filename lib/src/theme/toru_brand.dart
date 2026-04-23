import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'kinetic_noir.dart';

enum ToruMarkVariant {
  green,
  white,
}

class ToruMark extends StatelessWidget {
  const ToruMark({
    required this.size,
    this.variant = ToruMarkVariant.green,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    super.key,
  });

  final double size;
  final ToruMarkVariant variant;
  final double opacity;
  final BoxFit fit;

  String get _assetPath {
    return switch (variant) {
      ToruMarkVariant.green => 'assets/icons/toru_green.svg',
      ToruMarkVariant.white => 'assets/icons/toru_white.svg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0).toDouble(),
      child: SvgPicture.asset(
        _assetPath,
        width: size,
        height: size,
        fit: fit,
      ),
    );
  }
}

class FitLogWordmark extends StatelessWidget {
  const FitLogWordmark({
    this.iconSize = 32,
    this.spacing = 10,
    this.textSize = 24,
    this.textColor = KineticNoirPalette.primary,
    this.variant = ToruMarkVariant.green,
    super.key,
  });

  final double iconSize;
  final double spacing;
  final double textSize;
  final Color textColor;
  final ToruMarkVariant variant;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToruMark(size: iconSize, variant: variant),
        SizedBox(width: spacing),
        Text(
          'FIT LOG',
          style: KineticNoirTypography.headline(
            size: textSize,
            weight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
