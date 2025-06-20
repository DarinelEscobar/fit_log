import 'dart:async';
import 'mini_line_chart.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../../../utils/notification_service.dart';
import '../state/workout_log_state.dart';
import '../../domain/entities/workout_log_entry.dart';
import '../../domain/entities/plan_exercise_detail.dart';

part 'exercise_tile_body.dart';
part 'exercise_tile_helpers.dart';
part 'exercise_tile_ui_helpers.dart';

class ExerciseTile extends StatefulWidget {
  const ExerciseTile({
    super.key,
    required this.detail,
    required this.expanded,
    required this.onToggle,
    required this.logsMap,
    required this.highlightDone,
    required this.onChanged,
    required this.removeLog,
    required this.update,
    required this.planId,
    this.lastLogs,
    this.bestLogs,
    required this.showBest,
    this.onSwap,
  });

  final PlanExerciseDetail detail;
  final bool expanded;
  final VoidCallback onToggle;
  final Map<String, WorkoutLogEntry> logsMap;
  final bool highlightDone;
  final VoidCallback onChanged;
  final void Function(WorkoutLogEntry) removeLog;
  final void Function(WorkoutLogEntry) update;
  final int planId;
  final List<WorkoutLogEntry>? lastLogs;
  final List<WorkoutLogEntry>? bestLogs;
  final bool showBest;
  final VoidCallback? onSwap;

  @override
  ExerciseTileState createState() => ExerciseTileState();
}

class ExerciseTileState extends State<ExerciseTile>
    with AutomaticKeepAliveClientMixin, ExerciseTileHelpers, ExerciseTileUIHelpers {
  bool _showChart = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _logsLoaded = widget.lastLogs != null;
    _build(widget.detail.sets);
  }

  @override
  void didUpdateWidget(covariant ExerciseTile old) {
    super.didUpdateWidget(old);
    final setsChanged = old.detail.sets != widget.detail.sets;
    final lastArrived = !_logsLoaded && widget.lastLogs != null;
    if (setsChanged || lastArrived) _build(widget.detail.sets);

  @override
  void dispose() {
    for (final c in [..._repCtl, ..._kgCtl, ..._rirCtl]) {
      c.dispose();
    }
    _restTimer?.cancel();
    NotificationService.cancelRest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildExercise(context);
}
