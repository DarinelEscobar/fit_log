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
  exportAndShare,
  import,
}

class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  _DataAction? _activeAction;
  bool _isPickingRange = false;
  String _backupStatus = 'BACKUP FILE CREATED ON DEMAND DURING EXPORT';

  bool get _isBusy => _activeAction != null || _isPickingRange;

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

    switch (action) {
      case _DataAction.exportAndShare:
        await _exportAndShareBackup();
        break;
      case _DataAction.import:
        await _importData();
        break;
    }
  }

  Future<void> _exportAndShareBackup() async {
    final repo = ref.read(appDataRepositoryProvider);

    setState(() => _isPickingRange = true);
    final ExportRequest? request;
    try {
      request = await _chooseExportRequest(repo);
    } finally {
      if (mounted) {
        setState(() => _isPickingRange = false);
      }
    }

    if (request == null || !mounted) return;

    setState(() => _activeAction = _DataAction.exportAndShare);
    try {
      final file = await ExportAppDataUseCase(repo)(request: request);
      final shareService = ref.read(backupShareServiceProvider);
      final result = await shareService.shareBackupFile(file);
      if (!mounted) return;

      if (result.status == ShareResultStatus.dismissed) {
        _showMessage(
          title: 'Backup saved locally',
          detail: 'Saved as ${p.basename(file.path)}. Sharing was cancelled.',
        );
      } else if (result.status == ShareResultStatus.unavailable) {
        _showMessage(
          title: 'Backup saved locally',
          detail:
              'Saved as ${p.basename(file.path)}. Sharing is not available on this device.',
        );
      } else {
        _showMessage(
          title: 'Backup exported and shared',
          detail: 'Saved as ${p.basename(file.path)}.',
        );
      }
      await _refreshBackupStatus();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        title: 'Export failed',
        detail: _friendlyError(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
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
            'Import a backup?',
            style: KineticNoirTypography.headline(
                size: 24, weight: FontWeight.w700),
          ),
          content: Text(
            'Incremental backups merge workout history. Full backups and spreadsheet imports can replace current data. Choose a trusted backup to continue.',
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
          const SizedBox(height: 20),
          _DataActionCard(
            key: const Key('export-share-backup-card'),
            title: 'Export & Share Backup',
            description:
                'Create a verified backup archive and open the system share sheet to save or send it.',
            badge: 'ZIP ARCHIVE',
            actionLabel: 'EXPORT & SHARE',
            icon: Icons.ios_share_rounded,
            accentColor: KineticNoirPalette.primary,
            isBusy: _activeAction == _DataAction.exportAndShare,
            onTap: _isBusy ? null : () => _runAction(_DataAction.exportAndShare),
          ),
          const SizedBox(height: 14),
          _DataActionCard(
            key: const Key('import-backup-card'),
            title: 'Import Backup',
            description:
                'Merge incremental workout history or restore a full backup. Full restores can replace current data.',
            badge: 'RESTORE',
            actionLabel: 'VERIFY & IMPORT',
            icon: Icons.upload_file_rounded,
            accentColor: KineticNoirPalette.error,
            isDestructive: true,
            isBusy: _activeAction == _DataAction.import,
            onTap: _isBusy ? null : () => _runAction(_DataAction.import),
          ),
          const SizedBox(height: 24),
          _BackupStatusBanner(status: _backupStatus),
        ],
      ),
    );
  }
}

enum _ExportPreset {
  automatic,
  full,
  custom,
}

class _ExportRangeDialog extends StatefulWidget {
  const _ExportRangeDialog({required this.availability});

  final ExportAvailability availability;

  @override
  State<_ExportRangeDialog> createState() => _ExportRangeDialogState();
}

class _ExportRangeDialogState extends State<_ExportRangeDialog> {
  late _ExportPreset _selectedPreset;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    if (widget.availability.nextMissingRange != null) {
      _selectedPreset = _ExportPreset.automatic;
    } else {
      _selectedPreset = _ExportPreset.full;
    }
  }

  Future<void> _pickCustomRange() async {
    final availability = widget.availability;
    final firstDate = availability.firstDate ?? DateTime(2020);
    final now = DateTime.now();
    var lastDate = availability.lastDate != null &&
            availability.lastDate!.isAfter(now)
        ? availability.lastDate!
        : now;
    if (lastDate.isBefore(firstDate)) {
      lastDate = firstDate;
    }

    final initialStart = _customRange?.start ??
        availability.firstDate ??
        DateTime(now.year, now.month, 1);
    final initialEnd = _customRange?.end ??
        availability.lastDate ??
        now;

    final clampedStart = initialStart.isBefore(firstDate)
        ? firstDate
        : (initialStart.isAfter(lastDate) ? lastDate : initialStart);
    final clampedEnd = initialEnd.isAfter(lastDate)
        ? lastDate
        : (initialEnd.isBefore(clampedStart) ? clampedStart : initialEnd);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(
        start: clampedStart,
        end: clampedEnd,
      ),
      helpText: 'SELECT EXPORT RANGE',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: KineticNoirPalette.primary,
              surface: KineticNoirPalette.surface,
              onSurface: KineticNoirPalette.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedPreset = _ExportPreset.custom;
      _customRange = picked;
    });
  }

  String _formatRange(ExportDateRange? range) {
    if (range == null) return 'No dates';
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(range.startDate)} – ${format.format(range.endDate)}';
  }

  ExportDateRange? get _currentEffectiveRange {
    final availability = widget.availability;
    switch (_selectedPreset) {
      case _ExportPreset.automatic:
        return availability.nextMissingRange ??
            (!availability.hasWorkoutData && !availability.hasExportHistory
                ? ExportDateRange(DateTime.now(), DateTime.now())
                : null);
      case _ExportPreset.full:
        return availability.fullRange ??
            ExportDateRange(DateTime.now(), DateTime.now());
      case _ExportPreset.custom:
        if (_customRange == null) return null;
        return ExportDateRange(_customRange!.start, _customRange!.end);
    }
  }

  bool get _canSubmit {
    switch (_selectedPreset) {
      case _ExportPreset.automatic:
        return widget.availability.nextMissingRange != null ||
            (!widget.availability.hasWorkoutData &&
                !widget.availability.hasExportHistory);
      case _ExportPreset.full:
        return true;
      case _ExportPreset.custom:
        return _customRange != null;
    }
  }

  void _submit() {
    if (!_canSubmit) return;
    final availability = widget.availability;
    switch (_selectedPreset) {
      case _ExportPreset.automatic:
        Navigator.pop(context, const ExportRequest.automatic());
        break;
      case _ExportPreset.full:
        Navigator.pop(
          context,
          ExportRequest.full(availability.fullRange),
        );
        break;
      case _ExportPreset.custom:
        final range = _customRange!;
        Navigator.pop(
          context,
          ExportRequest.custom(
            ExportDateRange(range.start, range.end),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final availability = widget.availability;
    final hasAutomatic = availability.nextMissingRange != null ||
        (!availability.hasWorkoutData && !availability.hasExportHistory);

    return AlertDialog(
      backgroundColor: KineticNoirPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Text(
        'Choose export range',
        style: KineticNoirTypography.headline(size: 22, weight: FontWeight.w700),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select what training data to package and share.',
                style: KineticNoirTypography.body(
                  size: 13,
                  color: KineticNoirPalette.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _buildSelectedRangePreview(),
              const SizedBox(height: 12),
              _buildPresetTile(
                preset: _ExportPreset.automatic,
                title: 'Missing dates automatically',
                subtitle: availability.nextMissingRange != null
                    ? '${_formatRange(availability.nextMissingRange)} (${availability.nextMissingRange!.dayCount} ${availability.nextMissingRange!.dayCount == 1 ? 'day' : 'days'})'
                    : 'Up to date • All workout dates backed up',
                enabled: hasAutomatic,
                onTap: hasAutomatic
                    ? () => setState(() => _selectedPreset = _ExportPreset.automatic)
                    : null,
              ),
              const SizedBox(height: 6),
              _buildPresetTile(
                preset: _ExportPreset.full,
                title: 'Full backup (all history)',
                subtitle: availability.hasWorkoutData
                    ? '${_formatRange(availability.fullRange)} • Full DB & spreadsheets'
                    : 'Full app database & routines',
                enabled: true,
                onTap: () => setState(() => _selectedPreset = _ExportPreset.full),
              ),
              const SizedBox(height: 6),
              _buildPresetTile(
                preset: _ExportPreset.custom,
                title: 'Custom date range',
                subtitle: _customRange != null
                    ? '${_formatRange(ExportDateRange(_customRange!.start, _customRange!.end))} (${_customRange!.duration.inDays + 1} days)'
                    : 'Tap to choose start and end dates',
                enabled: true,
                trailingAction: TextButton.icon(
                  onPressed: _pickCustomRange,
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(_customRange == null ? 'Select' : 'Change'),
                  style: TextButton.styleFrom(
                    foregroundColor: KineticNoirPalette.primary,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                onTap: () {
                  setState(() => _selectedPreset = _ExportPreset.custom);
                  if (_customRange == null) {
                    _pickCustomRange();
                  }
                },
              ),
              if (availability.lastExportedDate != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Last export through: ${DateFormat('MMM dd, yyyy').format(availability.lastExportedDate!)}',
                  style: KineticNoirTypography.body(
                    size: 11,
                    weight: FontWeight.w600,
                    color: KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          style: TextButton.styleFrom(
            minimumSize: const Size(72, 48),
          ),
          child: Text(
            'Cancel',
            style: KineticNoirTypography.body(
              size: 14,
              weight: FontWeight.w700,
              color: KineticNoirPalette.onSurfaceVariant,
            ),
          ),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: KineticNoirPalette.primary,
            foregroundColor: KineticNoirPalette.onPrimary,
            minimumSize: const Size(120, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Export & Share',
            style: KineticNoirTypography.body(
              size: 14,
              weight: FontWeight.w800,
              color: KineticNoirPalette.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedRangePreview() {
    final range = _currentEffectiveRange;
    final String modeLabel;
    final String detailText;

    switch (_selectedPreset) {
      case _ExportPreset.automatic:
        modeLabel = 'AUTOMATIC INCREMENTAL';
        detailText = range != null
            ? '${range.dayCount} days inclusive • Missing logs & sessions'
            : 'No missing workout dates to export';
        break;
      case _ExportPreset.full:
        modeLabel = 'FULL BACKUP';
        detailText = range != null
            ? '${range.dayCount} days • Includes full SQLite DB & spreadsheets'
            : 'Complete app database and routine spreadsheets';
        break;
      case _ExportPreset.custom:
        modeLabel = 'CUSTOM RANGE';
        detailText = range != null
            ? '${range.dayCount} days inclusive • Selected logs & spreadsheets'
            : 'Pick dates to enable export';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surfaceBright,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: KineticNoirPalette.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'SELECTED RANGE',
                style: KineticNoirTypography.body(
                  size: 10,
                  weight: FontWeight.w800,
                  color: KineticNoirPalette.primary,
                  letterSpacing: 1.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: KineticNoirPalette.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  modeLabel,
                  style: KineticNoirTypography.body(
                    size: 9,
                    weight: FontWeight.w700,
                    color: KineticNoirPalette.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            range != null ? _formatRange(range) : 'No range selected',
            style: KineticNoirTypography.headline(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detailText,
            style: KineticNoirTypography.body(
              size: 12,
              color: KineticNoirPalette.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile({
    required _ExportPreset preset,
    required String title,
    required String subtitle,
    required bool enabled,
    VoidCallback? onTap,
    Widget? trailingAction,
  }) {
    final isSelected = _selectedPreset == preset;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: !enabled
                      ? KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.3)
                      : (isSelected
                          ? KineticNoirPalette.primary
                          : KineticNoirPalette.onSurfaceVariant),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: KineticNoirTypography.body(
                          size: 13,
                          weight: FontWeight.w700,
                          color: !enabled
                              ? KineticNoirPalette.onSurfaceVariant
                                  .withValues(alpha: 0.4)
                              : KineticNoirPalette.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: KineticNoirTypography.body(
                          size: 11,
                          weight: FontWeight.w500,
                          color: !enabled
                              ? KineticNoirPalette.onSurfaceVariant
                                  .withValues(alpha: 0.3)
                              : KineticNoirPalette.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingAction != null) trailingAction,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your data, within reach',
              style: KineticNoirTypography.headline(size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Keep local backups of routines and training history, or restore an existing backup file.',
              style: KineticNoirTypography.body(
                size: 13,
                color: KineticNoirPalette.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
}

class _DataActionCard extends StatelessWidget {
  const _DataActionCard({
    super.key,
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isBusy ? null : onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: isBusy
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: KineticNoirTypography.headline(size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: KineticNoirTypography.body(
                            size: 13,
                            color: KineticNoirPalette.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: KineticNoirTypography.body(
                                  size: 11,
                                  color: accentColor,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: KineticNoirPalette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _BackupStatusBanner extends StatelessWidget {
  const _BackupStatusBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: KineticNoirPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 20,
            color: KineticNoirPalette.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: KineticNoirTypography.body(
                size: 11,
                weight: FontWeight.w700,
                color: KineticNoirPalette.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

