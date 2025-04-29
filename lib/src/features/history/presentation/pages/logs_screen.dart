import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(workoutSessionsProvider);
    final logsAsync = ref.watch(workoutLogsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sesiones'),
              Tab(text: 'Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: Sessions ---
            sessionsAsync.when(
              data: (sessions) => ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  return ListTile(
                    leading: Text('${i + 1}'),
                    title: Text('${s.date.toLocal().toIso8601String().substring(0, 10)}'),
                    subtitle: Text('${s.durationMinutes} min • ${s.fatigueLevel}'),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
            // --- TAB 2: Logs ---
            logsAsync.when(
              data: (logs) => ListView.builder(
                itemCount: logs.length,
                itemBuilder: (_, i) {
                  final l = logs[i];
                  return ListTile(
                    leading: Text('${i + 1}'),
                    title: Text('Exercise ${l.exerciseId} - ${l.reps} reps'),
                    subtitle: Text('Weight: ${l.weight} kg • RIR: ${l.rir}'),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}
