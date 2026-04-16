import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_plan.dart';
import '../providers/exercises_provider.dart';
import '../providers/workout_plan_provider.dart';
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
    final asyncExercises =
        ref.watch(exercisesForPlanProvider(widget.planId));
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Editar rutina',
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
        ],
      ),
      body: asyncExercises.when(
        data: (exercises) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? exercises
              : exercises
                  .where((exercise) =>
                      exercise.name.toLowerCase().contains(query))
                  .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar ejercicio',
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      query.isEmpty
                          ? 'Aún no tienes ejercicios'
                          : 'No hay ejercicios para esa búsqueda',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final exercise = filtered[i];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF3A3A3A),
                              ),
                            ),
                            child: Icon(
                              Icons.sports_gymnastics,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: Text(exercise.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (exercise.description.isNotEmpty)
                                Text(
                                  exercise.description,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              Text(
                                '${exercise.category} • ${exercise.mainMuscleGroup}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar rutina'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StartRoutineScreen(planId: widget.planId),
          ),
        ),
      ),
    );
  }
}
