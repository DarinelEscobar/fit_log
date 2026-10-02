import 'package:flutter/material.dart';

import '../../../../theme/kinetic_noir.dart';

Future<bool> showConfirmExitSheet(BuildContext context) async {
  return (await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (sheetContext) {
          final isLargeText =
              MediaQuery.textScalerOf(sheetContext).scale(12) > 17 ||
                  MediaQuery.sizeOf(sheetContext).width < 340;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: KineticNoirPalette.surfaceLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: KineticNoirPalette.outlineVariant
                        .withValues(alpha: 0.22),
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
                            color: KineticNoirPalette.error
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: KineticNoirPalette.error
                                  .withValues(alpha: 0.28),
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
                        style: KineticNoirTypography.headline(
                          size: 24,
                          height: 1.2,
                        ),
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
                      const SizedBox(height: 24),
                      if (isLargeText) ...[
                        FilledButton(
                          key: const Key('confirm-exit-exit'),
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor: KineticNoirPalette.error,
                            foregroundColor: KineticNoirPalette.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                        const SizedBox(height: 12),
                        OutlinedButton(
                          key: const Key('confirm-exit-stay'),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            foregroundColor:
                                KineticNoirPalette.onSurfaceVariant,
                            side: BorderSide(
                              color: KineticNoirPalette.outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('confirm-exit-stay'),
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(false),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  foregroundColor:
                                      KineticNoirPalette.onSurfaceVariant,
                                  side: BorderSide(
                                    color: KineticNoirPalette.outlineVariant
                                        .withValues(alpha: 0.35),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(true),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  backgroundColor: KineticNoirPalette.error,
                                  foregroundColor: KineticNoirPalette.onSurface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      )) ??
      false;
}
