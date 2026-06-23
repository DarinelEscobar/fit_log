import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../theme/toru_brand.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_plan.dart';
import '../providers/exercises_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/workout_plan_provider.dart';
import '../widgets/add_routine_button.dart';
import '../widgets/deactivated_routines_dropdown.dart';
import '../widgets/routine_library_card.dart';
import 'edit_routine_screen.dart';
import 'exercises_screen.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  static const routeName = '/routines';

  const RoutinesScreen({
    required this.onOpenDataManagement,
    super.key,
  });

  final VoidCallback onOpenDataManagement;

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  final Map<int, _RoutineCardMetadata> _metadataByPlanId = {};
  final Set<int> _metadataInFlight = <int>{};
  List<Exercise>? _libraryExercises;
  bool _loadQueued = false;
  int _lastMetadataEpoch = 0;

  @override
  Widget build(BuildContext context) {
    final asyncPlans = ref.watch(workoutPlanProvider);
    final busyPlanIds = ref.watch(routinePlanBusyIdsProvider);
    final metadataEpoch = ref.watch(routineLibraryMetadataEpochProvider);

    if (_lastMetadataEpoch != metadataEpoch) {
      _lastMetadataEpoch = metadataEpoch;
      _metadataByPlanId.clear();
      _metadataInFlight.clear();
      _libraryExercises = null;
    }

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

            _scheduleMetadataLoad(activePlans);

            return CustomScrollView(
              cacheExtent: 600,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(onOpenManage: _openManageSheet),
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
                                color: KineticNoirPalette.primary
                                    .withValues(alpha: 0.12),
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
                      ],
                    ),
                  ),
                ),
                if (activePlans.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(child: _EmptyStateCard()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final plan = activePlans[index];
                          final metadata = _metadataByPlanId[plan.id];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == activePlans.length - 1 ? 0 : 16,
                            ),
                            child: RoutineLibraryCard(
                              plan: plan,
                              exerciseCount: metadata?.exerciseCount ?? 0,
                              muscleGroups: metadata?.groups ?? const [],
                              isBusy: busyPlanIds.contains(plan.id),
                              isMetadataReady: metadata != null,
                              onOpen: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExercisesScreen(plan: plan),
                                  ),
                                );
                              },
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditRoutineScreen(plan: plan),
                                  ),
                                );
                              },
                              onToggleActive: () =>
                                  _togglePlanActive(plan, false),
                            ),
                          );
                        },
                        childCount: activePlans.length,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 180),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          color: KineticNoirPalette.outlineVariant
                              .withValues(alpha: 0.16),
                        ),
                        const SizedBox(height: 18),
                        DeactivatedRoutinesDropdown(
                          plans: inactivePlans,
                          onActivate: (planId) {
                            final plan = inactivePlans.firstWhere(
                              (item) => item.id == planId,
                            );
                            _togglePlanActive(plan, true);
                          },
                        ),
                      ],
                    ),
                  ),
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

  void _scheduleMetadataLoad(List<WorkoutPlan> activePlans) {
    final missingIds = [
      for (final plan in activePlans)
        if (!_metadataByPlanId.containsKey(plan.id) &&
            !_metadataInFlight.contains(plan.id))
          plan.id,
    ];

    if (missingIds.isEmpty || _loadQueued) {
      return;
    }

    _loadQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadQueued = false;
      await _loadMetadata(missingIds);
    });
  }

  Future<void> _loadMetadata(List<int> planIds) async {
    if (planIds.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _metadataInFlight.addAll(planIds);
    });

    try {
      _libraryExercises ??= await ref.read(allExercisesProvider.future);
      final exerciseMap = {
        for (final exercise in _libraryExercises!) exercise.id: exercise,
      };
      final results = await Future.wait(
        planIds.map(
          (planId) async => MapEntry(
            planId,
            await ref.read(planExerciseDetailsProvider(planId).future),
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        for (final result in results) {
          _metadataByPlanId[result.key] = _buildMetadata(
            result.value,
            exerciseMap,
          );
          _metadataInFlight.remove(result.key);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _metadataInFlight.removeAll(planIds);
      });
    }
  }

  _RoutineCardMetadata _buildMetadata(
    List<PlanExerciseDetail> details,
    Map<int, Exercise> exerciseMap,
  ) {
    final groups = <String>[];
    for (final detail in details) {
      final group =
          (exerciseMap[detail.exerciseId]?.mainMuscleGroup ?? '').trim();
      if (group.isEmpty || groups.contains(group)) {
        continue;
      }
      groups.add(group);
      if (groups.length == 3) {
        break;
      }
    }

    return _RoutineCardMetadata(
      exerciseCount: details.length,
      groups: groups,
    );
  }

  Future<void> _togglePlanActive(WorkoutPlan plan, bool isActive) async {
    try {
      await ref.read(workoutPlanProvider.notifier).setPlanActive(
            plan.id,
            isActive,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: KineticNoirPalette.error,
          content: Text('Unable to update routine: $error'),
        ),
      );
    }
  }

  Future<void> _openManageSheet() async {
    final action = await showModalBottomSheet<_ManageAction>(
      context: context,
      backgroundColor: KineticNoirPalette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const _ManageSheet(),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _ManageAction.dataBackups:
        widget.onOpenDataManagement();
        break;
    }
  }
}

enum _ManageAction {
  dataBackups,
}

class _RoutineCardMetadata {
  const _RoutineCardMetadata({
    required this.exerciseCount,
    required this.groups,
  });

  final int exerciseCount;
  final List<String> groups;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onOpenManage});

  final VoidCallback onOpenManage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FitLogWordmark(),
        const Spacer(),
        Tooltip(
          message: 'Manage',
          child: IconButton(
            key: const Key('routines-manage-button'),
            onPressed: onOpenManage,
            icon: const Icon(Icons.more_vert_rounded),
            color: KineticNoirPalette.primary,
          ),
        ),
      ],
    );
  }
}

class _ManageSheet extends StatelessWidget {
  const _ManageSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      KineticNoirPalette.outlineVariant.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Manage',
              style: KineticNoirTypography.headline(
                size: 26,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tools that support your training library.',
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('routines-data-management-action'),
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.pop(context, _ManageAction.dataBackups),
                child: Ink(
                  decoration: BoxDecoration(
                    color: KineticNoirPalette.surfaceLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: KineticNoirPalette.outlineVariant
                          .withValues(alpha: 0.18),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: KineticNoirPalette.primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.backup_rounded,
                          color: KineticNoirPalette.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data & Backups',
                              style: KineticNoirTypography.headline(
                                size: 20,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Export, share, or import Fit Log data.',
                              style: KineticNoirTypography.body(
                                size: 13,
                                weight: FontWeight.w600,
                                color: KineticNoirPalette.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: KineticNoirPalette.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
          const ToruMark(
            size: 46,
            variant: ToruMarkVariant.green,
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
