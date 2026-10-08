typedef StepsTimezoneOffsetResolver = Duration Function(DateTime instantUtc);

class StepsDayRange {
  const StepsDayRange({
    required this.dayKey,
    required this.start,
    required this.end,
  });

  final String dayKey;
  final DateTime start;
  final DateTime end;
}

/// Defines the calendar day used by daily steps without reading the global
/// clock. Production follows the device timezone; tests may inject a fixed or
/// changing UTC offset.
class StepsDayPolicy {
  const StepsDayPolicy({this.offsetForInstant});

  final StepsTimezoneOffsetResolver? offsetForInstant;

  String dayKey(DateTime instant) {
    final local = _localProjection(instant);
    return _format(local.year, local.month, local.day);
  }

  StepsDayRange rangeFor(DateTime instant) {
    final resolver = offsetForInstant;
    if (resolver == null) {
      final local = instant.toLocal();
      final start = DateTime(local.year, local.month, local.day);
      return StepsDayRange(
        dayKey: _format(local.year, local.month, local.day),
        start: start,
        end: DateTime(local.year, local.month, local.day + 1),
      );
    }

    final utc = instant.toUtc();
    final offset = resolver(utc);
    final projected = utc.add(offset);
    final localStart = DateTime.utc(
      projected.year,
      projected.month,
      projected.day,
    );
    return StepsDayRange(
      dayKey: _format(projected.year, projected.month, projected.day),
      start: localStart.subtract(offset),
      end: localStart.add(const Duration(days: 1)).subtract(offset),
    );
  }

  DateTime dateForDayKey(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return DateTime.fromMillisecondsSinceEpoch(0);
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime(year, month, day);
  }

  DateTime _localProjection(DateTime instant) {
    final resolver = offsetForInstant;
    if (resolver == null) return instant.toLocal();
    final utc = instant.toUtc();
    return utc.add(resolver(utc));
  }

  static String _format(int year, int month, int day) {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }
}
