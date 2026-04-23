import 'package:flutter/material.dart';
import '../../../../theme/kinetic_noir.dart';
import '../../../../theme/toru_brand.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    required this.onOpenDataManagement,
    required this.onOpenRoutines,
    super.key,
  });

  final VoidCallback onOpenDataManagement;
  final VoidCallback onOpenRoutines;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KineticNoirPalette.background,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 28),
              Text.rich(
                key: const Key('home-hero-title'),
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'WELCOME TO ',
                      style: KineticNoirTypography.headline(
                        size: 47,
                        weight: FontWeight.w700,
                        height: 0.95,
                      ),
                    ),
                    TextSpan(
                      text: 'FIT\nLOG',
                      style: KineticNoirTypography.headline(
                        size: 47,
                        weight: FontWeight.w700,
                        height: 0.95,
                        color: KineticNoirPalette.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  'Track your workouts, monitor your progress, and stay consistent.',
                  style: KineticNoirTypography.body(
                    size: 17,
                    weight: FontWeight.w500,
                    color: KineticNoirPalette.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              _StartTrackingCard(onOpenRoutines: onOpenRoutines),
              const SizedBox(height: 34),
              const _SectionLabel(label: 'Data Management'),
              const SizedBox(height: 18),
              _DataManagementCard(onTap: onOpenDataManagement),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.menu_rounded, color: KineticNoirPalette.primary, size: 22),
        SizedBox(width: 14),
        FitLogWordmark(),
        Spacer(),
        Icon(
          Icons.more_vert_rounded,
          color: KineticNoirPalette.onSurfaceVariant,
          size: 22,
        ),
      ],
    );
  }
}

class _StartTrackingCard extends StatelessWidget {
  const _StartTrackingCard({required this.onOpenRoutines});

  final VoidCallback onOpenRoutines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          left: BorderSide(color: KineticNoirPalette.primary, width: 2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            const Positioned(
              right: 2,
              top: 0,
              child: _PatternIcon(offset: Offset(0, 0)),
            ),
            const Positioned(
              right: -22,
              bottom: 8,
              child: _PatternIcon(offset: Offset(0, 0)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START TRACKING',
                    style: KineticNoirTypography.headline(
                      size: 30,
                      weight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 248),
                    child: Text(
                      'Select a routine from your library to begin logging your session.',
                      style: KineticNoirTypography.body(
                        size: 15,
                        weight: FontWeight.w500,
                        color: KineticNoirPalette.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: KineticNoirPalette.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton(
                        key: const Key('home-view-routines'),
                        onPressed: onOpenRoutines,
                        style: TextButton.styleFrom(
                          foregroundColor: KineticNoirPalette.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'VIEW WORKOUT\nROUTINES',
                                textAlign: TextAlign.center,
                                style: KineticNoirTypography.body(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: KineticNoirPalette.onPrimary,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternIcon extends StatelessWidget {
  const _PatternIcon({required this.offset});

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Icon(
        Icons.close_rounded,
        size: 88,
        color: KineticNoirPalette.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: KineticNoirTypography.body(
            size: 13,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home-manage-data'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: KineticNoirPalette.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_upload_rounded,
                color: KineticNoirPalette.primary,
                size: 22,
              ),
              const SizedBox(height: 18),
              Text(
                'DATA & BACKUPS',
                style: KineticNoirTypography.headline(
                  size: 24,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Manage your local data. Export your workout history to JSON for safekeeping, or import a previous backup.',
                style: KineticNoirTypography.body(
                  size: 15,
                  weight: FontWeight.w500,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MANAGE DATA',
                    style: KineticNoirTypography.body(
                      size: 12,
                      weight: FontWeight.w800,
                      color: KineticNoirPalette.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: KineticNoirPalette.primary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
