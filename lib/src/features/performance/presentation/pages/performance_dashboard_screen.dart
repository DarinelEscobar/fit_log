import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../theme/toru_brand.dart';
import '../../../routines/domain/entities/exercise.dart';
import '../../../routines/domain/entities/workout_plan.dart';
import '../../../routines/presentation/models/exercise_list_view_data.dart';
import '../../../routines/presentation/providers/exercises_provider.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../models/performance_models.dart';
import '../providers/performance_providers.dart';
import 'exercise_progress_detail_screen.dart';

class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen> {
  PerformancePeriod _selectedPeriod = PerformancePeriod.fourWeeks;
  late final TextEditingController _exerciseSearchController;
  late final ValueNotifier<String> _exerciseQueryNotifier;

  List<WorkoutPlan>? _lastPlans;
  List<WorkoutPlan> _cachedActivePlans = const [];
  List<int> _cachedActivePlanIds = const [];

  List<Exercise>? _lastExercises;
  Map<int, Exercise> _cachedExerciseMap = const {};

  @override
  void initState() {
    super.initState();
    _exerciseQueryNotifier = ValueNotifier('');
    _exerciseSearchController = TextEditingController()
      ..addListener(() {
        _exerciseQueryNotifier.value =
            _exerciseSearchController.text.trim().toLowerCase();
      });
  }

  @override
  void dispose() {
    _exerciseSearchController.dispose();
    _exerciseQueryNotifier.dispose();
    super.dispose();
  }

  void _updateActivePlans(List<WorkoutPlan> plans) {
    if (identical(_lastPlans, plans)) return;
    _lastPlans = plans;
    _cachedActivePlans = plans.where((plan) => plan.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _cachedActivePlanIds = [
      for (final WorkoutPlan plan in _cachedActivePlans) plan.id,
    ];
  }

  Map<int, Exercise> _resolveExerciseMap(List<Exercise>? exercises) {
    if (exercises == null) return const {};
    if (identical(_lastExercises, exercises)) return _cachedExerciseMap;
    _lastExercises = exercises;
    _cachedExerciseMap = {
      for (final exercise in exercises) exercise.id: exercise,
    };
    return _cachedExerciseMap;
  }

  void _openExerciseProgress(
    BuildContext context,
    PerformanceExerciseItem item,
    Map<int, Exercise> exerciseMap,
  ) {
    final exerciseEntity = exerciseMap[item.exerciseId];
    final itemView = ExerciseListItemView(
      exerciseId: item.exerciseId,
      name: item.name,
      description: exerciseEntity?.description ?? item.description,
      category: item.category,
      mainMuscleGroup: item.mainMuscleGroup,
      sets: item.targetSets > 0 ? item.targetSets : 3,
      reps: item.targetReps > 0 ? item.targetReps : item.bestReps,
      restSeconds: item.restSeconds > 0 ? item.restSeconds : 90,
      weight: item.bestWeightKg,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseProgressDetailScreen(exercise: itemView),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(workoutPlanProvider);
    final allExercisesAsync = ref.watch(allExercisesProvider);

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          key: const Key('performance-dashboard-title'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const ToruMark(
              size: 26,
              variant: ToruMarkVariant.white,
              opacity: 0.94,
            ),
            const SizedBox(width: 10),
            Text(
              'PERFORMANCE',
              style: KineticNoirTypography.headline(
                size: 24,
                weight: FontWeight.w700,
                color: KineticNoirPalette.primary,
              ),
            ),
          ],
        ),
      ),
      body: plansAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KineticNoirPalette.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Unable to load performance data.\n$error',
              textAlign: TextAlign.center,
              style: KineticNoirTypography.body(
                size: 15,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ),
        data: (plans) {
          _updateActivePlans(plans);
          final activePlans = _cachedActivePlans;
          if (activePlans.isEmpty) {
            return const _PerformanceEmptyState();
          }

          final activePlanIds = _cachedActivePlanIds;
          final request = PerformanceDashboardRequest(
            period: _selectedPeriod,
            activePlanIds: activePlanIds,
          );
          final summaryAsync = ref.watch(performanceDashboardProvider(request));

          final exerciseMap = _resolveExerciseMap(allExercisesAsync.valueOrNull);

          return summaryAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: KineticNoirPalette.primary,
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Unable to load dashboard.\n$error',
                  textAlign: TextAlign.center,
                  style: KineticNoirTypography.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            data: (summary) => SafeArea(
              bottom: false,
              child: CustomScrollView(
                cacheExtent: 800,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PeriodSelector(
                            selected: _selectedPeriod,
                            onChanged: (period) {
                              if (period == _selectedPeriod) {
                                return;
                              }
                              setState(() => _selectedPeriod = period);
                            },
                          ),
                          const SizedBox(height: 18),
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
                              const SizedBox(width: 10),
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
                          const SizedBox(height: 8),
                          Text(
                            'Analytics for exercises across active routines',
                            style: KineticNoirTypography.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: KineticNoirPalette.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (summary.hasData) ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: KineticEntrance(
                          child: _PerformanceHero(summary: summary),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: _TrendSection(
                            summary: summary,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: _MuscleFocusSection(summary: summary),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: _RecentPrsSection(
                          summary: summary,
                          onOpenExercise: (exerciseId) {
                            final item = summary.activeExercises.firstWhere(
                              (e) => e.exerciseId == exerciseId,
                              orElse: () {
                                final ex = exerciseMap[exerciseId];
                                return PerformanceExerciseItem(
                                  exerciseId: exerciseId,
                                  name: ex?.name ?? 'Exercise $exerciseId',
                                  category: ex?.category ?? 'Compound',
                                  mainMuscleGroup:
                                      ex?.mainMuscleGroup ?? 'Full Body',
                                  totalVolumeKg: 0,
                                  sessionCount: 0,
                                  lastTrainedDate: null,
                                  bestWeightKg: 0,
                                  bestReps: 0,
                                  estimatedOneRmKg: 0,
                                );
                              },
                            );
                            _openExerciseProgress(context, item, exerciseMap);
                          },
                        ),
                      ),
                    ),
                  ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                      sliver: SliverToBoxAdapter(
                        child: _ExerciseExplorerSection(
                          activeExercises: summary.activeExercises,
                          searchController: _exerciseSearchController,
                          queryNotifier: _exerciseQueryNotifier,
                          onSelectExercise: (item) {
                            _openExerciseProgress(context, item, exerciseMap);
                          },
                        ),
                      ),
                    ),
                  ] else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _PerformanceNoLogsState(period: summary.period),
                            if (summary.activeExercises.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _ExerciseExplorerSection(
                                activeExercises: summary.activeExercises,
                                searchController: _exerciseSearchController,
                                queryNotifier: _exerciseQueryNotifier,
                                onSelectExercise: (item) {
                                  _openExerciseProgress(
                                    context,
                                    item,
                                    exerciseMap,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final PerformancePeriod selected;
  final ValueChanged<PerformancePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final period in PerformancePeriod.values)
            Expanded(
              child: _PeriodChip(
                key: Key('performance-period-${period.name}'),
                label: period.label,
                selected: selected == period,
                onTap: () => onChanged(period),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: KineticMotion.duration(context, 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? KineticNoirPalette.surfaceBright
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: KineticNoirTypography.body(
              size: 11,
              weight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? KineticNoirPalette.primary
                  : KineticNoirPalette.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceHero extends StatelessWidget {
  const _PerformanceHero({required this.summary});

  final PerformanceDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(22),
        border: Border(
          left: BorderSide(
            color: KineticNoirPalette.primary.withValues(alpha: 0.45),
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -32,
            child: IgnorePointer(
              child: SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            KineticNoirPalette.primary.withValues(alpha: 0.08),
                        boxShadow: [
                          BoxShadow(
                            color: KineticNoirPalette.primary.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 48,
                          ),
                        ],
                      ),
                    ),
                    const ToruMark(
                      size: 92,
                      variant: ToruMarkVariant.white,
                      opacity: 0.16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _heroVolumeLabel(summary.period),
                style: KineticNoirTypography.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurfaceVariant,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatKg(summary.totalVolumeKg),
                        style: KineticNoirTypography.headline(
                          size: 40,
                          weight: FontWeight.w700,
                          color: KineticNoirPalette.primary,
                          height: 0.9,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'kg·reps',
                      style: KineticNoirTypography.body(
                        size: 15,
                        weight: FontWeight.w600,
                        color: KineticNoirPalette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${summary.trainingDays} training days • ${summary.period.label} window',
                style: KineticNoirTypography.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: KineticNoirPalette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${summary.consistencyPercent}% day coverage',
                      style: KineticNoirTypography.body(
                        size: 11,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: KineticNoirPalette.surfaceBright,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${summary.totalReps} total reps',
                      style: KineticNoirTypography.body(
                        size: 11,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({
    required this.summary,
  });

  final PerformanceDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Volume Trend',
                style: KineticNoirTypography.headline(
                  size: 19,
                  weight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KineticNoirPalette.surfaceBright,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${summary.period.label} WEEKLY LOAD',
                  style: KineticNoirTypography.body(
                    size: 9,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: _VolumeTrendChart(
              points: summary.trend,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(
                color: KineticNoirPalette.primary,
                text: 'Weekly Volume (kg·reps)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: KineticNoirTypography.body(
            size: 11,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MuscleFocusSection extends StatelessWidget {
  const _MuscleFocusSection({required this.summary});

  final PerformanceDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Muscle Focus',
                  style: KineticNoirTypography.headline(
                    size: 19,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${summary.period.label} DISTRIBUTION',
                style: KineticNoirTypography.body(
                  size: 10,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (summary.muscleFocus.isEmpty)
            Text(
              'No focus data recorded yet.',
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: [
                for (final item in summary.muscleFocus) ...[
                  _FocusBar(item: item),
                  const SizedBox(height: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _FocusBar extends StatelessWidget {
  const _FocusBar({required this.item});

  final PerformanceMuscleFocus item;

  @override
  Widget build(BuildContext context) {
    final percent = item.percent.clamp(0, 100).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.label.toUpperCase(),
                style: KineticNoirTypography.body(
                  size: 12,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.percent}% • ${_formatKg(item.volumeKg)} kg·reps',
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 10,
            backgroundColor: KineticNoirPalette.surfaceBright,
            valueColor: AlwaysStoppedAnimation<Color>(
              item.percent > 33
                  ? KineticNoirPalette.primary
                  : KineticNoirPalette.primaryDim,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentPrsSection extends StatelessWidget {
  const _RecentPrsSection({
    required this.summary,
    required this.onOpenExercise,
  });

  final PerformanceDashboardSummary summary;
  final ValueChanged<int> onOpenExercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent PRs',
                style: KineticNoirTypography.headline(
                  size: 19,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${summary.period.label} • ACTIVE ONLY',
              style: KineticNoirTypography.body(
                size: 10,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (summary.recentPrs.isEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Text(
              'No performance peaks recorded in this period yet.',
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
              ),
            ),
          )
        else
          Column(
            children: [
              for (final card in summary.recentPrs) ...[
                _PrCard(
                  card: card,
                  onTap: card.exerciseId != null
                      ? () => onOpenExercise(card.exerciseId!)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class _PrCard extends StatelessWidget {
  const _PrCard({
    required this.card,
    this.onTap,
  });

  final PerformancePrCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KineticNoirPalette.surfaceLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('performance-pr-card-${card.exerciseId ?? card.label}'),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: KineticNoirPalette.surfaceBright,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  card.label == '1RM'
                      ? Icons.military_tech_rounded
                      : Icons.timeline_rounded,
                  color: KineticNoirPalette.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.exerciseName,
                      style: KineticNoirTypography.headline(
                        size: 17,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.detail,
                      style: KineticNoirTypography.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: KineticNoirPalette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d').format(card.date),
                      style: KineticNoirTypography.body(
                        size: 10,
                        weight: FontWeight.w700,
                        color: KineticNoirPalette.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: KineticNoirPalette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      card.label,
                      style: KineticNoirTypography.body(
                        size: 9,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatKg(card.valueKg),
                        style: KineticNoirTypography.headline(
                          size: 20,
                          weight: FontWeight.w700,
                          color: KineticNoirPalette.onSurface,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          card.label == 'VOL' ? 'kg·reps' : 'kg',
                          style: KineticNoirTypography.body(
                            size: 11,
                            weight: FontWeight.w700,
                            color: KineticNoirPalette.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.deltaLabel,
                    style: KineticNoirTypography.body(
                      size: 10,
                      weight: FontWeight.w800,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
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

class _ExerciseExplorerSection extends StatelessWidget {
  const _ExerciseExplorerSection({
    required this.activeExercises,
    required this.searchController,
    required this.queryNotifier,
    required this.onSelectExercise,
  });

  final List<PerformanceExerciseItem> activeExercises;
  final TextEditingController searchController;
  final ValueNotifier<String> queryNotifier;
  final ValueChanged<PerformanceExerciseItem> onSelectExercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Exercise Progress',
                style: KineticNoirTypography.headline(
                  size: 19,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KineticNoirPalette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${activeExercises.length} EXERCISES',
                style: KineticNoirTypography.body(
                  size: 9,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          style: KineticNoirTypography.body(
            size: 14,
            weight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Search active exercises...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: KineticNoirPalette.onSurfaceVariant,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: KineticNoirPalette.onSurfaceVariant,
                  tooltip: 'Clear search',
                  onPressed: searchController.clear,
                );
              },
            ),
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: KineticNoirPalette.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<String>(
          valueListenable: queryNotifier,
          builder: (context, query, _) {
            final filtered = activeExercises.where((item) {
              if (query.isEmpty) return true;
              return item.name.toLowerCase().contains(query) ||
                  item.mainMuscleGroup.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query);
            }).toList(growable: false);

            if (filtered.isEmpty) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: KineticNoirPalette.surfaceLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No exercises match your search.',
                  textAlign: TextAlign.center,
                  style: KineticNoirTypography.body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final item in filtered) ...[
                  _ExerciseProgressTile(
                    key: ValueKey(item.exerciseId),
                    item: item,
                    onTap: () => onSelectExercise(item),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ExerciseProgressTile extends StatelessWidget {
  const _ExerciseProgressTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final PerformanceExerciseItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('performance-exercise-card-${item.exerciseId}'),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: KineticNoirPalette.surfaceBright,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: KineticNoirPalette.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: KineticNoirTypography.headline(
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.category.isNotEmpty)
                            _MiniBadge(label: item.category),
                          if (item.mainMuscleGroup.isNotEmpty)
                            _MiniBadge(label: item.mainMuscleGroup),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.totalVolumeKg > 0
                            ? '${_formatKg(item.bestWeightKg)} kg top • ${item.sessionCount} sessions'
                            : 'No sessions in period',
                        style: KineticNoirTypography.body(
                          size: 11,
                          weight: FontWeight.w600,
                          color: KineticNoirPalette.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.estimatedOneRmKg > 0) ...[
                      Text(
                        '${_formatKg(item.estimatedOneRmKg)} kg',
                        style: KineticNoirTypography.headline(
                          size: 17,
                          weight: FontWeight.w700,
                          color: KineticNoirPalette.primary,
                        ),
                      ),
                      Text(
                        'EST. 1RM',
                        style: KineticNoirTypography.body(
                          size: 9,
                          weight: FontWeight.w800,
                          color: KineticNoirPalette.onSurfaceVariant,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: KineticNoirPalette.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceBright,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: KineticNoirTypography.body(
          size: 9,
          weight: FontWeight.w800,
          color: KineticNoirPalette.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PerformanceEmptyState extends StatelessWidget {
  const _PerformanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Container(
          decoration: BoxDecoration(
            color: KineticNoirPalette.surfaceLow,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ToruMark(
                size: 48,
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
              const SizedBox(height: 10),
              Text(
                'Performance analytics will appear once you activate routines and record sessions.',
                textAlign: TextAlign.center,
                style: KineticNoirTypography.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: KineticNoirPalette.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceNoLogsState extends StatelessWidget {
  const _PerformanceNoLogsState({required this.period});

  final PerformancePeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.query_stats_rounded,
            color: KineticNoirPalette.primary,
            size: 42,
          ),
          const SizedBox(height: 16),
          Text(
            'No logs found for this period',
            textAlign: TextAlign.center,
            style: KineticNoirTypography.headline(
              size: 22,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'The ${period.label} dashboard uses logged sets for exercises in your current active routines.',
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

class _VolumeTrendChart extends StatelessWidget {
  const _VolumeTrendChart({
    required this.points,
  });

  final List<PerformanceTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No data recorded for this window',
          style: KineticNoirTypography.body(
            size: 13,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
      );
    }

    final spots = [
      for (var index = 0; index < points.length; index++)
        FlSpot(
          index.toDouble(),
          points[index].volumeKg,
        ),
    ];

    final maxVal = spots.fold<double>(
      0,
      (peak, spot) => spot.y > peak ? spot.y : peak,
    );

    final maxY = (maxVal <= 0 ? 1.0 : maxVal * 1.15).toDouble();
    final maxX = points.length <= 1 ? 1.0 : (points.length - 1).toDouble();
    final interval =
        points.length <= 4 ? 1.0 : (points.length / 3).ceilToDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY / 3,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 3,
              reservedSize: 42,
              getTitlesWidget: (value, _) => Text(
                value <= 0 ? '' : _formatCompactKg(value),
                style: KineticNoirTypography.body(
                  size: 9,
                  weight: FontWeight.w700,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                if (points.length > 4 &&
                    index != 0 &&
                    index != points.length - 1 &&
                    index % interval != 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DateFormat('MM/dd').format(points[index].weekStart),
                  style: KineticNoirTypography.body(
                    size: 9,
                    weight: FontWeight.w700,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: KineticNoirPalette.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  KineticNoirPalette.primary.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (items) => [
              for (final item in items)
                LineTooltipItem(
                  '${DateFormat('MM/dd').format(points[item.spotIndex].weekStart)}\n${_formatCompactKg(points[item.spotIndex].volumeKg)} kg·reps',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatKg(double value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

String _formatCompactKg(double value) {
  return _formatKg(value);
}

String _heroVolumeLabel(PerformancePeriod period) {
  return switch (period) {
    PerformancePeriod.oneWeek => '7-Day Volume',
    PerformancePeriod.fourWeeks => '4-Week Volume',
    PerformancePeriod.twelveWeeks => '12-Week Volume',
    PerformancePeriod.yearToDate => 'YTD Volume',
  };
}
