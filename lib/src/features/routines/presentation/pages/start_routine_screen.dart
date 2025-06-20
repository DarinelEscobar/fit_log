// lib/src/features/routines/presentation/pages/start_routine_screen.dart
//
// Neutral-toned, shadow-light redesign with fixed compile errors.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plan_exercise_details_provider.dart';
import '../state/workout_log_state.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/plan_exercise_detail.dart';
import '../../data/repositories/workout_plan_repository_impl.dart';
import '../../domain/usecases/save_workout_logs_usecase.dart';
import '../../domain/usecases/save_workout_session_usecase.dart';
import '../widgets/exercise_tile.dart';
import '../widgets/progress_header.dart';
import '../widgets/scale_dropdown.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../providers/exercises_provider.dart';
import 'select_exercise_screen.dart';

part 'start_routine_helpers.dart';
part 'start_routine_dialogs.dart';
part 'start_routine_actions.dart';
part 'start_routine_body.dart';

class StartRoutineScreen extends ConsumerStatefulWidget {
  final int planId;
  const StartRoutineScreen({required this.planId, super.key});

  @override
  ConsumerState<StartRoutineScreen> createState() => _StartRoutineScreenState();
}

class _StartRoutineScreenState extends ConsumerState<StartRoutineScreen>
    with StartRoutineDialogs, StartRoutineActions {
  late final Timer _ticker;
  final Map<int, GlobalKey<ExerciseTileState>> _keys = {};
  int? _expandedExerciseId;
  List<PlanExerciseDetail>? _sessionDetails;
  Map<int, Exercise>? _exerciseMap;

  String _fatigue = '5';
  String _mood = '3';
  final TextEditingController _notesCtl = TextEditingController();
  bool _showBest = true;

  static const List<String> _scale10 = [
    '1','2','3','4','5','6','7','8','9','10'
  ];
  static const List<String> _scale5 = ['1','2','3','4','5'];
  static const int _defaultSets = 3;

  @override
  void initState() {
    super.initState();
    ref.read(workoutLogProvider.notifier).startSession();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildBody(context);

}
