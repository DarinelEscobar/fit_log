import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoutinesScreen extends StatelessWidget {
  static const String routeName = 'routines';

  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: const _RoutineList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: abrir formulario para crear rutina
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear nueva rutina (pendiente)')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
    );
  }
}

/// — Placeholder — reemplázalo cuando conectes el datasource.
class _RoutineList extends StatelessWidget {
  const _RoutineList();

  @override
  Widget build(BuildContext context) {
    // Mock data por ahora
    final routines = ['Push/Pull/Legs', 'Torso-Pierna', 'Full‑Body'];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: routines.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) => ListTile(
        title: Text(routines[i]),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/'),      // Navega a Window 2 de ejemplo
      ),
    );
  }
}
