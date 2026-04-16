<<<<<<< SEARCH
  @override
  Widget build(BuildContext context) {
    final asyncExercises = ref.watch(planExerciseDetailsProvider(widget.planId));
    final asyncPlans = ref.watch(workoutPlanProvider);
=======
  @override
  Widget build(BuildContext context) {
    final asyncExercises = ref.watch(exercisesForPlanProvider(widget.planId));
    final asyncPlans = ref.watch(workoutPlanProvider);
    final asyncDets = ref.watch(planExerciseDetailsProvider(widget.planId));
>>>>>>> REPLACE
<<<<<<< SEARCH
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
=======
            Expanded(
              child: asyncExercises.when(
                data: (exercises) {
                  return asyncDets.when(
                    data: (dets) {
                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = query.isEmpty
                          ? dets
                          : dets
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
>>>>>>> REPLACE
<<<<<<< SEARCH
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
=======
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
               );
             },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (e, _) => Center(child: Text('Error: $e')),
           ),
         ),
>>>>>>> REPLACE
