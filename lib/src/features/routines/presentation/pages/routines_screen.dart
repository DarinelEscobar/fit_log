import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../widgets/add_routine_button.dart';
import '../widgets/deactivated_routines_dropdown.dart';
import '../widgets/routine_library_card.dart';

class RoutinesScreen extends ConsumerWidget {
  static const routeName = '/routines';

  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlans = ref.watch(workoutPlanProvider);

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      floatingActionButton: const AddRoutineButton(),
      body: SafeArea(
        bottom: false,
        child: asyncPlans.when(
          data: (plans) {
            final activePlans = plans.where((plan) => plan.isActive).toList()
              ..sort((a, b) {
                final nameCompare = a.name.trim().toLowerCase().compareTo(
                      b.name.trim().toLowerCase(),
                    );
                if (nameCompare != 0) return nameCompare;
                return a.id.compareTo(b.id);
              });
            final inactivePlans = plans.where((plan) => !plan.isActive).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 180),
              children: [
                const _TopBar(),
                const SizedBox(height: 28),
                Text(
                  'My Routines',
                  style: KineticNoirTypography.headline(
                    size: 40,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Manage your weekly performance blueprint.',
                  style: KineticNoirTypography.body(
                    size: 16,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 34),
                Row(
                  children: [
                    Text(
                      'ACTIVE ROUTINES',
                      style: KineticNoirTypography.body(
                        size: 12,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            KineticNoirPalette.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${activePlans.length} ACTIVE',
                        style: KineticNoirTypography.body(
                          size: 10,
                          weight: FontWeight.w800,
                          color: KineticNoirPalette.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (activePlans.isEmpty)
                  const _EmptyStateCard()
                else
                  for (final plan in activePlans) ...[
                    RoutineLibraryCard(
                      plan: plan,
                      onToggleActive: () => ref
                          .read(workoutPlanProvider.notifier)
                          .setPlanActive(plan.id, false),
                    ),
                    const SizedBox(height: 16),
                  ],
                const SizedBox(height: 30),
                Container(
                  height: 1,
                  color:
                      KineticNoirPalette.outlineVariant.withValues(alpha: 0.16),
                ),
                const SizedBox(height: 18),
                DeactivatedRoutinesDropdown(
                  plans: inactivePlans,
                  onActivate: (planId) => ref
                      .read(workoutPlanProvider.notifier)
                      .setPlanActive(planId, true),
                ),
              ],
            );
          },
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(message: '$error'),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.menu_rounded,
            color: KineticNoirPalette.primary, size: 22),
        const SizedBox(width: 14),
        Text(
          'FIT LOG',
          style: KineticNoirTypography.headline(
            size: 24,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.more_vert_rounded,
          color: KineticNoirPalette.primary,
          size: 22,
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            size: 38,
            color: KineticNoirPalette.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No active routines yet',
            style: KineticNoirTypography.headline(
              size: 24,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create one with the floating action button to start building your training library.',
            textAlign: TextAlign.center,
            style: KineticNoirTypography.body(
              size: 14,
              weight: FontWeight.w600,
              color: KineticNoirPalette.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: KineticNoirPalette.primary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Unable to load routines.\n$message',
          textAlign: TextAlign.center,
          style: KineticNoirTypography.body(
            size: 15,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
