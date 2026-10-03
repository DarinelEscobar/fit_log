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
  int? _selectedExerciseId;

  final Set<String> _expandedGroupKeys = {};
  HistoryPeriod? _lastPeriod;
  bool _initializedGroups = false;

  void _onPeriodChanged(HistoryPeriod period) {
    if (period == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = period;
      _expandedGroupKeys.clear();
      _initializedGroups = false;
    });
  }

  void _toggleGroup(String groupKey) {
    setState(() {
      if (_expandedGroupKeys.contains(groupKey)) {
        _expandedGroupKeys.remove(groupKey);
      } else {
        _expandedGroupKeys.add(groupKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = HistoryFilter(
      period: _selectedPeriod,
      planId: _selectedPlanId,
      exerciseId: _selectedExerciseId,
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
        data: (data) {
          if (_lastPeriod != _selectedPeriod) {
            _lastPeriod = _selectedPeriod;
            _expandedGroupKeys.clear();
            if (data.groups.isNotEmpty) {
              _expandedGroupKeys.add(data.groups.first.key);
            }
            _initializedGroups = true;
          } else if (!_initializedGroups && data.groups.isNotEmpty) {
            _initializedGroups = true;
            _expandedGroupKeys.add(data.groups.first.key);
          }

          final isGrouped = _selectedPeriod != HistoryPeriod.oneWeek &&
              data.groups.isNotEmpty;

          return SafeArea(
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
                          onChanged: _onPeriodChanged,
                        ),
                        if (data.planOptions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _PlanFilter(
                            options: data.planOptions,
                            selectedPlanId: _selectedPlanId,
                            onChanged: (planId) {
                              setState(() {
                                _selectedPlanId = planId;
                                _expandedGroupKeys.clear();
                                _initializedGroups = false;
                              });
                            },
                          ),
                        ],
                        if (data.exerciseOptions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _ExerciseFilter(
                            options: data.exerciseOptions,
                            selectedExerciseId: _selectedExerciseId,
                            onChanged: (exerciseId) {
                              setState(() {
                                _selectedExerciseId = exerciseId;
                                _expandedGroupKeys.clear();
                                _initializedGroups = false;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              'SESSION REVIEW',
                              style: KineticNoirTypography.body(
                                size: 12,
                                weight: FontWeight.w800,
                                color: KineticNoirPalette.onSurfaceVariant,
                                letterSpacing: 2.2,
                              ),
                            ),
                            if (_selectedPlanId != null ||
                                _selectedExerciseId != null) ...[
                              const Spacer(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(48, 36),
                                  foregroundColor: KineticNoirPalette.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedPlanId = null;
                                    _selectedExerciseId = null;
                                    _expandedGroupKeys.clear();
                                    _initializedGroups = false;
                                  });
                                },
                                child: Text(
                                  'CLEAR FILTERS',
                                  style: KineticNoirTypography.body(
                                    size: 11,
                                    weight: FontWeight.w800,
                                    color: KineticNoirPalette.primary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
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
                      child: KineticEntrance(child: _OverviewGrid(data: data)),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 18),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                  if (isGrouped)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = data.groups[index];
                            final isExpanded =
                                _expandedGroupKeys.contains(group.key);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == data.groups.length - 1 ? 0 : 14,
                              ),
                              child: _HistoryGroupSection(
                                group: group,
                                isExpanded: isExpanded,
                                onToggle: () => _toggleGroup(group.key),
                                onSelectSession: _openSessionDetail,
                              ),
                            );
                          },
                          childCount: data.groups.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final session = data.sessions[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == data.sessions.length - 1 ? 0 : 14,
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
          );
        },
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
                key: Key('history-period-${period.name}'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROUTINE',
          style: KineticNoirTypography.body(
            size: 10,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: ListView(
            key: const Key('history-plan-filter-list'),
            scrollDirection: Axis.horizontal,
            children: [
              _PillButton(
                key: const Key('history-plan-filter-all'),
                label: 'All Routines',
                selected: selectedPlanId == null,
                onTap: () => onChanged(null),
              ),
              const SizedBox(width: 8),
              for (final option in options) ...[
                _PillButton(
                  key: Key('history-plan-filter-${option.planId}'),
                  label: option.name,
                  selected: selectedPlanId == option.planId,
                  onTap: () => onChanged(option.planId),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseFilter extends StatelessWidget {
  const _ExerciseFilter({
    required this.options,
    required this.selectedExerciseId,
    required this.onChanged,
  });

  final List<HistoryExerciseOption> options;
  final int? selectedExerciseId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXERCISE',
          style: KineticNoirTypography.body(
            size: 10,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: ListView(
            key: const Key('history-exercise-filter-list'),
            scrollDirection: Axis.horizontal,
            children: [
              _PillButton(
                key: const Key('history-exercise-filter-all'),
                label: 'All Exercises',
                selected: selectedExerciseId == null,
                onTap: () => onChanged(null),
              ),
              const SizedBox(width: 8),
              for (final option in options) ...[
                _PillButton(
                  key: Key('history-exercise-filter-${option.exerciseId}'),
                  label: option.name,
                  selected: selectedExerciseId == option.exerciseId,
                  onTap: () => onChanged(option.exerciseId),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
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
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
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
    return LayoutBuilder(builder: (context, constraints) {
      final columns = MediaQuery.textScalerOf(context).scale(14) > 21 ? 1 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
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
        ].map((child) => SizedBox(width: width, child: child)).toList(),
      );
    });
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
          const SizedBox(height: 8),
          Text(
            value,
            style: KineticNoirTypography.headline(
              size: 24,
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

class _HistoryGroupSection extends StatelessWidget {
  const _HistoryGroupSection({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelectSession,
  });

  final HistorySessionGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<HistorySessionSummary> onSelectSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('history-group-${group.key}'),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('history-group-toggle-${group.key}'),
              borderRadius: BorderRadius.circular(22),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: KineticNoirTypography.headline(
                              size: 17,
                              weight: FontWeight.w700,
                              color: KineticNoirPalette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.subtitle,
                            style: KineticNoirTypography.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: KineticNoirPalette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            KineticNoirPalette.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${group.sessionCount}',
                        style: KineticNoirTypography.body(
                          size: 11,
                          weight: FontWeight.w800,
                          color: KineticNoirPalette.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOutCubic,
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: KineticNoirPalette.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color:
                  KineticNoirPalette.outlineVariant.withValues(alpha: 0.10),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  for (int i = 0; i < group.sessions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _HistorySessionCard(
                      session: group.sessions[i],
                      onTap: () => onSelectSession(group.sessions[i]),
                      isNested: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({
    required this.session,
    required this.onTap,
    this.isNested = false,
  });

  final HistorySessionSummary session;
  final VoidCallback onTap;
  final bool isNested;

  @override
  Widget build(BuildContext context) {
    final bgColor = isNested
        ? KineticNoirPalette.surface
        : KineticNoirPalette.surfaceLow;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('history-session-${session.planId}-${_keyDate(session.date)}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                color: KineticNoirPalette.primary.withValues(alpha: 0.55),
                width: 3.5,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEE, MMM d').format(session.date).toUpperCase(),
                      style: KineticNoirTypography.body(
                        size: 11,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.primary,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  if (session.durationMinutes > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '${session.durationMinutes} min',
                        style: KineticNoirTypography.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: KineticNoirPalette.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: KineticNoirPalette.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                session.planName,
                style: KineticNoirTypography.headline(
                  size: 19,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(label: '${session.totalSets} sets'),
                  _MetaPill(
                    label: '${_formatCompactKg(session.totalVolumeKg)} kg',
                  ),
                  if (session.energy.isNotEmpty)
                    _MetaPill(label: '⚡ ${session.energy}/10'),
                  if (session.mood.isNotEmpty)
                    _MetaPill(label: '😊 ${session.mood}/5'),
                ],
              ),
              if (session.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  session.notes.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KineticNoirTypography.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                    height: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toStringAsFixed(0);
}

String _keyDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
