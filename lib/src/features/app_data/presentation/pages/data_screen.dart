import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../theme/kinetic_noir.dart';
import '../../../../theme/toru_brand.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../../performance/presentation/providers/performance_providers.dart';
import '../../domain/usecases/export_app_data_usecase.dart';
import '../../domain/usecases/import_app_data_usecase.dart';
import '../../domain/entities/export_models.dart';
import '../../domain/repositories/app_data_repository.dart';
import '../providers/app_data_providers.dart';
import '../../../routines/presentation/providers/exercises_provider.dart';
import '../../../routines/presentation/providers/workout_plan_provider.dart';

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
      final backupFiles = (await directory.list().toList())
          .whereType<File>()
          .where(
            (file) =>
                p.basename(file.path).startsWith('fitlog_backup_') &&
                p.extension(file.path).toLowerCase() == '.zip',
          )
          .toList();
      final legacyBackup = File(p.join(directory.path, 'fitlog_backup.zip'));
      if (backupFiles.isEmpty && !await legacyBackup.exists()) {
        if (!mounted) return;
        setState(() {
          _backupStatus = 'BACKUP FILE CREATED ON DEMAND DURING EXPORT';
        });
        return;
      }

      File backupFile = legacyBackup;
      if (backupFiles.isNotEmpty) {
        backupFile = backupFiles.first;
        var latestModified = await backupFile.lastModified();
        for (final candidate in backupFiles.skip(1)) {
          final modified = await candidate.lastModified();
          if (modified.isAfter(latestModified)) {
            backupFile = candidate;
            latestModified = modified;
          }
        }
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
      final request = await _chooseExportRequest(repo);
      if (request == null) return;
      final file = await ExportAppDataUseCase(repo)(request: request);
      if (!mounted) return;
      _showMessage(
        title: 'Backup exported',
        detail: 'Saved as ${p.basename(file.path)}.',
      );
      await _refreshBackupStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        title: 'Export failed',
        detail: _friendlyError(error),
        isError: true,
      );
    }
  }

  Future<void> _shareBackup() async {
    try {
      final repo = ref.read(appDataRepositoryProvider);
      final request = await _chooseExportRequest(repo);
      if (request == null) return;
      final file = await ExportAppDataUseCase(repo)(request: request);
      await Share.shareXFiles([XFile(file.path)], text: 'Backup Fit Log');
      if (!mounted) return;
      _showMessage(
        title: 'Backup ready to share',
        detail: 'Choose where you want to keep the file.',
      );
      await _refreshBackupStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        title: 'Unable to share backup',
        detail: _friendlyError(error),
        isError: true,
      );
    }
  }

  Future<ExportRequest?> _chooseExportRequest(AppDataRepository repo) async {
    final availability = await repo.getExportAvailability();
    if (!mounted) return null;
    return showDialog<ExportRequest>(
      context: context,
      builder: (_) => _ExportRangeDialog(availability: availability),
    );
  }

  Future<void> _importData() async {
    final confirmed = await _confirmImport();
    if (confirmed != true || !mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) {
        if (!mounted) return;
        _showMessage(title: 'Import cancelled');
        return;
      }

      final file = File(result.files.single.path!);
      final repo = ref.read(appDataRepositoryProvider);
      await ImportAppDataUseCase(repo)(file);
      ref.invalidate(workoutPlanProvider);
      ref.invalidate(allExercisesProvider);
      ref.invalidate(workoutLogsProvider);
      ref.invalidate(workoutSessionsProvider);
      ref.invalidate(performanceDashboardProvider);
      ref.invalidate(exerciseProgressDetailProvider);
      ref.read(routineLibraryMetadataEpochProvider.notifier).state++;
      if (!mounted) return;
      _showMessage(
        title: 'Data imported',
        detail: 'Routines, logs, and charts were refreshed.',
      );
      await _refreshBackupStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        title: 'Import failed',
        detail: '${_friendlyError(error)} Current data was not changed.',
        isError: true,
      );
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

  String _friendlyError(Object error) {
    final message = error is FormatException
        ? error.message
        : error is StateError
            ? error.message
            : error.toString().replaceFirst('Exception: ', '');
    return message.trim().isEmpty ? 'Please try again.' : message;
  }

  void _showMessage({
    required String title,
    String? detail,
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: isError
            ? KineticNoirPalette.error
            : KineticNoirPalette.surfaceBright,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: KineticNoirTypography.body(
                size: 14,
                weight: FontWeight.w800,
                color: isError
                    ? KineticNoirPalette.onPrimary
                    : KineticNoirPalette.onSurface,
              ),
            ),
            if (detail != null && detail.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                style: KineticNoirTypography.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: isError
                      ? KineticNoirPalette.onPrimary
                      : KineticNoirPalette.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
        children: [
          const _HeroCard(),
          const SizedBox(height: 22),
          _DataActionCard(
            title: 'Export Data',
            description:
                'Export only the missing workout dates or choose a custom range. Each backup includes its date range in the file name.',
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
                'Create a date-range backup and send it to another device or cloud storage. Automatic exports avoid dates already backed up.',
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
    );
  }
}

class _ExportRangeDialog extends StatefulWidget {
  const _ExportRangeDialog({required this.availability});

  final ExportAvailability availability;

  @override
  State<_ExportRangeDialog> createState() => _ExportRangeDialogState();
}

class _ExportRangeDialogState extends State<_ExportRangeDialog> {
  bool _useCustomRange = false;
  DateTimeRange? _customRange;

  Future<void> _pickCustomRange() async {
    final availability = widget.availability;
    final firstDate = availability.firstDate ?? DateTime(2020);
    final lastDate = availability.lastDate != null &&
            availability.lastDate!.isAfter(DateTime.now())
        ? availability.lastDate!
        : DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _customRange ??
          (availability.firstDate != null && availability.lastDate != null
              ? DateTimeRange(
                  start: availability.firstDate!,
                  end: availability.lastDate!,
                )
              : null),
      helpText: 'SELECT EXPORT RANGE',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _useCustomRange = true;
      _customRange = picked;
    });
  }

  String _formatRange(ExportDateRange? range) {
    if (range == null) return 'No unexported dates found';
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(range.startDate)} – ${format.format(range.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final availability = widget.availability;
    return AlertDialog(
      backgroundColor: KineticNoirPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Choose export range',
        style:
            KineticNoirTypography.headline(size: 22, weight: FontWeight.w700),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (availability.hasWorkoutData)
                Text(
                  'Available: ${_formatRange(ExportDateRange(availability.firstDate!, availability.lastDate!))}',
                  style: KineticNoirTypography.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => setState(() => _useCustomRange = false),
                leading: Icon(
                  _useCustomRange
                      ? Icons.radio_button_unchecked
                      : Icons.radio_button_checked,
                  color: KineticNoirPalette.primary,
                ),
                title: const Text('Missing dates automatically'),
                subtitle: Text(_formatRange(availability.nextMissingRange)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() => _useCustomRange = true);
                  if (_customRange == null) _pickCustomRange();
                },
                leading: Icon(
                  _useCustomRange
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: KineticNoirPalette.primary,
                ),
                title: const Text('Choose a custom range'),
                subtitle: Text(
                  _customRange == null
                      ? 'Select the dates to include'
                      : '${DateFormat('MMM dd, yyyy').format(_customRange!.start)} – ${DateFormat('MMM dd, yyyy').format(_customRange!.end)}',
                ),
              ),
              if (availability.lastExportedDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Last export through ${DateFormat('MMM dd, yyyy').format(availability.lastExportedDate!)}',
                    style: KineticNoirTypography.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _useCustomRange && _customRange == null
              ? _pickCustomRange
              : () {
                  if (_useCustomRange) {
                    final range = _customRange;
                    if (range == null) return;
                    Navigator.pop(
                      context,
                      ExportRequest.custom(
                        ExportDateRange(range.start, range.end),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, const ExportRequest.automatic());
                },
          style: FilledButton.styleFrom(
            backgroundColor: KineticNoirPalette.primary.withValues(alpha: 0.18),
            foregroundColor: KineticNoirPalette.primary,
          ),
          child: Text(_useCustomRange ? 'Use custom range' : 'Export missing'),
        ),
      ],
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
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            KineticNoirPalette.primary.withValues(alpha: 0.12),
                        boxShadow: [
                          BoxShadow(
                            color: KineticNoirPalette.primary.withValues(
                              alpha: 0.12,
                            ),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                    ),
                    const ToruMark(
                      size: 108,
                      variant: ToruMarkVariant.white,
                      opacity: 0.18,
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
