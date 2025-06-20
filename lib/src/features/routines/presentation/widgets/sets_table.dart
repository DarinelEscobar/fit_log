import 'package:flutter/material.dart';
import '../../domain/entities/set_entry.dart';

class SetsTable extends StatefulWidget {
  final List<SetEntry> sets;
  final bool editable;
  const SetsTable(this.sets, {this.editable = false, super.key});

  @override
  State<SetsTable> createState() => _SetsTableState();
}

class _SetsTableState extends State<SetsTable> {
  late List<SetEntry> _data;

  @override
  void initState() {
    super.initState();
    _data = List.from(widget.sets);
  }

  void _duplicateLast() {
    if (_data.isEmpty) return;
    setState(() {
      _data.add(_data.last);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = List.generate(_data.length, (i) {
      final set = _data[i];
      return Row(
        children: [
          Expanded(child: Text('${set.reps}')), // reps
          Expanded(child: Text('${set.weight}kg')),
          Expanded(child: Text('${set.rir}')),
          Checkbox(
            value: set.completed,
            onChanged: widget.editable
                ? (v) => setState(() {
                      _data[i] = set.copyWith(completed: v ?? false);
                    })
                : null,
          ),
        ],
      );
    });

    return Column(
      children: [
        ...rows,
        if (widget.editable)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _duplicateLast,
            ),
          ),
      ],
    );
  }
}
