import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';

Future<bool> showConfirmExitSheet(BuildContext context) async {
  return (await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: KineticNoirPalette.shadow.withValues(alpha: 0.52),
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceLow,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: KineticNoirPalette.shadow.withValues(alpha: 0.36),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: KineticNoirPalette.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              KineticNoirPalette.error.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: KineticNoirPalette.error,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Exit without saving?',
                    key: const Key('confirm-exit-title'),
                    textAlign: TextAlign.center,
                    style:
                        KineticNoirTypography.headline(size: 28, height: 0.95),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your current session progress will be lost if you leave now.',
                    textAlign: TextAlign.center,
                    style: KineticNoirTypography.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: KineticNoirPalette.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('confirm-exit-stay'),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                KineticNoirPalette.onSurfaceVariant,
                            side: BorderSide(
                              color: KineticNoirPalette.outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'STAY',
                            style: KineticNoirTypography.body(
                              size: 12,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.onSurfaceVariant,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          key: const Key('confirm-exit-exit'),
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: KineticNoirPalette.error,
                            foregroundColor: KineticNoirPalette.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'EXIT SESSION',
                            style: KineticNoirTypography.body(
                              size: 12,
                              weight: FontWeight.w800,
                              color: KineticNoirPalette.onSurface,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      )) ??
      false;
}
