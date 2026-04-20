import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../domain/usecases/create_workout_plan_usecase.dart';
import '../providers/workout_plan_provider.dart';
import '../providers/workout_plan_repository_provider.dart';
import 'routine_metadata_dialog.dart';

class AddRoutineButton extends ConsumerWidget {
  const AddRoutineButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: kineticPrimaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: KineticNoirPalette.shadow.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final metadata = await showDialog<RoutineMetadataInput>(
              context: context,
              builder: (_) => const RoutineMetadataDialog(),
            );

            if (metadata == null || !context.mounted) return;

            final repo = ref.read(workoutPlanRepositoryProvider);
            final usecase = CreateWorkoutPlanUseCase(repo);
            await usecase(metadata.name, metadata.frequency);
            ref.invalidate(workoutPlanProvider);
          },
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.add_rounded,
              size: 28,
              color: KineticNoirPalette.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
