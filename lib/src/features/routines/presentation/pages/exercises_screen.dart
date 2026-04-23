import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/workout_plan.dart';
import '../models/edit_routine_result.dart';
import '../models/exercise_list_view_data.dart';
import '../providers/exercise_list_view_provider.dart';
import '../../../performance/presentation/pages/exercise_progress_detail_screen.dart';
import 'edit_routine_screen.dart';
import 'start_routine_screen.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({required this.plan, super.key});

  final WorkoutPlan plan;

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<String> _queryNotifier;
  late WorkoutPlan _currentPlan;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.plan;
    _queryNotifier = ValueNotifier('');
    _searchController = TextEditingController()
      ..addListener(() {
        _queryNotifier.value = _searchController.text.trim().toLowerCase();
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(exerciseListViewProvider(_currentPlan.id));

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: KineticNoirPalette.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FIT LOG',
          style: KineticNoirTypography.headline(
            size: 24,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            color: KineticNoirPalette.onSurfaceVariant,
            tooltip: 'Edit routine',
            onPressed: _openEditor,
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.more_vert_rounded,
            color: KineticNoirPalette.primary,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: asyncData.when(
        data: (data) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _ExerciseListHero(
                plan: _currentPlan,
                searchController: _searchController,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _queryNotifier,
                builder: (context, query, _) {
                  final filteredItems = _filterItems(data.items, query);
                  if (filteredItems.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _ExerciseEmptyState(),
                    );
                  }

                  return ListView.builder(
                    key: const Key('exercise-list-results'),
                    cacheExtent: 500,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == filteredItems.length - 1 ? 0 : 14,
                        ),
                        child: RepaintBoundary(
                          child: _ExerciseCard(
                            item: filteredItems[index],
                            onOpenProgress: () =>
                                _openProgress(filteredItems[index]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: KineticNoirPalette.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Unable to load exercises.\n$error',
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
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: kineticPrimaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: KineticNoirPalette.shadow.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton.icon(
              key: const Key('exercise-list-start-workout'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StartRoutineScreen(plan: _currentPlan),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: KineticNoirPalette.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'START WORKOUT',
                style: KineticNoirTypography.body(
                  size: 16,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ExerciseListItemView> _filterItems(
    List<ExerciseListItemView> items,
    String query,
  ) {
    if (query.isEmpty) {
      return items;
    }

    return items.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.mainMuscleGroup.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<void> _openEditor() async {
    final result = await Navigator.push<EditRoutineResult>(
      context,
      MaterialPageRoute(
        builder: (_) => EditRoutineScreen(plan: _currentPlan),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _currentPlan = result.plan;
    });
  }

  Future<void> _openProgress(ExerciseListItemView item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseProgressDetailScreen(exercise: item),
      ),
    );
  }
}

class _ExerciseListHero extends StatelessWidget {
  const _ExerciseListHero({
    required this.plan,
    required this.searchController,
  });

  final WorkoutPlan plan;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT ROUTINE',
          style: KineticNoirTypography.body(
            size: 10,
            weight: FontWeight.w800,
            color: KineticNoirPalette.primary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          plan.name,
          key: const Key('exercise-list-title'),
          style: KineticNoirTypography.headline(
            size: 38,
            weight: FontWeight.w700,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          plan.frequency.toUpperCase(),
          style: KineticNoirTypography.body(
            size: 11,
            weight: FontWeight.w800,
            color: KineticNoirPalette.onSurfaceVariant,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Review your programmed exercises and launch the session when you are ready.',
          style: KineticNoirTypography.body(
            size: 15,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: searchController,
          style: KineticNoirTypography.body(
            size: 15,
            weight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Search exercises...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: searchController.clear,
                );
              },
            ),
            filled: true,
            fillColor: KineticNoirPalette.surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.item,
    required this.onOpenProgress,
  });

  final ExerciseListItemView item;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: item.mainMuscleGroup.isNotEmpty
                ? KineticNoirPalette.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (item.category.isNotEmpty)
                      _TagChip(
                        label: item.category,
                        backgroundColor:
                            KineticNoirPalette.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                        foregroundColor: KineticNoirPalette.onSurface,
                      ),
                    if (item.mainMuscleGroup.isNotEmpty)
                      _TagChip(
                        label: item.mainMuscleGroup,
                        backgroundColor:
                            KineticNoirPalette.primary.withValues(alpha: 0.12),
                        foregroundColor: KineticNoirPalette.primary,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.drag_indicator_rounded,
                color:
                    KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.name,
            style: KineticNoirTypography.headline(
              size: 28,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetricSummary(label: 'SETS', value: '${item.sets}'),
              _MetricSummary(label: 'REPS', value: '${item.reps}'),
              _MetricSummary(label: 'REST', value: '${item.restSeconds}s'),
              if (item.weight > 0)
                _MetricSummary(label: 'LOAD', value: '${item.weight}'),
            ],
          ),
          if (item.description.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              item.description,
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key('exercise-progress-${item.exerciseId}'),
              onPressed: onOpenProgress,
              style: TextButton.styleFrom(
                foregroundColor: KineticNoirPalette.primary,
                backgroundColor:
                    KineticNoirPalette.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.trending_up_rounded, size: 18),
              label: Text(
                'PROGRESS',
                style: KineticNoirTypography.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSummary extends StatelessWidget {
  const _MetricSummary({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          const SizedBox(height: 4),
          Text(
            value,
            style: KineticNoirTypography.headline(
              size: 18,
              weight: FontWeight.w700,
              color: KineticNoirPalette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: KineticNoirTypography.body(
          size: 9,
          weight: FontWeight.w800,
          color: foregroundColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ExerciseEmptyState extends StatelessWidget {
  const _ExerciseEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: KineticNoirPalette.surfaceLow,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 34,
              color: KineticNoirPalette.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No exercises match the filter',
              style: KineticNoirTypography.headline(
                size: 24,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clear the search field to inspect the full routine setup.',
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
      ),
    );
  }
}
