class WarmUpStep {
  const WarmUpStep({
    this.id = 0,
    required this.name,
    this.notes = '',
    this.sets = 1,
    this.workSeconds = 30,
    this.restSeconds = 0,
    this.perSide = false,
  });

  final int id;
  final String name;
  final String notes;
  final int sets;
  final int workSeconds;
  final int restSeconds;
  final bool perSide;

  WarmUpStep copyWith({
    int? id,
    String? name,
    String? notes,
    int? sets,
    int? workSeconds,
    int? restSeconds,
    bool? perSide,
  }) =>
      WarmUpStep(
        id: id ?? this.id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
        sets: sets ?? this.sets,
        workSeconds: workSeconds ?? this.workSeconds,
        restSeconds: restSeconds ?? this.restSeconds,
        perSide: perSide ?? this.perSide,
      );
}
