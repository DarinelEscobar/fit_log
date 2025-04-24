import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Routine {
  Routine({required this.id, required this.name, required this.frequency});
  final String id;
  String name;
  String frequency;
}

class RoutineExercise {
  RoutineExercise({
    required this.idExercise,
    required this.routineId,
    required this.name,
    required this.muscle,
    required this.series,
    required this.reps,
    required this.weight,
  });
  final String idExercise;
  final String routineId;
  String name;
  String muscle;
  int series;
  int reps;
  double weight;
}

class XlsxRepository {
  static const _routineFileName = 'rutinas.xlsx';
  static const _relFileName = 'rutina_ejercicios.xlsx';
  XlsxRepository._();
  static final XlsxRepository instance = XlsxRepository._();
  Future<Directory> get _docsDir async => await getApplicationDocumentsDirectory();
  Future<File> _routineFile() async {
    final dir = await _docsDir;
    final file = File('${dir.path}/$_routineFileName');
    if (!await file.exists()) {
      final excel = Excel.createExcel();
      final sheet = excel['Rutinas'];
      sheet.appendRow(['id_rutina', 'nombre', 'frecuencia']);
      final bytes = excel.encode();
      await file.writeAsBytes(bytes!, flush: true);
    }
    return file;
  }
  Future<File> _relFile() async {
    final dir = await _docsDir;
    final file = File('${dir.path}/$_relFileName');
    if (!await file.exists()) {
      final excel = Excel.createExcel();
      final sheet = excel['Rel'];
      sheet.appendRow([
        'id_rutina',
        'id_ejercicio',
        'nombre',
        'musculo',
        'series',
        'reps',
        'peso',
      ]);
      final bytes = excel.encode();
      await file.writeAsBytes(bytes!, flush: true);
    }
    return file;
  }
  Future<List<Routine>> getAllRoutines() async {
    final file = await _routineFile();
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Rutinas'];
    final routines = <Routine>[];
    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;
      routines.add(Routine(
        id: row[0]!.value.toString(),
        name: row[1]!.value.toString(),
        frequency: row[2]!.value.toString(),
      ));
    }
    return routines;
  }
  Future<String> addRoutine(String name, {String frequency = '-'}) async {
    final file = await _routineFile();
    final excel = Excel.decodeBytes(file.readAsBytesSync());
    final sheet = excel['Rutinas'];
    final nextId = _nextId(sheet, prefix: 'ru');
    sheet.appendRow([nextId, name, frequency]);
    final updated = excel.encode();
    await file.writeAsBytes(updated!, flush: true);
    return nextId;
  }
  Future<void> deleteRoutine(String id) async {
    final file = await _routineFile();
    final excel = Excel.decodeBytes(file.readAsBytesSync());
    final sheet = excel['Rutinas'];
    for (var i = 1; i < sheet.maxRows; i++) {
      if (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).value == id) {
        sheet.removeRow(i);
        break;
      }
    }
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!, flush: true);
    final relFile = await _relFile();
    final relExcel = Excel.decodeBytes(relFile.readAsBytesSync());
    final relSheet = relExcel['Rel'];
    for (var i = relSheet.maxRows - 1; i >= 1; i--) {
      if (relSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).value == id) {
        relSheet.removeRow(i);
      }
    }
    final relBytes = relExcel.encode();
    await relFile.writeAsBytes(relBytes!, flush: true);
  }
  Future<void> renameRoutine(String id, String newName) async {
    final file = await _routineFile();
    final excel = Excel.decodeBytes(file.readAsBytesSync());
    final sheet = excel['Rutinas'];
    for (var i = 1; i < sheet.maxRows; i++) {
      final idCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
      if (idCell.value == id) {
        // Asignar directamente el nuevo nombre
        final nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i));
        nameCell.value = newName;
        break;
      }
    }
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!, flush: true);
  }
  Future<List<RoutineExercise>> getExercises(String routineId) async {
  final file = await _relFile();
  final excel = Excel.decodeBytes(file.readAsBytesSync());
  final sheet = excel['Rel'];
  final exercises = <RoutineExercise>[];
  for (var i = 1; i < sheet.maxRows; i++) {
    final row = sheet.row(i);
    // Verificar si la fila tiene todas las columnas necesarias
    if (row.length < 7) continue;
    final cellRoutineId = row[0]?.value.toString();
    if (cellRoutineId != routineId) continue;
    // Extraer valores con manejo de nulos
    final idExercise = row[1]?.value.toString() ?? '';
    final name = row[2]?.value.toString() ?? '';
    final muscle = row[3]?.value.toString() ?? '';
    final series = int.tryParse(row[4]?.value.toString() ?? '') ?? 0;
    final reps = int.tryParse(row[5]?.value.toString() ?? '') ?? 0;
    final weight = double.tryParse(row[6]?.value.toString() ?? '') ?? 0.0;
    exercises.add(RoutineExercise(
      routineId: routineId,
      idExercise: idExercise,
      name: name,
      muscle: muscle,
      series: series,
      reps: reps,
      weight: weight,
    ));
  }
  return exercises;
}

  Future<void> addExercise({
    required String routineId,
    required String name,
    required String muscle,
    required int series,
    required int reps,
    required double weight,
  }) async {
    try {
      final file = await _relFile();
      final excel = Excel.decodeBytes(file.readAsBytesSync());
      final sheet = excel['Rel'];
      final nextId = _nextId(sheet, prefix: 'ex', idColumn: 1);
      sheet.appendRow([routineId, nextId, name, muscle, series, reps, weight]);
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Error al codificar el Excel de ejercicios');
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      debugPrint('Error añadiendo ejercicio: $e');
      rethrow;
    }
  }
  Future<void> deleteExercise(String routineId, String exerciseId) async {
    final file = await _relFile();
    final excel = Excel.decodeBytes(file.readAsBytesSync());
    final sheet = excel['Rel'];
    for (var i = 1; i < sheet.maxRows; i++) {
      final rutId = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).value;
      final exId = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i)).value;
      if (rutId == routineId && exId == exerciseId) {
        sheet.removeRow(i);
        break;
      }
    }
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!, flush: true);
  }
  String _nextId(Sheet sheet, {required String prefix, int idColumn = 0}) {
  final ids = <int>[];
  for (var i = 1; i < sheet.maxRows; i++) {
    final val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: idColumn, rowIndex: i)).value;
    if (val != null && val.toString().startsWith(prefix)) {
      final numPart = int.tryParse(val.toString().substring(prefix.length));
      if (numPart != null) ids.add(numPart);
    }
  }
  final nextNum = ids.isEmpty ? 1 : (ids.reduce((a, b) => a > b ? a : b) + 1);
  return '$prefix${nextNum.toString().padLeft(3, '0')}';
}
}


class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  static const String routeName = '/routines';

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}


class _RoutinesScreenState extends State<RoutinesScreen> {
  final repo = XlsxRepository.instance;
  late Future<List<Routine>> _futureRoutines;
  @override
  void initState() {
    super.initState();
    _load();
  }
  void _load() {
    setState(() {
      _futureRoutines = repo.getAllRoutines();
    });
  }
  Future<void> _createRoutine() async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva rutina'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok == true && nameController.text.trim().isNotEmpty) {
      await repo.addRoutine(nameController.text.trim());
      _load();
    }
  }
  Future<void> _deleteRoutine(Routine r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: Text('¿Eliminar "${r.name}" y todos sus ejercicios?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await repo.deleteRoutine(r.id);
      _load();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas')),
      body: FutureBuilder<List<Routine>>(
        future: _futureRoutines,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final routines = snap.data!;
          if (routines.isEmpty) return const Center(child: Text('Sin rutinas aún'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) => Dismissible(
              key: ValueKey(routines[i].id),
              background: Container(color: Colors.red.withOpacity(0.7), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                await _deleteRoutine(routines[i]);
                return false;
              },
              child: ListTile(
                title: Text(routines[i].name),
                subtitle: Text('ID: ${routines[i].id}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routines[i]))).then((_) => _load()),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _createRoutine, icon: const Icon(Icons.add), label: const Text('Nueva rutina')),
    );
  }
}

class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({super.key, required this.routine});
  final Routine routine;
  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  final repo = XlsxRepository.instance;
  late Future<List<RoutineExercise>> _futureExercises;
  @override
  void initState() {
    super.initState();
    _load();
  }
  void _load() {
    setState(() {
      _futureExercises = repo.getExercises(widget.routine.id);
    });
  }
  Future<void> _addExercise() async {
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();
    final seriesCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir ejercicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: muscleCtrl, decoration: const InputDecoration(labelText: 'Músculo')),
              TextField(controller: seriesCtrl, decoration: const InputDecoration(labelText: 'Series'), keyboardType: TextInputType.number),
              TextField(controller: repsCtrl, decoration: const InputDecoration(labelText: 'Reps'), keyboardType: TextInputType.number),
              TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Peso (kg)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Agregar')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
    try {
      await repo.addExercise(
        routineId: widget.routine.id,
        name: nameCtrl.text.trim(),
        muscle: muscleCtrl.text.trim(),
        series: int.tryParse(seriesCtrl.text) ?? 0,
        reps: int.tryParse(repsCtrl.text) ?? 0,
        weight: double.tryParse(weightCtrl.text) ?? 0,
      );
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo añadir el ejercicio: $e'))
      );
    }
  }

  }
  Future<void> _deleteExercise(RoutineExercise ex) async {
    await repo.deleteExercise(widget.routine.id, ex.idExercise);
    _load();
  }
  Future<void> _renameRoutine() async {
  final ctrl = TextEditingController(text: widget.routine.name);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Renombrar rutina'),
      content: TextField(controller: ctrl),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
      ],
    ),
  );

  if (ok == true && ctrl.text.trim().isNotEmpty) {
    final newName = ctrl.text.trim();
    await repo.renameRoutine(widget.routine.id, newName);
    setState(() {
      // Actualiza título de AppBar
      widget.routine.name = newName;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rutina renombrada a "$newName"'))
    );
    // Opcional: si quieres volver automáticamente a la lista y disparar el reload:
    // Navigator.pop(context);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: _renameRoutine)],
      ),
      body: FutureBuilder<List<RoutineExercise>>(
        future: _futureExercises,
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final exs = snap.data!;
          if (exs.isEmpty) return const Center(child: Text('Sin ejercicios'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) => Dismissible(
              key: ValueKey(exs[i].idExercise),
              background: Container(color: Colors.red.withOpacity(0.7), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _deleteExercise(exs[i]),
              child: ListTile(
                title: Text(exs[i].name),
                subtitle: Text('${exs[i].series}x${exs[i].reps} • ${exs[i].weight} kg'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addExercise, icon: const Icon(Icons.add), label: const Text('Añadir ejercicio')),
    );
  }
}
