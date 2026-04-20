import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/entities/exercise.dart';
import '../providers/exercises_provider.dart';

class SelectExerciseScreen extends ConsumerStatefulWidget {
  const SelectExerciseScreen({
    required this.groups,
    this.initialExercises,
    super.key,
  });

  final Set<String> groups;
  final List<Exercise>? initialExercises;

  @override
  ConsumerState<SelectExerciseScreen> createState() =>
      _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends ConsumerState<SelectExerciseScreen> {
  late final TextEditingController _searchController;
  late final ValueNotifier<String> _queryNotifier;
  late final ValueNotifier<String> _groupNotifier;
  late Future<List<Exercise>> _loadFuture;
  List<Exercise>? _cachedExercises;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _queryNotifier = ValueNotifier('');
    _groupNotifier = ValueNotifier('All');
    _cachedExercises = widget.initialExercises == null
        ? null
        : (List<Exercise>.from(widget.initialExercises!)
          ..sort((a, b) => a.name.compareTo(b.name)));
    _loadFuture = _cachedExercises != null
        ? Future.value(_cachedExercises)
        : ref.read(allExercisesProvider.future);
    _searchController.addListener(() {
      _queryNotifier.value = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    _groupNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsList = [
      'All',
      ...widget.groups.where((group) => group.trim().isNotEmpty),
    ];

    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: KineticNoirPalette.primary,
        ),
        title: Text(
          'EXERCISE LIBRARY',
          style: KineticNoirTypography.headline(
            size: 22,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: KineticNoirPalette.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load library.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: KineticNoirTypography.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
            );
          }

          _cachedExercises ??= List<Exercise>.from(snapshot.data ?? const [])
            ..sort((a, b) => a.name.compareTo(b.name));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: _SelectExerciseHeader(
                  searchController: _searchController,
                  groupsList: groupsList,
                  selectedGroupListenable: _groupNotifier,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _queryNotifier,
                  builder: (context, query, _) {
                    return ValueListenableBuilder<String>(
                      valueListenable: _groupNotifier,
                      builder: (context, group, __) {
                        final filtered = _filterExercises(
                          _cachedExercises!,
                          query: query,
                          group: group,
                        );

                        if (filtered.isEmpty) {
                          return const _SelectExerciseEmptyState();
                        }

                        return ListView.builder(
                          cacheExtent: 500,
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == filtered.length - 1 ? 0 : 12,
                              ),
                              child: RepaintBoundary(
                                child: _ExerciseLibraryCard(
                                  exercise: filtered[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Exercise> _filterExercises(
    List<Exercise> exercises, {
    required String query,
    required String group,
  }) {
    return exercises.where((exercise) {
      final matchesGroup = group == 'All' || exercise.mainMuscleGroup == group;
      final matchesQuery = exercise.name.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList(growable: false);
  }
}

class _SelectExerciseHeader extends StatelessWidget {
  const _SelectExerciseHeader({
    required this.searchController,
    required this.groupsList,
    required this.selectedGroupListenable,
  });

  final TextEditingController searchController;
  final List<String> groupsList;
  final ValueNotifier<String> selectedGroupListenable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select an existing exercise to add it to the routine.',
          style: KineticNoirTypography.body(
            size: 14,
            weight: FontWeight.w600,
            color: KineticNoirPalette.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search exercise...',
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
        if (groupsList.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ValueListenableBuilder<String>(
              valueListenable: selectedGroupListenable,
              builder: (context, selectedGroup, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupsList.length,
                  itemBuilder: (context, index) {
                    final group = groupsList[index];
                    final selected = selectedGroup == group;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == groupsList.length - 1 ? 0 : 8,
                      ),
                      child: ChoiceChip(
                        label: Text(group),
                        selected: selected,
                        onSelected: (_) =>
                            selectedGroupListenable.value = group,
                        labelStyle: KineticNoirTypography.body(
                          size: 12,
                          weight: FontWeight.w800,
                          color: selected
                              ? KineticNoirPalette.primary
                              : KineticNoirPalette.onSurfaceVariant,
                        ),
                        selectedColor:
                            KineticNoirPalette.primary.withValues(alpha: 0.12),
                        backgroundColor: KineticNoirPalette.surfaceLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ExerciseLibraryCard extends StatelessWidget {
  const _ExerciseLibraryCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pop(context, exercise),
        child: Ink(
          decoration: BoxDecoration(
            color: KineticNoirPalette.surfaceLow,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: KineticNoirTypography.headline(
                  size: 24,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (exercise.category.trim().isNotEmpty)
                    _LibraryChip(
                      label: exercise.category,
                      backgroundColor: KineticNoirPalette.outlineVariant
                          .withValues(alpha: 0.32),
                      foregroundColor: KineticNoirPalette.onSurface,
                    ),
                  if (exercise.mainMuscleGroup.trim().isNotEmpty)
                    _LibraryChip(
                      label: exercise.mainMuscleGroup,
                      backgroundColor:
                          KineticNoirPalette.primary.withValues(alpha: 0.12),
                      foregroundColor: KineticNoirPalette.primary,
                    ),
                ],
              ),
              if (exercise.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  exercise.description,
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
        ),
      ),
    );
  }
}

class _LibraryChip extends StatelessWidget {
  const _LibraryChip({
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
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SelectExerciseEmptyState extends StatelessWidget {
  const _SelectExerciseEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
              'No library exercises match',
              style: KineticNoirTypography.headline(
                size: 24,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust the search or create a new exercise from the routine editor.',
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
