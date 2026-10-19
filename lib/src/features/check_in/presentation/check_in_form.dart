import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routines/presentation/providers/exercises_provider.dart';
import '../data/check_in_repository.dart';

class CheckInForm extends ConsumerStatefulWidget {
  final String kind;
  final Map<String, String>? previous;
  final CheckInRepository repository;
  const CheckInForm(
      {super.key, required this.kind, required this.repository, this.previous});
  @override
  ConsumerState<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends ConsumerState<CheckInForm> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, String>{};
  late DateTime _measuredAt;
  DateTime? _bowel;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _values.addAll(widget.previous ?? {});
    _measuredAt =
        DateTime.tryParse(_values['measured_at'] ?? '') ?? DateTime.now();
    _bowel = DateTime.tryParse(_values['last_bowel_movement'] ?? '');
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String key, String label, {bool numeric = true}) {
    final controller = _controllers.putIfAbsent(
        key, () => TextEditingController(text: _values[key] ?? ''));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label, helperText: 'Opcional · vacío = sin dato'),
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: (text) {
          if (!numeric || text == null || text.trim().isEmpty) return null;
          final value = double.tryParse(text.trim().replaceAll(',', '.'));
          final max = CheckInRepository.numericLimits[key]!;
          if (value == null ||
              !value.isFinite ||
              value < 0 ||
              value > max ||
              ((key.endsWith('_cm') || key == 'weight_kg') && value == 0)) {
            return 'Introduce un número válido (máximo $max).';
          }
          return null;
        },
      ),
    );
  }

  Widget _choice(String key, String label, Map<String, String> choices) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: _values[key] ?? '',
          decoration: InputDecoration(labelText: label),
          items: choices.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (value) => setState(() => _values[key] = value ?? ''),
        ),
      );

  Future<DateTime?> _pick(DateTime value) async {
    final day = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2024),
        lastDate: DateTime.now());
    if (day == null || !mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(value));
    return time == null
        ? null
        : DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, String>{
        ..._values,
        'kind': widget.kind,
        'measured_at': _measuredAt.toIso8601String(),
        'last_bowel_movement': _bowel?.toIso8601String() ?? '',
        for (final entry in _controllers.entries)
          entry.key: CheckInRepository.numericLimits.containsKey(entry.key)
              ? entry.value.text.trim().replaceAll(',', '.')
              : entry.value.text.trim(),
      }..remove('record_id');
      if (widget.previous != null) {
        data['supersedes_id'] = widget.previous!['record_id']!;
      }
      await widget.repository.save(data);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const yesNo = {'': 'Sin confirmar', '1': 'Sí', '0': 'No'};
    final titles = {
      'morning': 'Peso y abdomen',
      'daily': 'Comida y actividad',
      'tolerance': 'Tolerancia por ejercicio'
    };
    final exerciseOptions = widget.kind == 'tolerance'
        ? ref.watch(allExercisesProvider).asData?.value
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(titles[widget.kind]!)),
      body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            TextButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(_measuredAt.toString().substring(0, 16)),
                onPressed: _saving
                    ? null
                    : () async {
                        final value = await _pick(_measuredAt);
                        if (value != null && mounted) {
                          setState(() => _measuredAt = value);
                        }
                      }),
            if (widget.kind == 'morning') ...[
              const Text(
                  'Peso: 5–7 mañanas/semana, al despertar, después de orinar y antes de comer/beber. No fuerces una evacuación.\nAbdomen: lunes, miércoles y sábado, dos lecturas en los mismos puntos, relajado y tras espirar normalmente.'),
              const SizedBox(height: 16),
              _field('weight_kg', 'Peso (kg)'),
              _field('abdomen_upper_cm', 'Arriba del ombligo (cm)'),
              _field(
                  'abdomen_upper_repeat_cm', 'Arriba · segunda lectura (cm)'),
              _field('abdomen_lower_cm', 'Debajo del ombligo (cm)'),
              _field(
                  'abdomen_lower_repeat_cm', 'Debajo · segunda lectura (cm)'),
              _choice('fasted', 'En ayunas de alimentos', yesNo),
              _field('water_ml', 'Agua antes de medir (ml; 0 = ninguna)'),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Última evacuación (opcional)'),
                  subtitle:
                      Text(_bowel?.toString().substring(0, 16) ?? 'Sin dato'),
                  trailing: _bowel == null
                      ? const Icon(Icons.event)
                      : IconButton(
                          onPressed: () => setState(() => _bowel = null),
                          icon: const Icon(Icons.clear)),
                  onTap: () async {
                    final value = await _pick(_bowel ?? _measuredAt);
                    if (value != null && mounted) {
                      setState(() => _bowel = value);
                    }
                  }),
            ],
            if (widget.kind == 'daily') ...[
              const Text(
                  'Cierra el día sin rellenar datos que no mediste. Usa siempre la misma fuente de pasos.'),
              const SizedBox(height: 16),
              _field('calories_kcal', 'Calorías registradas (kcal)'),
              _field('protein_g', 'Proteína (g)'),
              _choice('diary_complete', '¿Registraste toda la comida?', yesNo),
              _choice('portions_estimated', '¿Hay porciones estimadas?', yesNo),
              _field('steps', 'Pasos del día'),
              _field('step_source', 'Fuente de pasos (ej. Google Fit)',
                  numeric: false),
              _field('sleep_hours', 'Horas de sueño declaradas (opcional)'),
            ],
            if (widget.kind == 'tolerance') ...[
              const Text(
                  'Fecha = exposición de entrenamiento. El seguimiento de la mañana siguiente se registra por separado del dolor durante la sesión. Detén la variante si reproduce la punzada o sensación de inestabilidad.'),
              const SizedBox(height: 16),
              if (exerciseOptions != null)
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Elegir de My Exercises (opcional)'),
                  items: exerciseOptions
                      .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (id) {
                    final e = exerciseOptions.firstWhere((e) => e.id == id);
                    _values['exercise_id'] = '$id';
                    _controllers
                        .putIfAbsent(
                            'exercise_name', () => TextEditingController())
                        .text = e.name;
                    setState(() {});
                  },
                ),
              const SizedBox(height: 12),
              _field('exercise_name', 'Ejercicio y variante', numeric: false),
              _field('apparatus_setup', 'Máquina / asiento / ajustes',
                  numeric: false),
              _field('pain_during', 'Dolor/punzada durante (0–10)'),
              _field('pain_next_morning', 'Dolor a la mañana siguiente (0–10)'),
              _field('discomfort_next_morning',
                  'Sensación rara/suelto al día siguiente (0–10)'),
              _choice('stopped_for', '¿Qué terminó la serie?', {
                '': 'Sin dato',
                'muscular': 'Fatiga muscular',
                'pain': 'Dolor / punzada',
                'discomfort': 'Disconfort / inestabilidad',
                'other': 'Otro',
              }),
            ],
            const SizedBox(height: 12),
            _field('photo_reference',
                'Referencia a fotos guardadas aparte (opcional)',
                numeric: false),
            _field('notes', 'Notas / punto exacto de cinta / contexto',
                numeric: false),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving
                    ? 'Guardando…'
                    : widget.previous == null
                        ? 'Guardar registro'
                        : 'Guardar corrección')),
            if (widget.previous != null)
              const Text(
                  'La corrección conserva el registro original en el archivo exportable.'),
          ])),
    );
  }
}
