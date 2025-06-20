part of 'start_routine_screen.dart';

mixin StartRoutineDialogs on ConsumerState<StartRoutineScreen> {
  Future<bool> _confirmExit(BuildContext ctx) async =>
      (await showModalBottomSheet<bool>(
        context: ctx,
        backgroundColor: const Color(0xFF1F1F1F),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('¿Salir sin guardar?',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white38)),
            const SizedBox(height: 8),
            const Text('Perderás el progreso de esta sesión.',
                style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Salir'))),
            ]),
          ]),
        ),
      )) ??
      false;

  Future<bool> _showFinishDialog(BuildContext ctx) async {
    String lf = _fatigue, lm = _mood;
    final noteCtl = TextEditingController(text: _notesCtl.text);
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Finalizar sesión'),
          titleTextStyle: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleDropdown(
                  icon: Icons.bolt,
                  val: lf,
                  list: _scale10,
                  onC: (v) => setState(() => lf = v)),
              const SizedBox(height: 8),
              ScaleDropdown(
                  icon: Icons.mood,
                  val: lm,
                  list: _scale5,
                  onC: (v) => setState(() => lm = v)),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  focusedBorder:
                      OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dCtx).pop(false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.of(dCtx).pop(true),
                child: const Text('Finalizar')),
          ],
        ),
      ),
    );
    if (ok == true) {
      _fatigue = lf;
      _mood = lm;
      _notesCtl.text = noteCtl.text;
    }
    return ok ?? false;
  }
}
