import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_plan.dart';

import '../providers/workout_plan_provider.dart';
import '../providers/plan_exercise_details_provider.dart';
import 'edit_routine_screen.dart';
import 'start_routine_screen.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  final int planId;
  const ExercisesScreen({required this.planId, super.key});

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
    final asyncExercises = ref.watch(planExerciseDetailsProvider(widget.planId));
    final asyncPlans = ref.watch(workoutPlanProvider);

    final WorkoutPlan? currentPlan = asyncPlans.maybeWhen(
      data: (plans) {
        for (final plan in plans) {
          if (plan.id == widget.planId) return plan;
        }
        return null;
      },
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFCC97FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FIT LOG',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFFCC97FF),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFADAAAB)),
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFCC97FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT ROUTINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFFCC97FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentPlan?.name ?? 'Loading...',
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentPlan?.frequency ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFADAAAB),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131314),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: const TextStyle(color: Color(0xFFADAAAB)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFADAAAB)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFFADAAAB)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            Expanded(
              child: asyncExercises.when(
                data: (exercises) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = query.isEmpty
                      ? exercises
                      : exercises
                          .where((ex) => ex.name.toLowerCase().contains(query))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? 'Aún no tienes ejercicios'
                            : 'No hay ejercicios para esa búsqueda',
                        style: const TextStyle(color: Color(0xFFADAAAB)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      // Use alternating border colors based on index for the sleek card effect
                      final bool isHighlight = index % 2 != 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131314),
                          borderRadius: BorderRadius.circular(16),
                          border: isHighlight
                              ? const Border(
                                  left: BorderSide(
                                    color: Color.fromRGBO(204, 151, 255, 0.4),
                                    width: 4,
                                  ),
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF262627),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'STRENGTH',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFCC97FF).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'EXERCISE',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.5,
                                                color: Color(0xFFCC97FF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        exercise.name,
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.drag_indicator, color: Color(0xFFADAAAB)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SETS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: -0.5,
                                          color: Color(0xFFADAAAB),
                                        ),
                                      ),
                                      Text(
                                        '${exercise.sets}',
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'REPS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: -0.5,
                                          color: Color(0xFFADAAAB),
                                        ),
                                      ),
                                      Text(
                                        '${exercise.reps}',
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'REST',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: -0.5,
                                          color: Color(0xFFADAAAB),
                                        ),
                                      ),
                                      Text(
                                        '${exercise.restSeconds}s',
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (exercise.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                exercise.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFADAAAB),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFF0E0E0F),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StartRoutineScreen(planId: widget.planId),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCC97FF), Color(0xFF9C48EA)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(132, 44, 211, 0.25),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Color(0xFF47007C)),
                SizedBox(width: 12),
                Text(
                  'START WORKOUT',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF47007C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
