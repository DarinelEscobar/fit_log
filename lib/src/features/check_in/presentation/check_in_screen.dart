import 'package:flutter/material.dart';

import '../../../utils/notification_service.dart';
import '../../app_data/presentation/pages/data_screen.dart';
import '../data/check_in_repository.dart';
import 'check_in_form.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _repository = CheckInRepository();
  List<Map<String, String>> _rows = [];
  String? _error;
  bool _loading = true;
  bool _reminderBusy = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _repository.readAll();
      final reminder = await NotificationService.readCheckInReminder();
      final superseded = rows.map((r) => r['supersedes_id']).toSet();
      rows.removeWhere((r) => superseded.contains(r['record_id']));
      rows.sort((a, b) => b['measured_at']!.compareTo(a['measured_at']!));
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        _error = null;
        _reminderEnabled = reminder?['enabled'] == true;
        _reminderTime = TimeOfDay(
            hour: reminder?['hour'] as int? ?? 8,
            minute: reminder?['minute'] as int? ?? 0);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(String kind, [Map<String, String>? row]) async {
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => CheckInForm(
                kind: kind, repository: _repository, previous: row)));
    if (saved == true) await _load();
  }

  Future<void> _remind(bool enabled) async {
    if (_reminderBusy) return;
    setState(() => _reminderBusy = true);
    try {
      final time = enabled
          ? await showTimePicker(context: context, initialTime: _reminderTime)
          : _reminderTime;
      if (time == null) return;
      await NotificationService.setCheckInReminder(
          enabled: enabled, hour: time.hour, minute: time.minute);
      if (mounted) {
        setState(() {
          _reminderEnabled = enabled;
          _reminderTime = time;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo activar el recordatorio: $error')));
      }
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final end = DateTime(2026, 11, 1);
    final active = DateTime.now().isBefore(end);
    final weights = <String, double>{};
    for (final row in _rows) {
      final value = double.tryParse(row['weight_kg'] ?? '');
      final date = DateTime.tryParse(row['measured_at'] ?? '');
      if (value != null &&
          date != null &&
          date.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        weights.putIfAbsent(row['date']!, () => value);
      }
    }
    final average = weights.isEmpty
        ? null
        : weights.values.reduce((a, b) => a + b) / weights.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in'), actions: [
        IconButton(
            tooltip: 'Exportar / importar datos',
            icon: const Icon(Icons.import_export),
            onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DataScreen()))
                .then((_) => _load())),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  active
                                      ? '19–31 octubre · calibración'
                                      : 'Bloque finalizado · revisar decisión',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              const Text(
                                  '3,000 kcal registradas · 150 g proteína\nMedia semanal orientativa: 2,950–3,050 kcal. Actividad estable: 3,000–4,000 pasos con la misma fuente. No compensar automáticamente con calorías de ejercicio.'),
                              const SizedBox(height: 8),
                              const Text(
                                  'Decisión de fase: 1 noviembre. No cambiar a cut automáticamente desde la app.'),
                            ]))),
                if (average != null)
                  ListTile(
                      title: Text(
                          '${average.toStringAsFixed(2)} kg · últimos 7 días'),
                      subtitle: Text(
                          '${weights.length} fechas, una lectura por día. Los protocolos pueden variar; no incluye días sin dato.')),
                SwitchListTile(
                    title: const Text('Recordatorio de mañana'),
                    subtitle: Text(
                        '${_reminderTime.format(context)} · hasta el 31 Oct · abre este registro'),
                    value: _reminderEnabled,
                    onChanged: _reminderBusy ? null : _remind),
                const Text(
                    'Peso: 5–7 mañanas/semana. Abdomen: lunes, miércoles y sábado, dos lecturas por punto. Fotos relajadas: ahora y 30–31 Oct; después cada 4 semanas. Guárdalas aparte e indica su referencia.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: () => _open('morning'),
                    icon: const Icon(Icons.monitor_weight_outlined),
                    label: const Text('Peso y abdomen')),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                    onPressed: () => _open('daily'),
                    icon: const Icon(Icons.restaurant_outlined),
                    label: const Text('Cerrar comida y actividad')),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                    onPressed: () => _open('tolerance'),
                    icon: const Icon(Icons.healing_outlined),
                    label: const Text('Molestias por ejercicio')),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text('No se pudo leer el registro: $_error'),
                  TextButton(onPressed: _load, child: const Text('Reintentar'))
                ],
                Text('Registros',
                    style: Theme.of(context).textTheme.titleMedium),
                if (_rows.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'Todavía no hay registros. Los datos desconocidos se conservan vacíos.')),
                for (final row in _rows.take(40))
                  Card(
                      child: ListTile(
                    title: Text(
                        '${row['date']} · ${row['kind'] == 'tolerance' ? row['exercise_name'] : row['kind'] == 'daily' ? 'Comida y actividad' : 'Peso y abdomen'}'),
                    subtitle: Text([
                      if ((row['weight_kg'] ?? '').isNotEmpty)
                        '${row['weight_kg']} kg',
                      if ((row['abdomen_upper_cm'] ?? '').isNotEmpty)
                        'Arriba ${row['abdomen_upper_cm']} cm',
                      if ((row['abdomen_lower_cm'] ?? '').isNotEmpty)
                        'Debajo ${row['abdomen_lower_cm']} cm',
                      if ((row['pain_during'] ?? '').isNotEmpty)
                        'Durante ${row['pain_during']}/10',
                      if ((row['discomfort_next_morning'] ?? '').isNotEmpty)
                        'Mañana ${row['discomfort_next_morning']}/10',
                      if ((row['calories_kcal'] ?? '').isNotEmpty)
                        '${row['calories_kcal']} kcal',
                    ].join(' · ')),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _open(row['kind']!, row),
                  )),
              ]),
            ),
    );
  }
}
