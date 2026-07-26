enum WarmUpSessionStatus { running, paused, completed }

enum WarmUpPhase { work, rest }

enum WarmUpSide { none, left, right }

class WarmUpSessionState {
  const WarmUpSessionState({
    required this.status,
    required this.stepIndex,
    required this.setNumber,
    required this.phase,
    required this.side,
    this.phaseEndsAt,
    this.pausedRemainingSeconds = 0,
    this.skippedStepIndexes = const <int>{},
  });

  factory WarmUpSessionState.start(DateTime now) => WarmUpSessionState(
        status: WarmUpSessionStatus.running,
        stepIndex: 0,
        setNumber: 1,
        phase: WarmUpPhase.work,
        side: WarmUpSide.none,
        phaseEndsAt: now,
      );

  final WarmUpSessionStatus status;
  final int stepIndex;
  final int setNumber;
  final WarmUpPhase phase;
  final WarmUpSide side;
  final DateTime? phaseEndsAt;
  final int pausedRemainingSeconds;
  final Set<int> skippedStepIndexes;

  WarmUpSessionState copyWith({
    WarmUpSessionStatus? status,
    int? stepIndex,
    int? setNumber,
    WarmUpPhase? phase,
    WarmUpSide? side,
    DateTime? phaseEndsAt,
    bool clearPhaseEndsAt = false,
    int? pausedRemainingSeconds,
    Set<int>? skippedStepIndexes,
  }) =>
      WarmUpSessionState(
        status: status ?? this.status,
        stepIndex: stepIndex ?? this.stepIndex,
        setNumber: setNumber ?? this.setNumber,
        phase: phase ?? this.phase,
        side: side ?? this.side,
        phaseEndsAt: clearPhaseEndsAt ? null : phaseEndsAt ?? this.phaseEndsAt,
        pausedRemainingSeconds:
            pausedRemainingSeconds ?? this.pausedRemainingSeconds,
        skippedStepIndexes: skippedStepIndexes ?? this.skippedStepIndexes,
      );

  Map<String, Object?> toJson() => {
        'status': status.name,
        'stepIndex': stepIndex,
        'setNumber': setNumber,
        'phase': phase.name,
        'side': side.name,
        'phaseEndsAt': phaseEndsAt?.toIso8601String(),
        'pausedRemainingSeconds': pausedRemainingSeconds,
        'skippedStepIndexes': skippedStepIndexes.toList(growable: false),
      };

  static WarmUpSessionState? fromJson(Map<String, Object?> json) {
    final status = WarmUpSessionStatus.values.where(
      (value) => value.name == json['status'],
    );
    if (status.isEmpty) return null;
    final phase = WarmUpPhase.values.firstWhere(
      (value) => value.name == json['phase'],
      orElse: () => WarmUpPhase.work,
    );
    final side = WarmUpSide.values.firstWhere(
      (value) => value.name == json['side'],
      orElse: () => WarmUpSide.none,
    );
    final skipped = json['skippedStepIndexes'];
    return WarmUpSessionState(
      status: status.first,
      stepIndex: _asInt(json['stepIndex']),
      setNumber: _asInt(json['setNumber'], fallback: 1),
      phase: phase,
      side: side,
      phaseEndsAt: DateTime.tryParse(json['phaseEndsAt']?.toString() ?? ''),
      pausedRemainingSeconds: _asInt(json['pausedRemainingSeconds']),
      skippedStepIndexes: {
        if (skipped is List)
          for (final value in skipped)
            if (_asInt(value) >= 0) _asInt(value),
      },
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
