part of 'exercise_tile.dart';

mixin ExerciseTileUIHelpers on State<ExerciseTile> {
  ElevatedButton _actionBtn(IconData ic, VoidCallback fn) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(0),
          backgroundColor: const Color(0xFF2A2A2A),
        ),
        onPressed: fn,
        child: Icon(ic, size: 20, color: Colors.white),
      );

  Widget _num(TextEditingController c, double w, String label, int idx, bool enabled) =>
      SizedBox(
        width: w + 24,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: c,
                enabled: enabled,
                onChanged: (_) {
                  _persist(idx);
                  widget.onChanged();
                },
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: enabled ? Colors.white : Colors.white38),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  filled: true,
                  fillColor: enabled ? const Color(0xFF2A2A2A) : Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38, fontSize: 13)),
          ],
        ),
      );

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            Text(value, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      );

  Widget _deltaBadge(int delta, Color color, IconData icon, String tooltip) => Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Text('\${delta > 0 ? '+' : ''}\$delta%',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
}
