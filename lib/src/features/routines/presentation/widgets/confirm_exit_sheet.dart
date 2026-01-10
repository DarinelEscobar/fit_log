import 'package:flutter/material.dart';

Future<bool> showConfirmExitSheet(BuildContext context) async =>
    (await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            '¿Salir sin guardar?',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white38),
          ),
          const SizedBox(height: 8),
          const Text(
            'Perderás el progreso de esta sesión.',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salir'),
              ),
            ),
          ]),
        ]),
      ),
    )) ??
    false;
