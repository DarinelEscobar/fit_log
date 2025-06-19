import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercises_provider.dart';

class SelectExerciseScreen extends ConsumerStatefulWidget {
  final Set<String> groups;
  const SelectExerciseScreen({required this.groups, super.key});

  @override
  ConsumerState<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends ConsumerState<SelectExerciseScreen> {
  late String _group;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _group = 'Todos';
  }

  @override
  Widget build(BuildContext context) {
    final asyncExercises = ref.watch(allExercisesProvider);
    final groupsList = ['Todos', ...widget.groups.toList()];
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir ejercicio')),
      body: asyncExercises.when(
        data: (ex) {
          final exercises = ex.where((e) => widget.groups.contains(e.mainMuscleGroup)).toList();
          final filtered = exercises.where((e) {
            final byGroup = _group == 'Todos' || e.mainMuscleGroup == _group;
            final byName = e.name.toLowerCase().contains(_query.toLowerCase());
            return byGroup && byName;
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (groupsList.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _group,
                    onChanged: (v) => setState(() => _group = v!),
                    items: groupsList
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final exercise = filtered[i];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (exercise.description.isNotEmpty)
                            Text(exercise.description, style: const TextStyle(fontSize: 12)),
                          Text('${exercise.category} • ${exercise.mainMuscleGroup}',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, exercise),
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
    );
  }
}
