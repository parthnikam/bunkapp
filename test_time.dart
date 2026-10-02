import 'dart:core';

class ClockParts {
  final int hour;
  final int minute;
  final bool isPm;
  const ClockParts(this.hour, this.minute, this.isPm);
}

ClockParts? parseTimetableClock(dynamic raw) {
  final text = raw.toString();
  if (text.isEmpty) return null;
  final normalized = text.replaceAll('.', ':');
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(normalized);
  if (match == null) return null;

  var hour = int.tryParse(match.group(1)!) ?? 0;
  final minute = int.tryParse(match.group(2)!) ?? 0;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  final isPm = hour == 12 || (hour >= 1 && hour <= 7);
  if (hour == 0) hour = 12;
  if (hour > 12) {
    return ClockParts(hour - 12, minute, true);
  }
  return ClockParts(hour, minute, isPm);
}

String formatClockShort(ClockParts clock) {
  if (clock.minute == 0) return '${clock.hour}';
  return '${clock.hour}:${clock.minute.toString().padLeft(2, '0')}';
}

String formatTimetableTimeRange(dynamic raw) {
  final cleaned = raw.toString();
  if (cleaned.isEmpty) return '';
  final parts = cleaned.split(RegExp(r'\s*-\s*'));
  if (parts.length != 2) return cleaned;

  final start = parseTimetableClock(parts[0]);
  final end = parseTimetableClock(parts[1]);
  if (start == null || end == null) return cleaned;

  final period = end.isPm ? 'pm' : 'am';
  return '${formatClockShort(start)} - ${formatClockShort(end)} $period';
}

void main() {
  print(formatTimetableTimeRange("09.00-09.50"));
  print(formatTimetableTimeRange("12.30-01.00"));
  print(formatTimetableTimeRange("02.00-04.00"));
  print(formatTimetableTimeRange("09.50-10.40"));
  print(formatTimetableTimeRange("10.40-10.50"));
  print(formatTimetableTimeRange("01.00-01.50"));
  print(formatTimetableTimeRange("01.50-02.40"));
}
