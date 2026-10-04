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
                size: 22,
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PeriodSelector(
                          selected: _selectedPeriod,
                          onChanged: _onPeriodChanged,
                        ),
                        if (data.planOptions.isNotEmpty) ...[
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 6),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _rangeLabel(data.range),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KineticNoirTypography.body(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: KineticNoirPalette.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (_selectedPlanId != null ||
                                _selectedExerciseId != null) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  minimumSize: const Size(48, 32),
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
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
                if (data.hasSessions) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: KineticEntrance(
                        child: RepaintBoundary(
                          child: _OverviewSummaryBand(data: data),
                        ),
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 12),
                    sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                  if (isGrouped)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = data.groups[index];
                            final isExpanded =
                                _expandedGroupKeys.contains(group.key);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == data.groups.length - 1 ? 0 : 10,
                              ),
                              child: _HistoryGroupSection(
                                key: ValueKey(group.key),
                                group: group,
                                isExpanded: isExpanded,
                                onToggle: () => _toggleGroup(group.key),
                                onSelectSession: _openSessionDetail,
                              ),
                            );
                          },
                          childCount: data.groups.length,
                          findChildIndexCallback: (Key key) {
                            if (key is ValueKey<String>) {
                              final idx = data.groups
                                  .indexWhere((g) => g.key == key.value);
                              return idx == -1 ? null : idx;
                            }
                            return null;
                          },
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final session = data.sessions[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == data.sessions.length - 1 ? 0 : 10,
                              ),
                              child: _HistorySessionCard(
                                key: ValueKey(
                                  session.identity,
                                ),
                                session: session,
                                onTap: () => _openSessionDetail(session),
                              ),
                            );
                          },
                          childCount: data.sessions.length,
                          findChildIndexCallback: (Key key) {
                            if (key is ValueKey<String>) {
                              final idx = data.sessions
                                  .indexWhere((s) => s.identity == key.value);
                              return idx == -1 ? null : idx;
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                ] else
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
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
      padding: const EdgeInsets.all(3),
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
    return SizedBox(
      height: 38,
      child: ListView.separated(
        key: const Key('history-plan-filter-list'),
        scrollDirection: Axis.horizontal,
        cacheExtent: 300,
        itemCount: options.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PillButton(
              key: const Key('history-plan-filter-all'),
              label: 'All Routines',
              selected: selectedPlanId == null,
              onTap: () => onChanged(null),
            );
          }
          final option = options[index - 1];
          return _PillButton(
            key: Key('history-plan-filter-${option.planId}'),
            label: option.name,
            selected: selectedPlanId == option.planId,
            onTap: () => onChanged(option.planId),
          );
        },
      ),
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
    return SizedBox(
      height: 38,
      child: ListView.separated(
        key: const Key('history-exercise-filter-list'),
        scrollDirection: Axis.horizontal,
        cacheExtent: 300,
        itemCount: options.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PillButton(
              key: const Key('history-exercise-filter-all'),
              label: 'All Exercises',
              selected: selectedExerciseId == null,
              onTap: () => onChanged(null),
            );
          }
          final option = options[index - 1];
          return _PillButton(
            key: Key('history-exercise-filter-${option.exerciseId}'),
            label: option.name,
            selected: selectedExerciseId == option.exerciseId,
            onTap: () => onChanged(option.exerciseId),
          );
        },
      ),
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
          constraints: const BoxConstraints(minHeight: 34),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 7),
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
              letterSpacing: 1.2,
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
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelStyle: KineticNoirTypography.body(
        size: 11,
        weight: FontWeight.w700,
        color: selected
            ? KineticNoirPalette.primary
            : KineticNoirPalette.onSurfaceVariant,
      ),
      selectedColor: KineticNoirPalette.primary.withValues(alpha: 0.14),
      backgroundColor: KineticNoirPalette.surfaceLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected
              ? KineticNoirPalette.primary.withValues(alpha: 0.32)
              : KineticNoirPalette.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

class _OverviewSummaryBand extends StatelessWidget {
  const _OverviewSummaryBand({required this.data});

  final HistoryOverviewData data;

  @override
  Widget build(BuildContext context) {
    final isLargeText = MediaQuery.textScalerOf(context).scale(14) > 20;

    if (isLargeText) {
      return Container(
        decoration: BoxDecoration(
          color: KineticNoirPalette.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'WORKOUTS',
                    value: '${data.sessions.length}',
                    detail: '${data.trainingDays} training days',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'VOLUME',
                    value: '${_formatCompactKg(data.totalVolumeKg)} kg',
                    detail: 'total load moved',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'SETS',
                    value: '${data.totalSets}',
                    detail: 'completed sets',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'AVG TIME',
                    value: data.averageDurationMinutes <= 0
                        ? '--'
                        : '${data.averageDurationMinutes}m',
                    detail: 'per session',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.14),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'WORKOUTS',
              value: '${data.sessions.length}',
              detail: '${data.trainingDays} training days',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatColumn(
              label: 'VOLUME',
              value: _formatCompactKg(data.totalVolumeKg),
              detail: 'kg moved',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatColumn(
              label: 'SETS',
              value: '${data.totalSets}',
              detail: 'sets',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatColumn(
              label: 'AVG TIME',
              value: data.averageDurationMinutes <= 0
                  ? '--'
                  : '${data.averageDurationMinutes}m',
              detail: 'per session',
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.12),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: KineticNoirTypography.body(
            size: 9,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: KineticNoirTypography.headline(
            size: 17,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KineticNoirTypography.body(
            size: 10,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HistoryGroupSection extends StatelessWidget {
  const _HistoryGroupSection({
    super.key,
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
        borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(18),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: KineticNoirTypography.headline(
                              size: 15,
                              weight: FontWeight.w700,
                              color: KineticNoirPalette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            group.subtitle,
                            style: KineticNoirTypography.body(
                              size: 11,
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
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            KineticNoirPalette.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${group.sessionCount}',
                        style: KineticNoirTypography.body(
                          size: 10,
                          weight: FontWeight.w800,
                          color: KineticNoirPalette.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOutCubic,
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: KineticNoirPalette.onSurfaceVariant,
                        size: 20,
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
              color: KineticNoirPalette.outlineVariant.withValues(alpha: 0.10),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: [
                  for (int i = 0; i < group.sessions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _HistorySessionCard(
                      key: ValueKey(
                        group.sessions[i].identity,
                      ),
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
    super.key,
    required this.session,
    required this.onTap,
    this.isNested = false,
  });

  final HistorySessionSummary session;
  final VoidCallback onTap;
  final bool isNested;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isNested ? KineticNoirPalette.surface : KineticNoirPalette.surfaceLow;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key(
            'history-session-${session.planId}-${_keyDate(session.date)}${session.sessionId == null || session.sessionId!.startsWith('legacy:') ? '' : '-${session.sessionId}'}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: KineticNoirPalette.primary.withValues(alpha: 0.55),
                width: 3.0,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _sessionHeaderDateFormatter
                          .format(session.date)
                          .toUpperCase(),
                      style: KineticNoirTypography.body(
                        size: 10,
                        weight: FontWeight.w800,
                        color: KineticNoirPalette.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (session.durationMinutes > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '${session.durationMinutes} min',
                        style: KineticNoirTypography.body(
                          size: 11,
                          weight: FontWeight.w700,
                          color: KineticNoirPalette.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: KineticNoirPalette.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                session.planName,
                style: KineticNoirTypography.headline(
                  size: 17,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
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
                const SizedBox(height: 8),
                Text(
                  session.notes.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KineticNoirTypography.body(
                    size: 11,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                    height: 1.3,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          letterSpacing: 0.6,
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
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 32,
            color: KineticNoirPalette.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No sessions in this window',
            style: KineticNoirTypography.headline(size: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Finish a workout or choose a wider period to review previous training.',
            textAlign: TextAlign.center,
            style: KineticNoirTypography.body(
              size: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Unable to load history.\n$message',
          textAlign: TextAlign.center,
          style: KineticNoirTypography.body(
            size: 14,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

final DateFormat _rangeDateFormatter = DateFormat('MMM d, yyyy');
final DateFormat _keyDateFormatter = DateFormat('yyyy-MM-dd');
final DateFormat _sessionHeaderDateFormatter = DateFormat('EEE, MMM d');

String _rangeLabel(HistoryDateRange range) {
  return '${_rangeDateFormatter.format(range.start)} - ${_rangeDateFormatter.format(range.end)}';
}

String _formatCompactKg(double value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toStringAsFixed(0);
}

String _keyDate(DateTime date) => _keyDateFormatter.format(date);
