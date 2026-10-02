import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../timetable_fetch.dart';
import 'models.dart';
import 'utils.dart';
import 'settings_provider.dart';
import 'holidays_provider.dart';

import 'package:flutter/foundation.dart';

final rawDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('timetable_payload');
  if (raw == null || raw.isEmpty) return null;
  return await compute((String jsonString) => Map<String, dynamic>.from(jsonDecode(jsonString) as Map), raw);
});

/// Active semester key (`sem1` / `sem2`) from today's date vs start/end.
final activeSemesterKeyProvider = Provider<String?>((ref) {
  final rawData = ref.watch(rawDataProvider).valueOrNull;
  return resolveActiveSemesterKey(rawData);
});

final currentSemesterProvider = Provider<String?>((ref) {
  final rawData = ref.watch(rawDataProvider).valueOrNull;
  final year = ref.watch(settingsProvider.select((s) => s.year));
  if (rawData == null) return null;
  // Always derive from date ranges — never trust a stale current_sem alone.
  final sem = resolveActiveSemesterKey(rawData) ??
      rawData['current_sem']?.toString();

  int baseSem = 0;
  if (year == '2nd Year') {
    baseSem = 2;
  } else if (year == '3rd Year') {
    baseSem = 4;
  } else if (year == '4th Year') {
    baseSem = 6;
  }

  if (sem == 'sem1') return 'Semester ${baseSem + 1}';
  if (sem == 'sem2') return 'Semester ${baseSem + 2}';
  return sem;
});

final _defaultSections = List.generate(
  24,
  (i) => '${String.fromCharCode(65 + i)} Section',
);

final availableSectionsProvider = Provider<List<String>>((ref) {
  final rawData = ref.watch(rawDataProvider).valueOrNull;
  if (rawData == null) return _defaultSections;

  final sections = extractSectionNames(rawData);
  if (sections.isNotEmpty) return sections;
  return _defaultSections;
});

final availableSectionsAsyncProvider = FutureProvider<List<String>>((
  ref,
) async {
  final settings = ref.watch(settingsProvider);
  final sections = await fetchSem1SectionNames(
    collegeName: settings.collegeName,
    department: settings.department,
    year: settings.year,
  );

  if (sections.isNotEmpty) return sections;

  // Fall back to sections already available from local timetable payload.
  final local = ref.read(availableSectionsProvider);
  return local;
});

final currentSectionDataProvider = Provider<Map<String, dynamic>?>((ref) {
  final rawData = ref.watch(rawDataProvider).valueOrNull;
  final section = ref.watch(settingsProvider.select((s) => s.selectedSection));
  return _sectionPayload(rawData, section);
});

final rawTimetableProvider = Provider<Map<String, List<Map<String, String>>>>((
  ref,
) {
  final sectionData = ref.watch(currentSectionDataProvider);
  if (sectionData == null) return {};
  final tt = sectionData['timetable'];
  final result = <String, List<Map<String, String>>>{};
  if (tt is! Map) return result;

  for (final day in ['MON', 'TUE', 'WED', 'THU', 'FRI']) {
    final activities = tt[day];
    if (activities is! List) {
      result[day] = const [];
      continue;
    }
    result[day] = activities.map((e) {
      if (e is! Map) {
        return <String, String>{'time': '', 'activity': ''};
      }
      return <String, String>{
        'time': formatTimetableTimeRange(e['time']),
        'activity': safeString(e['activity']),
      };
    }).toList();
  }
  return result;
});

/// Resolve a section block from a semester's `timetable` map.
/// Shape: `sem1.timetable["A Section"] = { timetable, courses, ... }`
Map<String, dynamic>? sectionPayloadFromTimetableRoot(
  dynamic root,
  String section,
) {
  if (root is! Map || section.trim().isEmpty) return null;
  final sectionKey = section.trim();
  dynamic sectionData = root[sectionKey];
  if (sectionData is! Map) {
    for (final entry in root.entries) {
      if (safeString(entry.key).toLowerCase() == sectionKey.toLowerCase() &&
          entry.value is Map) {
        sectionData = entry.value;
        break;
      }
    }
  }
  if (sectionData is Map) {
    final mapped = safeStringKeyMap(sectionData);
    return mapped.isEmpty ? null : mapped;
  }
  return null;
}

/// Resolve section-level payload (timetable + courses) for a year structure.
/// Prefers the date-resolved active semester, then the other sem, then root.
Map<String, dynamic>? _sectionPayload(
  Map<String, dynamic>? rawData,
  String section, {
  String? preferredSemKey,
}) {
  if (rawData == null || section.trim().isEmpty) return null;
  final sectionKey = section.trim();
  final activeKey =
      preferredSemKey ?? resolveActiveSemesterKey(rawData);

  final candidates = <dynamic>[];
  if (activeKey != null && rawData[activeKey] is Map) {
    candidates.add((rawData[activeKey] as Map)['timetable']);
  }
  // Prefer stored current_sem next (legacy payloads), then both sems.
  final stored = rawData['current_sem']?.toString();
  if (stored != null &&
      stored != activeKey &&
      rawData[stored] is Map) {
    candidates.add((rawData[stored] as Map)['timetable']);
  }
  for (final key in const ['sem1', 'sem2']) {
    if (key == activeKey || key == stored) continue;
    if (rawData[key] is Map) {
      candidates.add((rawData[key] as Map)['timetable']);
    }
  }
  candidates.add(rawData['timetable']);

  Map<String, dynamic>? best;
  for (final root in candidates) {
    final payload = sectionPayloadFromTimetableRoot(root, sectionKey);
    if (payload == null) continue;
    if (payload['courses'] is List && (payload['courses'] as List).isNotEmpty) {
      return payload;
    }
    best ??= payload;
  }

  final deep = _findSectionWithCourses(rawData, sectionKey);
  return deep ?? best;
}

/// Walk nested JSON looking for `section` maps that include `courses`.
Map<String, dynamic>? _findSectionWithCourses(dynamic node, String section) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = safeString(entry.key);
      if (key.toLowerCase() == section.toLowerCase() && entry.value is Map) {
        final mapped = safeStringKeyMap(entry.value);
        if (mapped['courses'] is List &&
            (mapped['courses'] as List).isNotEmpty) {
          return mapped;
        }
      }
    }
    for (final value in node.values) {
      final found = _findSectionWithCourses(value, section);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final item in node) {
      final found = _findSectionWithCourses(item, section);
      if (found != null) return found;
    }
  }
  return null;
}

final scheduleDataProvider = Provider<ScheduleData>((ref) {
  final rawData = ref.watch(rawDataProvider).valueOrNull;
  final settings = ref.watch(settingsProvider);
  final holidays = ref.watch(allHolidaysProvider);
  final examsMap = ref.watch(examsProvider);

  final subjects = <String, Subject>{};
  final schedule = <int, List<ClassSlot>>{};

  if (rawData == null) return ScheduleData(schedule, subjects);

  final section = settings.selectedSection;
  final activeSemKey = resolveActiveSemesterKey(rawData);
  final sectionPayload = _sectionPayload(
    rawData,
    section,
    preferredSemKey: activeSemKey,
  );

  Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map) return safeStringKeyMap(value);
    return null;
  }

  Map<String, dynamic>? sectionTimetableFromRoot(dynamic root) {
    final sectionMap = sectionPayloadFromTimetableRoot(root, section);
    return asMap(sectionMap?['timetable']);
  }

  final sem1 = asMap(rawData['sem1']);
  final sem2 = asMap(rawData['sem2']);

  final sem1Start = tryParseDate(safeString(sem1?['start_date']));
  final sem1End = tryParseDate(safeString(sem1?['end_date']));
  final sem2Start = tryParseDate(safeString(sem2?['start_date']));
  final sem2End = tryParseDate(safeString(sem2?['end_date']));

  // Faculty maps per semester so stats cards show the right instructor.
  final facultyBySem = <String, Map<String, String>>{
    'sem1': facultyBySubjectCode(
      sectionPayloadFromTimetableRoot(sem1?['timetable'], section),
    ),
    'sem2': facultyBySubjectCode(
      sectionPayloadFromTimetableRoot(sem2?['timetable'], section),
    ),
  };
  final fallbackFaculty = facultyBySubjectCode(sectionPayload);

  Map<String, dynamic>? sem1Timetable = sectionTimetableFromRoot(
    sem1?['timetable'],
  );
  Map<String, dynamic>? sem2Timetable = sectionTimetableFromRoot(
    sem2?['timetable'],
  );

  if (sem1Timetable == null && sem2Timetable == null) {
    if (activeSemKey != null && rawData[activeSemKey] is Map) {
      sem1Timetable = sectionTimetableFromRoot(
        (rawData[activeSemKey] as Map)['timetable'],
      );
    }
    sem1Timetable ??= sectionTimetableFromRoot(rawData['timetable']);
    sem1Timetable ??= asMap(sectionPayload?['timetable']);
  }

  final dayMap = {
    DateTime.monday: 'MON',
    DateTime.tuesday: 'TUE',
    DateTime.wednesday: 'WED',
    DateTime.thursday: 'THU',
    DateTime.friday: 'FRI',
  };

  bool dateInRange(DateTime day, DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final d = dateOnly(day);
    return !d.isBefore(dateOnly(start)) && !d.isAfter(dateOnly(end));
  }

  int totalDays = settings.endDate.difference(settings.startDate).inDays + 1;
  if (totalDays <= 0) totalDays = 1;

  for (int i = 1; i <= totalDays; i++) {
    final currentDate = dateFromDayIndex(settings.startDate, i);
    final weekday = currentDate.weekday;
    final isHolidayDay = isHolidayDate(holidays, currentDate);
    final isExamDay = examsMap.containsKey(dateOnly(currentDate));

    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      schedule[i] = [];
      continue;
    }

    final dayStr = dayMap[weekday]!;

    Map<String, dynamic>? currentTimetable;
    Map<String, String> facultyMap = fallbackFaculty;

    if (dateInRange(currentDate, sem1Start, sem1End)) {
      currentTimetable = sem1Timetable;
      facultyMap = facultyBySem['sem1']!.isNotEmpty
          ? facultyBySem['sem1']!
          : fallbackFaculty;
    } else if (dateInRange(currentDate, sem2Start, sem2End)) {
      currentTimetable = sem2Timetable;
      facultyMap = facultyBySem['sem2']!.isNotEmpty
          ? facultyBySem['sem2']!
          : fallbackFaculty;
    } else if (activeSemKey == 'sem2') {
      currentTimetable = sem2Timetable ?? sem1Timetable;
      facultyMap = facultyBySem['sem2']!.isNotEmpty
          ? facultyBySem['sem2']!
          : fallbackFaculty;
    } else {
      currentTimetable = sem1Timetable ?? sem2Timetable;
      facultyMap = facultyBySem['sem1']!.isNotEmpty
          ? facultyBySem['sem1']!
          : fallbackFaculty;
    }

    final activitiesRaw = currentTimetable?[dayStr];
    final activities = activitiesRaw is List ? activitiesRaw : const [];

    final slotsByName = <String, ClassSlot>{};
    for (var activityObj in activities) {
      if (activityObj is! Map) continue;
      final entry = safeStringKeyMap(activityObj);
      final act = safeString(entry['activity']);
      if (act.isEmpty) continue;
      if (act.toLowerCase().contains('break') ||
          act.toLowerCase().contains('lunch')) {
        continue;
      }
      final timeRange = formatTimetableTimeRange(entry['time']);
      final parts = act.split('/');
      for (var p in parts) {
        final cleaned = safeString(p.replaceAll(RegExp(r'\(.*?\)'), ''));
        if (cleaned.isEmpty) continue;
        slotsByName.putIfAbsent(
          cleaned,
          () => ClassSlot(name: cleaned, timeRange: timeRange),
        );
      }
    }

    final daySlots = slotsByName.values.toList();
    schedule[i] = daySlots;

    Subject ensureSubject(String name) {
      final existing = subjects[name];
      if (existing != null) {
        if (existing.faculty.trim().isEmpty) {
          final faculty = lookupFaculty(name, facultyMap);
          if (faculty.isNotEmpty) {
            final updated = existing.copyWith(faculty: faculty);
            subjects[name] = updated;
            return updated;
          }
        }
        return existing;
      }
      final created = Subject(
        name,
        0,
        0,
        heldClasses: 0,
        faculty: lookupFaculty(name, facultyMap),
      );
      subjects[name] = created;
      return created;
    }

    if (!isHolidayDay && !isExamDay) {
      for (final slot in daySlots) {
        final currentSub = ensureSubject(slot.name);
        subjects[slot.name] = currentSub.copyWith(
          totalClasses: currentSub.totalClasses + 1,
        );
      }
    } else {
      for (final slot in daySlots) {
        ensureSubject(slot.name);
      }
    }
  }

  return ScheduleData(schedule, subjects);
});
