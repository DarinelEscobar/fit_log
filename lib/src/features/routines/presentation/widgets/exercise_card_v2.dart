import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/set_entry.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../routines/domain/entities/workout_log_entry.dart';
import '../widgets/badge_delta.dart';
import '../widgets/exercise_card_header.dart';
import '../widgets/mini_sparkline.dart';
import '../widgets/sets_table.dart';
import '../../../../utils/tonnage.dart';

class ExerciseCardV2 extends ConsumerStatefulWidget {
  final Exercise exercise;
  final List<SetEntry> planSets;
  final List<SetEntry> lastSets;
  final List<SetEntry> bestSets;
  final List<SetEntry> todaySets;
  const ExerciseCardV2({
    super.key,
    required this.exercise,
    required this.planSets,
    required this.lastSets,
    required this.bestSets,
    required this.todaySets,
  });

  @override
  ConsumerState<ExerciseCardV2> createState() => _ExerciseCardV2State();
}

class _ExerciseCardV2State extends ConsumerState<ExerciseCardV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool showBest = true, expanded = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final delta = deltaPercent(
      tonnage(widget.todaySets),
      tonnage(widget.lastSets),
    );

    final history = ref.watch(logsByExerciseProvider(widget.exercise.id));
    final sparkData = history.when(
      data: (logs) {
        final volumes = <double>[];
        final sorted = List<WorkoutLogEntry>.from(logs);
        sorted.sort((a, b) => a.date.compareTo(b.date));
        for (final l in sorted) {
          volumes.add(l.reps * l.weight);
        }
        if (volumes.length > 10) {
          volumes.removeRange(0, volumes.length - 10);
        }
        return volumes;
      },
      loading: () => <double>[],
      error: (_, __) => <double>[],
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ExerciseCardHeader(
              name: widget.exercise.name,
              showBest: showBest,
              onToggleBest: () => setState(() => showBest = !showBest),
              onExpand: () => setState(() => expanded = !expanded),
            ),
            if (expanded) ...[
              TabBar(
                controller: _tabs,
                tabs: [
                  const Tab(text: 'Plan'),
                  const Tab(text: 'Último'),
                  if (showBest) const Tab(text: 'Mejor'),
                  const Tab(text: 'Hoy'),
                ],
              ),
              const SizedBox(height: 2),
              BadgeDelta(delta),
              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    SetsTable(widget.planSets),
                    SetsTable(widget.lastSets),
                    if (showBest) SetsTable(widget.bestSets),
                    SetsTable(widget.todaySets, editable: true),
                  ],
                ),
              ),
              MiniSparkline(data: sparkData),
            ],
          ],
        ),
      ),
    );
  }
}
