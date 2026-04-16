import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_data_providers.dart';

class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFCC97FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DATA MANAGEMENT',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFFCC97FF),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFADAAAB)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF131314),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Your Journey',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Manage your workout logs, PR history, and custom routines. All data is stored locally. Use the tools below to backup or transfer your records.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFFADAAAB),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: -32,
                      top: -32,
                      child: Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFCC97FF).withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCC97FF).withValues(alpha: 0.2),
                              blurRadius: 100,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildActionCard(
                icon: Icons.download,
                iconColor: const Color(0xFFCC97FF),
                title: 'Export Data',
                badgeText: 'JSON/CSV',
                badgeColor: const Color(0xFFCC97FF),
                description: 'Generate a comprehensive archive of your entire workout history and personal bests. Portable and ready for external analysis.',
                actionText: 'START EXPORT',
                actionColor: const Color(0xFFCC97FF),
                onTap: () async {
                  final file = await ref.read(exportDataProvider.future);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exportado: ${file.path}')),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildActionCard(
                icon: Icons.ios_share,
                iconColor: const Color(0xFFCC97FF),
                title: 'Share Backup',
                badgeText: 'SYNC',
                badgeColor: const Color(0xFFCC97FF),
                description: 'Quickly send an encrypted backup file to another device or cloud storage to ensure your progress is never lost.',
                actionText: 'CHOOSE DESTINATION',
                actionColor: const Color(0xFFCC97FF),
                onTap: () async {
                  final file = await ref.read(exportDataProvider.future);
                  await Share.shareXFiles([XFile(file.path)], text: 'Backup Fit Log');
                },
              ),

              const SizedBox(height: 16),

              _buildActionCard(
                icon: Icons.upload_file,
                iconColor: const Color(0xFFFF6B6B),
                title: 'Import Data',
                badgeText: 'DESTRUCTIVE',
                badgeColor: const Color(0xFFFF6B6B),
                description: 'Replace your current logs with an external backup file. This action will permanently overwrite all existing data on this device.',
                actionText: 'VERIFY & IMPORT',
                actionColor: const Color(0xFFFF6B6B),
                isDestructive: true,
                onTap: () async {
                  final res = await FilePicker.platform.pickFiles();
                  if (res == null || res.files.single.path == null) return;
                  final f = File(res.files.single.path!);
                  try {
                    await ref.read(importDataProvider(f).future);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos importados')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al importar datos: $e')),
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF484849)),
                    const SizedBox(height: 8),
                    Text(
                      'LAST BACKUP: UNKNOWN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFF484849).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String description,
    required String actionText,
    required Color actionColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFF201F21) : const Color(0xFF1A191B),
          borderRadius: BorderRadius.circular(16),
          border: isDestructive ? Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.1)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            if (isDestructive) ...[
                              Icon(Icons.warning, size: 12, color: badgeColor),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFADAAAB),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        actionText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: actionColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: actionColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
