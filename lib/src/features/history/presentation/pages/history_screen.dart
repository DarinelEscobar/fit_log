import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../theme/toru_brand.dart';
import '../models/history_models.dart';
import '../providers/history_overview_provider.dart';
import 'history_session_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryPeriod _selectedPeriod = HistoryPeriod.fourWeeks;
  int? _selectedPlanId;

  @override
  Widget build(BuildContext context) {
    final filter = HistoryFilter(
      period: _selectedPeriod,
      planId: _selectedPlanId,
    );
    final historyAsync = ref.watch(historyOverviewProvider(filter));

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          key: const Key('history-screen-title'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const ToruMark(
              size: 26,
              variant: ToruMarkVariant.white,
              opacity: 0.94,
            ),
            const SizedBox(width: 10),
            Text(
              'HISTORY',
              style: KineticNoirTypography.headline(
                size: 24,
                weight: FontWeight.w700,
                color: KineticNoirPalette.primary,
              ),
            ),
          ],
        ),
      ),
      body: historyAsync.when(
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(message: '$error'),
        data: (data) => SafeArea(
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
                      if (data.planOptions.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _PlanFilter(
                          options: data.planOptions,
                          selectedPlanId: _selectedPlanId,
                          onChanged: (planId) {
                            setState(() => _selectedPlanId = planId);
                          },
                        ),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        'SESSION REVIEW',
                        style: KineticNoirTypography.body(
                          size: 12,
                          weight: FontWeight.w800,
                          color: KineticNoirPalette.onSurfaceVariant,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rangeLabel(data.range),
                        style: KineticNoirTypography.body(
                          size: 13,
                          weight: FontWeight.w600,
                          color: KineticNoirPalette.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (data.hasSessions) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: _OverviewGrid(data: data),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 18),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final session = data.sessions[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == data.sessions.length - 1 ? 0 : 14,
                          ),
                          child: _HistorySessionCard(
                            session: session,
                            onTap: () => _openSessionDetail(session),
                          ),
                        );
                      },
                      childCount: data.sessions.length,
                    ),
                  ),
                ),
              ] else
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyState(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSessionDetail(HistorySessionSummary session) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HistorySessionDetailScreen(session: session),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final HistoryPeriod selected;
  final ValueChanged<HistoryPeriod> onChanged;

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
          for (final period in HistoryPeriod.values)
            Expanded(
              child: _FilterChipButton(
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

class _PlanFilter extends StatelessWidget {
  const _PlanFilter({
    required this.options,
    required this.selectedPlanId,
    required this.onChanged,
  });

  final List<HistoryPlanOption> options;
  final int? selectedPlanId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _PillButton(
            label: 'All',
            selected: selectedPlanId == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final option in options) ...[
            _PillButton(
              label: option.name,
              selected: selectedPlanId == option.planId,
              onTap: () => onChanged(option.planId),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
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

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: KineticNoirTypography.body(
        size: 12,
        weight: FontWeight.w800,
        color: selected
            ? KineticNoirPalette.primary
            : KineticNoirPalette.onSurfaceVariant,
      ),
      selectedColor: KineticNoirPalette.primary.withValues(alpha: 0.12),
      backgroundColor: KineticNoirPalette.surfaceLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected
              ? KineticNoirPalette.primary.withValues(alpha: 0.28)
              : KineticNoirPalette.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.data});

  final HistoryOverviewData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _StatCard(
          label: 'WORKOUTS',
          value: '${data.sessions.length}',
          detail: '${data.trainingDays} training days',
        ),
        _StatCard(
          label: 'VOLUME',
          value: _formatCompactKg(data.totalVolumeKg),
          detail: 'kg across reviewed sets',
        ),
        _StatCard(
          label: 'SETS',
          value: '${data.totalSets}',
          detail: 'completed work sets',
        ),
        _StatCard(
          label: 'AVG TIME',
          value: data.averageDurationMinutes <= 0
              ? '--'
              : '${data.averageDurationMinutes}',
          detail: 'minutes per session',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const Spacer(),
          Text(
            value,
            style: KineticNoirTypography.headline(
              size: 30,
              weight: FontWeight.w700,
              color: KineticNoirPalette.primary,
            ),
          ),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KineticNoirTypography.body(
              size: 11,
              weight: FontWeight.w700,
              color: KineticNoirPalette.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({
    required this.session,
    required this.onTap,
  });

  final HistorySessionSummary session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('history-session-${session.planId}-${_keyDate(session.date)}'),
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
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
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEE, MMM d').format(session.date),
                      style: KineticNoirTypography.body(
                        size: 11,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.primary,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.planName,
                style: KineticNoirTypography.headline(
                  size: 25,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(label: '${session.totalSets} sets'),
                  _MetaPill(
                      label: '${_formatCompactKg(session.totalVolumeKg)} kg'),
                  if (session.durationMinutes > 0)
                    _MetaPill(label: '${session.durationMinutes} min'),
                  if (session.energy.isNotEmpty)
                    _MetaPill(label: 'Energy ${session.energy}/10'),
                  if (session.mood.isNotEmpty)
                    _MetaPill(label: 'Mood ${session.mood}/5'),
                ],
              ),
              if (session.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  session.notes.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KineticNoirTypography.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceBright.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: KineticNoirTypography.body(
          size: 10,
          weight: FontWeight.w800,
          color: KineticNoirPalette.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 36,
            color: KineticNoirPalette.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'No sessions in this window',
            style: KineticNoirTypography.headline(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Finish a workout or choose a wider period to review previous training.',
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
          'Unable to load history.\n$message',
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

String _rangeLabel(HistoryDateRange range) {
  final formatter = DateFormat('MMM d, yyyy');
  return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
}

String _formatCompactKg(double value) {
  if (value >= 1000) {
    return (value / 1000).toStringAsFixed(1);
  }
  return value.toStringAsFixed(0);
}

String _keyDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
