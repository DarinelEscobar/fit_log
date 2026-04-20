import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_data_providers.dart';

class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final file = await ref.refresh(exportDataProvider.future);
                  if (!context.mounted) return;
                  _showMessage(context, 'Exportado: ${file.path}');
                } catch (e) {
                  if (!context.mounted) return;
                  _showMessage(context, 'Error al exportar datos: $e');
                }
              },
              child: const Text('Exportar Datos'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final file = await ref.refresh(exportDataProvider.future);
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: 'Backup Fit Log',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  _showMessage(context, 'Error al compartir backup: $e');
                }
              },
              child: const Text('Compartir Backup'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final res = await FilePicker.platform.pickFiles();
                if (!context.mounted ||
                    res == null ||
                    res.files.single.path == null) {
                  return;
                }
                final file = File(res.files.single.path!);
                try {
                  await ref.read(importDataProvider(file).future);
                  if (!context.mounted) return;
                  _showMessage(context, 'Datos importados');
                } catch (e) {
                  if (!context.mounted) return;
                  _showMessage(context, 'Error al importar datos: $e');
                }
              },
              child: const Text('Importar Datos'),
            ),
          ],
        ),
      ),
    );
  }
}
