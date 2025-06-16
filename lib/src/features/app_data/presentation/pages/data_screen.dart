import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_data_providers.dart';

class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});

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
                final file = await ref.read(exportDataProvider.future);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exportado: ${file.path}')),
                );
              },
              child: const Text('Exportar Datos'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final res = await FilePicker.platform.pickFiles();
                if (res == null || res.files.single.path == null) return;
                final f = File(res.files.single.path!);
                await ref.read(importDataProvider(f).future);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Datos importados')),
                );
              },
              child: const Text('Importar Datos'),
            ),
          ],
        ),
      ),
    );
  }
}
