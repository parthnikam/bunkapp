// ---------------------------------------------------------
// Utilities
// ---------------------------------------------------------

String safeString(Object? v, [String f = '']) =>
    (v?.toString().trim() == 'null' || v?.toString().trim().isEmpty == true)
    ? f
    : (v?.toString().trim() ?? f);

int safeInt(Object? v, [int f = 0]) => v is num
    ? (v.isNaN || v.isInfinite ? f : v.round())
    : (int.tryParse(v?.toString().trim() ?? '') ?? f);

int clampInt(int v, int min, int max) => v < min ? min : (v > max ? max : v);

Map<String, dynamic> safeStringKeyMap(dynamic v) => v is Map
    ? (v.map<String, dynamic>((k, val) => MapEntry(k?.toString() ?? '', val))
        ..remove(''))
    : <String, dynamic>{};

// --- Date Utilities ---

/// Calendar date only (local midnight) — avoids timezone/time-of-day drift.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Real-world "today" as a local calendar date.
DateTime calendarToday([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Map a calendar date to a 1-based day index from the semester start.
int computeTodayDayIndex(
  DateTime startDate,
  DateTime endDate, [
  DateTime? now,
]) {
  final start = dateOnly(startDate);
  final today = calendarToday(now);
  final rawIndex = today.difference(start).inDays + 1;
  // Before the semester starts, pin to day 1.
  if (rawIndex < 1) return 1;
  return rawIndex;
}

/// Convert a 1-based semester day index back to a calendar date.
DateTime dateFromDayIndex(DateTime startDate, int dayIndex) {
  return dateOnly(startDate).add(Duration(days: dayIndex - 1));
}

/// Check if a date is a holiday using O(1) set lookup
bool isHolidayDate(Set<DateTime> holidays, DateTime date) {
  return holidays.contains(DateTime(date.year, date.month, date.day));
}

/// Consolidated date parser
DateTime? tryParseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = value.trim();

  // YYYYMMDD
  if (RegExp(r'^\d{8}$').hasMatch(normalized)) {
    final year = int.tryParse(normalized.substring(0, 4));
    final month = int.tryParse(normalized.substring(4, 6));
    final day = int.tryParse(normalized.substring(6, 8));
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }

  // ISO / DateTime.parse
  final direct = DateTime.tryParse(normalized);
  if (direct != null) {
    final local = direct.isUtc ? direct.toLocal() : direct;
    return DateTime(local.year, local.month, local.day);
  }

  final parts = normalized.split(RegExp(r'[\s,/.\-]+'));
  if (parts.length == 3) {
    // "05 Jan 2026"
    final dayFirst = int.tryParse(parts[0]);
    final yearLast = int.tryParse(parts[2]);
    if (dayFirst != null && yearLast != null) {
      final month = monthFromName(parts[1]);
      if (month != null) return DateTime(yearLast, month, dayFirst);
    }

    // "Jan 05 2026"
    final yearFirst = int.tryParse(parts[0]);
    final dayLast = int.tryParse(parts[2]);
    if (yearFirst != null && yearFirst > 31 && dayLast != null) {
      final month = monthFromName(parts[1]);
      if (month != null) return DateTime(yearFirst, month, dayLast);
    }
  }

  return null;
}

int? monthFromName(String name) {
  const months = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };
  return months[name.toLowerCase()];
}

// --- Time Formatting Utilities ---

class ClockParts {
  final int hour;
  final int minute;
  final bool isPm;
  const ClockParts(this.hour, this.minute, this.isPm);
}

ClockParts? parseTimetableClock(dynamic raw) {
  final text = safeString(raw);
  if (text.isEmpty) return null;
  final normalized = text.replaceAll('.', ':');
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(normalized);
  if (match == null) return null;

  var hour = int.tryParse(safeString(match.group(1))) ?? 0;
  final minute = int.tryParse(safeString(match.group(2))) ?? 0;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  final isPm = hour == 12 || (hour >= 1 && hour <= 7);
  if (hour == 0) hour = 12;
  if (hour > 12) {
    return ClockParts(hour - 12, minute, true);
  }
  return ClockParts(hour, minute, isPm);
}

String formatClockShort(ClockParts clock) {
  return '${clock.hour}:${clock.minute.toString().padLeft(2, '0')}';
}

String formatTimetableTimeRange(dynamic raw) {
  final cleaned = safeString(raw);
  if (cleaned.isEmpty) return '';
  final parts = cleaned.split(RegExp(r'\s*-\s*'));
  if (parts.length != 2) return cleaned;

  final start = parseTimetableClock(parts[0]);
  final end = parseTimetableClock(parts[1]);
  if (start == null || end == null) return cleaned;

  final startPeriod = start.isPm ? 'PM' : 'AM';
  final endPeriod = end.isPm ? 'PM' : 'AM';

  if (startPeriod == endPeriod) {
    return '${formatClockShort(start)} - ${formatClockShort(end)} $endPeriod';
  } else {
    return '${formatClockShort(start)} $startPeriod - ${formatClockShort(end)} $endPeriod';
  }
}

// --- Active semester / holidays / exams from timetable payload ---

/// Pick `sem1` or `sem2` from [rawData] using today's date against each
/// semester's `start_date` / `end_date` (inclusive). Never blindly defaults
/// to sem1 when a date-based match exists.
String? resolveActiveSemesterKey(
  Map<String, dynamic>? rawData, [
  DateTime? now,
]) {
  if (rawData == null) return null;
  final today = dateOnly(now ?? DateTime.now());

  DateTime? startOf(String key) {
    final sem = rawData[key];
    if (sem is! Map) return null;
    return tryParseDate(safeString(sem['start_date']));
  }

  DateTime? endOf(String key) {
    final sem = rawData[key];
    if (sem is! Map) return null;
    return tryParseDate(safeString(sem['end_date']));
  }

  final s1 = startOf('sem1');
  final e1 = endOf('sem1');
  final s2 = startOf('sem2');
  final e2 = endOf('sem2');

  bool inRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return !today.isBefore(start) && !today.isAfter(end);
  }

  // 1) Currently inside a semester window.
  if (inRange(s1, e1)) return 'sem1';
  if (inRange(s2, e2)) return 'sem2';

  // 2) Before a semester starts → next upcoming.
  final upcoming = <(DateTime, String)>[];
  if (s1 != null && today.isBefore(s1)) upcoming.add((s1, 'sem1'));
  if (s2 != null && today.isBefore(s2)) upcoming.add((s2, 'sem2'));
  if (upcoming.isNotEmpty) {
    upcoming.sort((a, b) => a.$1.compareTo(b.$1));
    return upcoming.first.$2;
  }

  // 3) After both → most recently ended.
  final past = <(DateTime, String)>[];
  if (e1 != null && today.isAfter(e1)) past.add((e1, 'sem1'));
  if (e2 != null && today.isAfter(e2)) past.add((e2, 'sem2'));
  if (past.isNotEmpty) {
    past.sort((a, b) => b.$1.compareTo(a.$1));
    return past.first.$2;
  }

  // 4) Fallbacks when dates are missing.
  final stored = safeString(rawData['current_sem']);
  if (stored == 'sem1' || stored == 'sem2') return stored;
  if (rawData['sem1'] is Map) return 'sem1';
  if (rawData['sem2'] is Map) return 'sem2';
  return null;
}

/// Semester map for [semKey] (`sem1` / `sem2`), or null.
Map<String, dynamic>? semesterMap(
  Map<String, dynamic>? rawData,
  String? semKey,
) {
  if (rawData == null || semKey == null) return null;
  final sem = rawData[semKey];
  if (sem is! Map) return null;
  return safeStringKeyMap(sem);
}

/// Collect holiday name → date maps from root + each semester block.
/// Schema (per data_backup.json):
/// `sem1.holidays = { "Independence Day": "20260815", ... }`
Iterable<Map> holidaySourceMaps(Map<String, dynamic>? rawData) sync* {
  if (rawData == null) return;
  if (rawData['holidays'] is Map) yield rawData['holidays'] as Map;
  for (final key in const ['sem1', 'sem2']) {
    final sem = rawData[key];
    if (sem is Map && sem['holidays'] is Map) {
      yield sem['holidays'] as Map;
    }
  }
}

/// Parse holiday maps into `date → display name`.
Map<DateTime, String> parseHolidayEntries(Iterable<Map> sources) {
  final out = <DateTime, String>{};
  for (final source in sources) {
    source.forEach((key, value) {
      final name = safeString(key);
      final date = tryParseDate(safeString(value));
      if (name.isEmpty || date == null) return;
      out[dateOnly(date)] = name;
    });
  }
  return out;
}

/// Collect exam maps from root + each semester.
/// Schema: `sem1.exams = { mid_term_start_date, mid_term_end_date, ... }`
Iterable<Map> examSourceMaps(Map<String, dynamic>? rawData) sync* {
  if (rawData == null) return;
  if (rawData['exams'] is Map) yield rawData['exams'] as Map;
  for (final key in const ['sem1', 'sem2']) {
    final sem = rawData[key];
    if (sem is Map && sem['exams'] is Map) {
      yield sem['exams'] as Map;
    }
  }
}

/// A continuous exam period (e.g. Mid Term 24 Sep – 1 Oct).
class ExamRange {
  final String label;
  final DateTime start;
  final DateTime end;

  const ExamRange({
    required this.label,
    required this.start,
    required this.end,
  });

  bool get isSingleDay => start.isAtSameMomentAs(end);

  bool contains(DateTime date) {
    final d = dateOnly(date);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

/// Humanize exam keys: `mid_term` → `Mid Term`, `end_term` → `End Term`.
String humanizeExamLabel(String rawKey) {
  var key = safeString(rawKey);
  if (key.isEmpty) return 'Exam';
  key = key.replaceAll(
    RegExp(r'(_start_date|_end_date|_start|_end|_date)$', caseSensitive: false),
    '',
  );
  key = key.replaceAll(RegExp(r'_+'), ' ').trim();
  if (key.isEmpty) return 'Exam';
  return key
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

/// Parse exam payload into continuous ranges (not discrete days).
/// Schema: `{ mid_term_start_date, mid_term_end_date, ... }` or legacy
/// single-day `{ "Mid Term": "20260924" }`.
List<ExamRange> parseExamRanges(Iterable<Map> sources) {
  final ranges = <ExamRange>[];

  for (final source in sources) {
    final starts = <String, DateTime>{};
    final ends = <String, DateTime>{};
    final singles = <DateTime, String>{};

    source.forEach((rawKey, rawValue) {
      final key = safeString(rawKey);
      final date = tryParseDate(safeString(rawValue));
      if (key.isEmpty || date == null) return;
      final day = dateOnly(date);
      final lower = key.toLowerCase();

      if (lower.endsWith('_start_date') || lower.endsWith('_start')) {
        final prefix = key.replaceAll(
          RegExp(r'(_start_date|_start)$', caseSensitive: false),
          '',
        );
        starts[prefix.toLowerCase()] = day;
      } else if (lower.endsWith('_end_date') || lower.endsWith('_end')) {
        final prefix = key.replaceAll(
          RegExp(r'(_end_date|_end)$', caseSensitive: false),
          '',
        );
        ends[prefix.toLowerCase()] = day;
      } else {
        // Legacy / single-day: { "Mid Term": "20260924" }
        singles[day] = humanizeExamLabel(key);
      }
    });

    final prefixes = {...starts.keys, ...ends.keys}.toList()..sort();
    for (final prefix in prefixes) {
      final start = starts[prefix] ?? ends[prefix];
      final end = ends[prefix] ?? starts[prefix];
      if (start == null || end == null) continue;
      final from = start.isBefore(end) ? start : end;
      final to = start.isBefore(end) ? end : start;
      ranges.add(
        ExamRange(label: humanizeExamLabel(prefix), start: from, end: to),
      );
    }

    final singleDays = singles.keys.toList()..sort();
    for (final day in singleDays) {
      ranges.add(ExamRange(label: singles[day]!, start: day, end: day));
    }
  }

  ranges.sort((a, b) => a.start.compareTo(b.start));
  return ranges;
}

/// Expand exam ranges into every calendar day covered (for day-level checks).
Map<DateTime, String> parseExamEntries(Iterable<Map> sources) {
  final out = <DateTime, String>{};
  for (final range in parseExamRanges(sources)) {
    for (
      var d = range.start;
      !d.isAfter(range.end);
      d = d.add(const Duration(days: 1))
    ) {
      out[dateOnly(d)] = range.label;
    }
  }
  return out;
}

// --- Faculty Lookup Utilities ---

Map<String, String> facultyBySubjectCode(Map<String, dynamic>? sectionData) {
  final map = <String, String>{};
  if (sectionData == null) return map;

  dynamic courses =
      sectionData['courses'] ??
      sectionData['Courses'] ??
      sectionData['course_list'];
  if (courses is! List) return map;

  void put(String? code, String faculty) {
    final key = normalizeSubjectKey(code);
    if (key.isEmpty || faculty.isEmpty) return;
    map[key] = faculty;
    map[key.replaceAll(' ', '')] = faculty;
    // Also index last token: "CAEG Lab" → "CAEG" already covered; "DV LAB" helpers
    final tokens = key.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.length > 1) {
      final first = tokens.first;
      // Prefer longer/more specific keys; only fill if empty.
      map.putIfAbsent(first, () => faculty);
      map.putIfAbsent(first.replaceAll(' ', ''), () => faculty);
    }
  }

  for (final course in courses) {
    if (course is! Map) continue;
    final courseMap = safeStringKeyMap(course);

    final faculty = formatFacultyName(
      courseMap['faculty'] ??
          courseMap['Faculty'] ??
          courseMap['faculty_name'] ??
          courseMap['instructor'] ??
          courseMap['teacher'],
    );
    if (faculty.isEmpty) continue;

    final courseName = safeString(
      courseMap['course_name'] ??
          courseMap['Course_Name'] ??
          courseMap['name'] ??
          courseMap['subject'],
    );
    final courseCode = safeString(
      courseMap['course_code'] ?? courseMap['Course_Code'] ?? courseMap['code'],
    );

    // Abbreviations in parentheses: "Fundamentals of Electrical Engineering (FEE)"
    final parenCodes = <String>[];
    for (final match in RegExp(r'\(([^)]+)\)').allMatches(courseName)) {
      final code = safeString(match.group(1));
      if (code.isNotEmpty) parenCodes.add(code);
    }

    for (final code in parenCodes) {
      put(code, faculty);
    }

    // Full course name without trailing code paren (secondary key).
    if (courseName.isNotEmpty) {
      final stripped = safeString(
        courseName.replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' '),
      );
      if (stripped.isNotEmpty) put(stripped, faculty);
      if (parenCodes.isEmpty) put(courseName, faculty);
    }

    // Official course code e.g. "MAT 1203" / "CSS 1002"
    if (courseCode.isNotEmpty) {
      put(courseCode, faculty);
      put(courseCode.replaceAll(' ', ''), faculty);
    }
  }
  return map;
}

String formatFacultyName(dynamic raw) {
  var value = safeString(raw);
  if (value.isEmpty) return '';

  if (value.contains('/')) {
    value = value
        .split('/')
        .map((part) => safeString(part))
        .where((part) => part.isNotEmpty)
        .join(' / ');
  } else if (value.contains('+')) {
    value = value
        .split('+')
        .map((part) => safeString(part))
        .where((part) => part.isNotEmpty)
        .join(' + ');
  }

  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String normalizeSubjectKey(dynamic value) {
  final text = safeString(value).toUpperCase();
  if (text.isEmpty) return '';
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String lookupFaculty(String subject, Map<String, String> facultyMap) {
  if (facultyMap.isEmpty) return '';
  final key = normalizeSubjectKey(subject);
  if (key.isEmpty) return '';
  final compact = key.replaceAll(' ', '');

  if (facultyMap[key] != null) return facultyMap[key]!;
  if (facultyMap[compact] != null) return facultyMap[compact]!;

  // "DV LAB", "OOPS Lab", "CAEG Lab" → strip trailing Lab token.
  final withoutLab = key
      .replaceAll(RegExp(r'\s+LAB$', caseSensitive: false), '')
      .trim();
  if (withoutLab.isNotEmpty && withoutLab != key) {
    if (facultyMap[withoutLab] != null) return facultyMap[withoutLab]!;
    final compactNoLab = withoutLab.replaceAll(' ', '');
    if (facultyMap[compactNoLab] != null) return facultyMap[compactNoLab]!;
  }

  // First token only: "DV LAB" → "DV", "CAEG Lab" → "CAEG".
  final firstToken = key
      .split(' ')
      .firstWhere((t) => t.isNotEmpty, orElse: () => '');
  if (firstToken.isNotEmpty && firstToken != key) {
    if (facultyMap[firstToken] != null) return facultyMap[firstToken]!;
  }

  String? best;
  var bestLen = 0;
  for (final entry in facultyMap.entries) {
    final code = entry.key;
    if (code.isEmpty) continue;
    final matches =
        key == code ||
        key.startsWith('$code ') ||
        code.startsWith('$key ') ||
        (key.startsWith(code) && code.length >= 2) ||
        (code.startsWith(key) && key.length >= 2);
    if (matches && code.length > bestLen) {
      best = entry.value;
      bestLen = code.length;
    }
  }
  return best ?? '';
}
