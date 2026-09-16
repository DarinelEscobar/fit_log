enum ExportRangeMode { automatic, custom }

class ExportDateRange {
  ExportDateRange(DateTime startDate, DateTime endDate)
      : startDate = _dateOnly(startDate),
        endDate = _dateOnly(endDate) {
    if (this.startDate.isAfter(this.endDate)) {
      throw ArgumentError(
          'The export start date must not be after the end date.');
    }
  }

  final DateTime startDate;
  final DateTime endDate;

  bool contains(DateTime date) {
    final normalized = _dateOnly(date);
    return !normalized.isBefore(startDate) && !normalized.isAfter(endDate);
  }

  String get startIso => _formatDate(startDate);
  String get endIso => _formatDate(endDate);

  Map<String, String> toJson() => {
        'startDate': startIso,
        'endDate': endIso,
      };

  static ExportDateRange? tryParse(Object? value) {
    if (value is! Map) return null;
    final start = DateTime.tryParse(value['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(value['endDate']?.toString() ?? '');
    if (start == null || end == null) return null;
    try {
      return ExportDateRange(start, end);
    } on ArgumentError {
      return null;
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${pad(date.month)}-${pad(date.day)}';
  }
}

class ExportRequest {
  const ExportRequest.automatic()
      : mode = ExportRangeMode.automatic,
        range = null;

  const ExportRequest.custom(this.range) : mode = ExportRangeMode.custom;

  final ExportRangeMode mode;
  final ExportDateRange? range;
}

class ExportAvailability {
  const ExportAvailability({
    required this.firstDate,
    required this.lastDate,
    required this.nextMissingRange,
    required this.lastExportedDate,
    required this.hasExportHistory,
  });

  final DateTime? firstDate;
  final DateTime? lastDate;
  final ExportDateRange? nextMissingRange;
  final DateTime? lastExportedDate;
  final bool hasExportHistory;

  bool get hasWorkoutData => firstDate != null && lastDate != null;
}
