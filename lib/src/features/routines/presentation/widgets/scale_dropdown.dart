import 'package:flutter/material.dart';

class ScaleDropdown extends StatelessWidget {
  const ScaleDropdown({
    super.key,
    required this.icon,
    required this.val,
    required this.list,
    required this.onC,
  });

  final IconData icon;
  final String val;
  final List<String> list;
  final ValueChanged<String> onC;

  @override
  Widget build(BuildContext ctx) {
    return DropdownButtonFormField<String>(
      value: val,
      dropdownColor: const Color(0xFF2A2A2A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        border: const OutlineInputBorder(),
      ),
      items: list.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onC(v ?? val),
    );
  }
}
