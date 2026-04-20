import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../navigation/widgets/kinetic_bottom_nav_bar.dart';
import '../../../../theme/kinetic_noir.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../domain/usecases/export_app_data_usecase.dart';
import '../../domain/usecases/import_app_data_usecase.dart';
import '../providers/app_data_providers.dart';
import '../../../routines/presentation/providers/exercises_provider.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';

enum DataScreenResult {
  goHome,
  goRoutines,
}

enum _DataAction {
  export,
  share,
  import,
}

class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  _DataAction? _activeAction;
  String _backupStatus = 'BACKUP FILE CREATED ON DEMAND DURING EXPORT';

  bool get _isBusy => _activeAction != null;

  @override
  void initState() {
    super.initState();
    _refreshBackupStatus();
  }

  Future<void> _refreshBackupStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File(p.join(directory.path, 'fitlog_backup.zip'));
      if (!await backupFile.exists()) {
        if (!mounted) return;
        setState(() {
          _backupStatus = 'BACKUP FILE CREATED ON DEMAND DURING EXPORT';
        });
        return;
      }

      final modified = await backupFile.lastModified();
      final formatted = DateFormat('MMM dd, yyyy • HH:mm').format(modified);
      if (!mounted) return;
      setState(() {
        _backupStatus = 'LAST LOCAL BACKUP: $formatted';
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _backupStatus = 'BACKUP STATUS IS AVAILABLE ON DEVICE BUILDS';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backupStatus = 'BACKUP STATUS COULD NOT BE READ';
      });
    }
  }

  Future<void> _runAction(_DataAction action) async {
    if (_isBusy) return;

    setState(() {
      _activeAction = action;
    });

    try {
      switch (action) {
        case _DataAction.export:
          await _exportData();
          break;
        case _DataAction.share:
          await _shareBackup();
          break;
        case _DataAction.import:
          await _importData();
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _activeAction = null;
        });
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final repo = ref.read(appDataRepositoryProvider);
      final file = await ExportAppDataUseCase(repo)();
      if (!mounted) return;
      _showMessage('Export ready: ${file.path}');
      await _refreshBackupStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Export failed: $error', isError: true);
    }
  }

  Future<void> _shareBackup() async {
    try {
      final repo = ref.read(appDataRepositoryProvider);
      final file = await ExportAppDataUseCase(repo)();
      await Share.shareXFiles([XFile(file.path)], text: 'Backup Fit Log');
      if (!mounted) return;
      _showMessage('Backup ready to share');
      await _refreshBackupStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to share backup: $error', isError: true);
    }
  }

  Future<void> _importData() async {
    final confirmed = await _confirmImport();
    if (confirmed != true || !mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) {
        if (!mounted) return;
        _showMessage('Import cancelled');
        return;
      }

      final file = File(result.files.single.path!);
      final repo = ref.read(appDataRepositoryProvider);
      await ImportAppDataUseCase(repo)(file);
      ref.invalidate(workoutPlanProvider);
      ref.invalidate(allExercisesProvider);
      ref.invalidate(workoutLogsProvider);
      ref.invalidate(workoutSessionsProvider);
      ref.read(routineLibraryMetadataEpochProvider.notifier).state++;
      if (!mounted) return;
      _showMessage('Data imported');
      await _refreshBackupStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Import failed: $error', isError: true);
    }
  }

  Future<bool?> _confirmImport() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: KineticNoirPalette.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Replace current data?',
            style: KineticNoirTypography.headline(
                size: 24, weight: FontWeight.w700),
          ),
          content: Text(
            'Importing a backup will overwrite the current logs stored on this device.',
            style: KineticNoirTypography.body(
              size: 15,
              weight: FontWeight.w500,
              color: KineticNoirPalette.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: KineticNoirTypography.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    KineticNoirPalette.error.withValues(alpha: 0.18),
                foregroundColor: KineticNoirPalette.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Import',
                style: KineticNoirTypography.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? KineticNoirPalette.error
            : KineticNoirPalette.surfaceBright,
        content: Text(message),
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    if (_isBusy) return;
    switch (index) {
      case 0:
        Navigator.pop(context, DataScreenResult.goHome);
        break;
      case 1:
        Navigator.pop(context, DataScreenResult.goRoutines);
        break;
      case 2:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KineticNoirPalette.background,
      appBar: AppBar(
        backgroundColor: KineticNoirPalette.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: KineticNoirPalette.primary,
        ),
        title: Text(
          'DATA MANAGEMENT',
          key: const Key('data-screen-title'),
          style: KineticNoirTypography.headline(
            size: 24,
            weight: FontWeight.w700,
            color: KineticNoirPalette.primary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              Icons.more_vert_rounded,
              color: KineticNoirPalette.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 130),
        children: [
          const _HeroCard(),
          const SizedBox(height: 22),
          _DataActionCard(
            title: 'Export Data',
            description:
                'Generate a comprehensive archive of your entire workout history and personal bests. Portable and ready for external analysis.',
            badge: 'JSON/CSV',
            actionLabel: 'START EXPORT',
            icon: Icons.download_rounded,
            accentColor: KineticNoirPalette.primary,
            isBusy: _activeAction == _DataAction.export,
            onTap: () => _runAction(_DataAction.export),
          ),
          const SizedBox(height: 14),
          _DataActionCard(
            title: 'Share Backup',
            description:
                'Quickly send an encrypted backup file to another device or cloud storage to ensure your progress is never lost.',
            badge: 'SYNC',
            actionLabel: 'CHOOSE DESTINATION',
            icon: Icons.ios_share_rounded,
            accentColor: KineticNoirPalette.primary,
            isBusy: _activeAction == _DataAction.share,
            onTap: () => _runAction(_DataAction.share),
          ),
          const SizedBox(height: 14),
          _DataActionCard(
            title: 'Import Data',
            description:
                'Replace your current logs with an external backup file. This action will permanently overwrite all existing data on this device.',
            badge: 'DESTRUCTIVE',
            actionLabel: 'VERIFY & IMPORT',
            icon: Icons.upload_file_rounded,
            accentColor: KineticNoirPalette.error,
            isDestructive: true,
            isBusy: _activeAction == _DataAction.import,
            onTap: () => _runAction(_DataAction.import),
          ),
          const SizedBox(height: 26),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: KineticNoirPalette.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
                const SizedBox(height: 10),
                Text(
                  _backupStatus,
                  textAlign: TextAlign.center,
                  style: KineticNoirTypography.body(
                    size: 10,
                    weight: FontWeight.w800,
                    color: KineticNoirPalette.onSurfaceVariant
                        .withValues(alpha: 0.58),
                    letterSpacing: 2.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: KineticBottomNavBar(
        selectedIndex: 2,
        onTap: _handleBottomNavigation,
        items: const [
          KineticBottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          KineticBottomNavItem(
              icon: Icons.fitness_center_rounded, label: 'Routines'),
          KineticBottomNavItem(icon: Icons.settings_rounded, label: 'Data'),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: KineticNoirPalette.surfaceLow,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Your Journey',
                  style: KineticNoirTypography.headline(
                      size: 24, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 310),
                  child: Text(
                    'Manage your workout logs, PR history, and custom routines. All data is stored locally. Use the tools below to backup or transfer your records.',
                    style: KineticNoirTypography.body(
                      size: 15,
                      weight: FontWeight.w500,
                      color: KineticNoirPalette.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -46,
            top: -58,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KineticNoirPalette.primary.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: KineticNoirPalette.primary.withValues(alpha: 0.12),
                      blurRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataActionCard extends StatelessWidget {
  const _DataActionCard({
    required this.title,
    required this.description,
    required this.badge,
    required this.actionLabel,
    required this.icon,
    required this.accentColor,
    required this.isBusy,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final String description;
  final String badge;
  final String actionLabel;
  final IconData icon;
  final Color accentColor;
  final bool isBusy;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: isDestructive
                ? const Color(0xFF201F21)
                : KineticNoirPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: isDestructive
                ? Border.all(color: accentColor.withValues(alpha: 0.16))
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isBusy
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      )
                    : Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: KineticNoirTypography.headline(
                              size: 25,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: KineticNoirTypography.body(
                              size: 10,
                              weight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: KineticNoirTypography.body(
                        size: 14,
                        weight: FontWeight.w500,
                        color: KineticNoirPalette.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel,
                          style: KineticNoirTypography.body(
                            size: 12,
                            weight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
