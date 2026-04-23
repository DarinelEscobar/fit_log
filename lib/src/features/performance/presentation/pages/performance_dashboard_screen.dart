import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../theme/toru_brand.dart';
import '../../../routines/domain/entities/workout_plan.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';
import '../models/performance_models.dart';
import '../providers/performance_providers.dart';

class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen> {
  PerformancePeriod _selectedPeriod = PerformancePeriod.fourWeeks;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(workoutPlanProvider);

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          color: KineticNoirPalette.primary,
          onPressed: () {},
        ),
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: KineticNoirPalette.surfaceBright,
              child: Icon(
                Icons.person_rounded,
                color: KineticNoirPalette.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
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
          final activePlans = plans.where((plan) => plan.isActive).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (activePlans.isEmpty) {
            return const _PerformanceEmptyState();
          }

          final activePlanIds = [
            for (final WorkoutPlan plan in activePlans) plan.id,
          ];
          final request = PerformanceDashboardRequest(
            period: _selectedPeriod,
            activePlanIds: activePlanIds,
          );
          final summaryAsync = ref.watch(performanceDashboardProvider(request));

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
                            'Based on exercises in current active routines',
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
                        child: _PerformanceHero(summary: summary),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.only(top: 18),
                      sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: _MetricGrid(summary: summary),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: _TrendSection(summary: summary),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: _MuscleFocusSection(summary: summary),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                      sliver: SliverToBoxAdapter(
                        child: _RecentPrsSection(summary: summary),
                      ),
                    ),
                  ] else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverToBoxAdapter(
                        child: _PerformanceNoLogsState(period: summary.period),
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
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
                          size: 52,
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
                      'kg',
                      style: KineticNoirTypography.body(
                        size: 16,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: KineticNoirPalette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${summary.consistencyPercent}% day coverage • ${summary.totalReps} reps',
                  style: KineticNoirTypography.body(
                    size: 11,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary});

  final PerformanceDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _MetricCard(
          label: 'TOTAL REPS',
          value: '${summary.totalReps}',
          detail: 'Completed across active routines',
        ),
        _MetricCard(
          label: 'DAY COVERAGE',
          value: '${summary.consistencyPercent}%',
          detail: 'Training days / calendar days',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: KineticNoirTypography.body(
              size: 10,
              weight: FontWeight.w800,
              color: KineticNoirPalette.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: KineticNoirTypography.headline(
              size: 28,
              weight: FontWeight.w700,
              color: KineticNoirPalette.onSurface,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: KineticNoirTypography.body(
              size: 11,
              weight: FontWeight.w600,
              color: KineticNoirPalette.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.summary});

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
            children: [
              Text(
                'Volume Trend',
                style: KineticNoirTypography.headline(
                  size: 19,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz_rounded,
                color:
                    KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: _VolumeTrendChart(points: summary.trend),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: KineticNoirPalette.primary, text: 'Volume'),
              SizedBox(width: 16),
              _Legend(color: KineticNoirPalette.primaryDim, text: 'Peak 1RM'),
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
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
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
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Focus',
            style: KineticNoirTypography.headline(
              size: 19,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (summary.muscleFocus.isEmpty)
            Text(
              'No focus data yet.',
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
            Text(
              item.label.toUpperCase(),
              style: KineticNoirTypography.body(
                size: 12,
                weight: FontWeight.w800,
                color: KineticNoirPalette.onSurface,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${item.percent}%',
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
  const _RecentPrsSection({required this.summary});

  final PerformanceDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent PRs',
              style: KineticNoirTypography.headline(
                size: 19,
                weight: FontWeight.w700,
              ),
            ),
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
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceLow,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Text(
              'No performance peaks yet.',
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
                _PrCard(card: card),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class _PrCard extends StatelessWidget {
  const _PrCard({required this.card});

  final PerformancePrCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  const _VolumeTrendChart({required this.points});

  final List<PerformanceTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: KineticNoirPalette.onSurfaceVariant),
        ),
      );
    }

    final spots = [
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].volumeKg),
    ];
    final maxVolume = points.fold<double>(
      0,
      (peak, point) => point.volumeKg > peak ? point.volumeKg : peak,
    );
    final maxOneRm = points.fold<double>(
      0,
      (peak, point) => point.topSetKg > peak ? point.topSetKg : peak,
    );
    final scale = maxOneRm > 0 ? maxVolume / maxOneRm : 1.0;
    final peakSpots = [
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].topSetKg * scale),
    ];
    final maxY = (maxVolume <= 0 ? 1.0 : maxVolume * 1.15).toDouble();
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
              reservedSize: 36,
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
          LineChartBarData(
            spots: peakSpots,
            isCurved: true,
            barWidth: 2.5,
            color: KineticNoirPalette.primaryDim,
            dashArray: const [6, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (items) => [
              for (final item in items)
                LineTooltipItem(
                  item.barIndex == 0
                      ? '${_formatCompactKg(points[item.spotIndex].volumeKg)} kg·reps'
                      : '${_formatCompactKg(points[item.spotIndex].topSetKg)} kg',
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
