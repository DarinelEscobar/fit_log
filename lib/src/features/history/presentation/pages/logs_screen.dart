import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_providers.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(workoutSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de sesiones')),
      body: sessionsAsync.when(
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
    );
  }
}
