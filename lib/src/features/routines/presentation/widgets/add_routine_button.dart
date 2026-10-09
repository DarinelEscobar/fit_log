import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/usecases/create_workout_plan_usecase.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import 'routine_metadata_dialog.dart';

class AddRoutineButton extends ConsumerStatefulWidget {
  const AddRoutineButton({super.key});

  @override
  ConsumerState<AddRoutineButton> createState() => _AddRoutineButtonState();
}

class _AddRoutineButtonState extends ConsumerState<AddRoutineButton> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: const Key('add-routine-button'),
      tooltip: 'Create routine',
      backgroundColor: KineticNoirPalette.primary,
      foregroundColor: KineticNoirPalette.onPrimary,
      shape: const CircleBorder(),
      onPressed: _isCreating ? null : _handleCreate,
      child: _isCreating
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: KineticNoirPalette.onPrimary,
              ),
            )
          : const Icon(Icons.add_rounded, size: 28),
    );
  }

  Future<void> _handleCreate() async {
    final metadata = await showDialog<RoutineMetadataInput>(
      context: context,
      builder: (_) => const RoutineMetadataDialog(),
    );

    if (metadata == null || !mounted) {
      return;
    }

    setState(() => _isCreating = true);
    try {
      final repo = ref.read(workoutPlanRepositoryProvider);
      final usecase = CreateWorkoutPlanUseCase(repo);
      await usecase(metadata.name, metadata.frequency);
      await ref.read(workoutPlanProvider.notifier).refresh(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: KineticNoirPalette.error,
          content: Text('Unable to create routine: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
