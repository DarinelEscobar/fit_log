import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../domain/entities/workout_plan.dart';
import '../providers/exercises_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../providers/workout_plan_provider.dart';
import 'edit_routine_screen.dart';
import 'start_routine_screen.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({required this.planId, super.key});

  final int planId;

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncExercises = ref.watch(exercisesForPlanProvider(widget.planId));
    final asyncDetails = ref.watch(planExerciseDetailsProvider(widget.planId));
    final asyncPlans = ref.watch(workoutPlanProvider);

    final currentPlan = asyncPlans.maybeWhen(
      data: (plans) => plans.cast<WorkoutPlan?>().firstWhere(
            (plan) => plan?.id == widget.planId,
            orElse: () => null,
          ),
      orElse: () => null,
    );

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
            onPressed: currentPlan == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditRoutineScreen(plan: currentPlan),
                      ),
                    );
                  },
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.more_vert_rounded,
            color: KineticNoirPalette.primary,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: asyncExercises.when(
        data: (exercises) => asyncDetails.when(
          data: (details) {
            final items = _buildItems(exercises, details);
            final query = _searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? items
                : items
                    .where(
                      (item) => item.name.toLowerCase().contains(query),
                    )
                    .toList();

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
                        currentPlan?.name ?? 'Routine',
                        key: const Key('exercise-list-title'),
                        style: KineticNoirTypography.headline(
                          size: 38,
                          weight: FontWeight.w700,
                          height: 0.95,
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
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: KineticNoirTypography.body(
                          size: 15,
                          weight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search exercises...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
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
                      const SizedBox(height: 20),
                      if (filtered.isEmpty)
                        const _ExerciseEmptyState()
                      else
                        for (final item in filtered) ...[
                          _ExerciseCard(item: item),
                          const SizedBox(height: 14),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
          loading: _buildLoading,
          error: _buildError,
        ),
        loading: _buildLoading,
        error: _buildError,
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
                  color: KineticNoirPalette.shadow.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: FilledButton.icon(
              key: const Key('exercise-list-start-workout'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StartRoutineScreen(planId: widget.planId),
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

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: KineticNoirPalette.primary),
    );
  }

  Widget _buildError(Object error, StackTrace _) {
    return Center(
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
    );
  }

  List<_ExerciseListItem> _buildItems(
    List<Exercise> exercises,
    List<PlanExerciseDetail> details,
  ) {
    final exerciseMap = {
      for (final exercise in exercises) exercise.id: exercise,
    };

    return details
        .map(
          (detail) => _ExerciseListItem(
            exerciseId: detail.exerciseId,
            name: detail.name,
            description: detail.description,
            category: exerciseMap[detail.exerciseId]?.category ?? '',
            mainMuscleGroup:
                exerciseMap[detail.exerciseId]?.mainMuscleGroup ?? '',
            sets: detail.sets,
            reps: detail.reps,
            restSeconds: detail.restSeconds,
            weight: detail.weight,
          ),
        )
        .toList();
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.item});

  final _ExerciseListItem item;

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
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w600,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
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
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: KineticNoirTypography.headline(
              size: 24,
              weight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ExerciseEmptyState extends StatelessWidget {
  const _ExerciseEmptyState();

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
            Icons.search_off_rounded,
            size: 34,
            color: KineticNoirPalette.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No exercises match this search',
            style: KineticNoirTypography.headline(
              size: 24,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clear the query or return to the routine editor to adjust the setup.',
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

class _ExerciseListItem {
  const _ExerciseListItem({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.category,
    required this.mainMuscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.weight,
  });

  final int exerciseId;
  final String name;
  final String description;
  final String category;
  final String mainMuscleGroup;
  final int sets;
  final int reps;
  final int restSeconds;
  final double weight;
}
