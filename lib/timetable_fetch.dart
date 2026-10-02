import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'state/utils.dart';

const _yearColumn = {
  '1st Year': 'first',
  '2nd Year': 'second',
  '3rd Year': 'third',
  '4th Year': 'fourth',
};

bool get isSupabaseReady {
  try {
    // Accessing .client throws if initialize() was never called.
    // ignore: unnecessary_statements
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

/// Fetches the year timetable from Supabase and persists it locally.
/// Returns `true` when a payload was saved, `false` when nothing was stored.
Future<bool> fetchTimetable({
  required String collegeName,
  required String department,
  required String year,
  required String selectedSection,
}) async {
  if (!isSupabaseReady) return false;

  try {
    final column = _yearColumn[year] ?? 'first';

    final row = await Supabase.instance.client
        .from('timetables')
        .select()
        .eq('college_name', collegeName)
        .eq('department', department)
        .maybeSingle();

    if (row == null) return false;

    final data = row[column];
    if (data == null) return false;

    final json = data is String ? jsonDecode(data) : data;
    if (json is! Map) return false;

    final prefs = await SharedPreferences.getInstance();
    final payload = Map<String, dynamic>.from(json);
    await prefs.setString('selected_section', selectedSection);

    if (payload.containsKey('sem1') || payload.containsKey('sem2')) {
      // Pick sem1/sem2 by comparing today to each semester's start/end dates.
      final currentSem = resolveActiveSemesterKey(payload);
      payload['current_sem'] = currentSem;
      payload['selected_section'] = selectedSection;
      if (currentSem != null) {
        final active = payload[currentSem];
        if (active is Map) {
          final activeMap = Map<String, dynamic>.from(active);
          payload['current_sem_start_date'] = activeMap['start_date']
              ?.toString();
          payload['current_sem_end_date'] = activeMap['end_date']?.toString();
        }
      }
    }

    await prefs.setString('timetable_payload', jsonEncode(payload));

    final yearStart = payload['year_start_date']?.toString();
    final yearEnd = payload['year_end_date']?.toString();
    if (yearStart != null && yearStart.isNotEmpty) {
      await prefs.setString('year_start_date', yearStart);
    }
    if (yearEnd != null && yearEnd.isNotEmpty) {
      await prefs.setString('year_end_date', yearEnd);
    }
    final currentSemStart = payload['current_sem_start_date']?.toString();
    final currentSemEnd = payload['current_sem_end_date']?.toString();
    if (currentSemStart != null && currentSemStart.isNotEmpty) {
      await prefs.setString('current_sem_start_date', currentSemStart);
    }
    if (currentSemEnd != null && currentSemEnd.isNotEmpty) {
      await prefs.setString('current_sem_end_date', currentSemEnd);
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Extracts section names from a year timetable payload.
/// Supports both nested (`sem1.timetable`) and flat (`timetable`) shapes.
/// Prefers the date-resolved active semester when present.
List<String> extractSectionNames(dynamic payload) {
  if (payload is! Map) return const [];
  final map = Map<String, dynamic>.from(payload);

  Map? timetable;
  final activeKey = resolveActiveSemesterKey(map);
  if (activeKey != null) {
    final active = map[activeKey];
    if (active is Map && active['timetable'] is Map) {
      timetable = active['timetable'] as Map;
    }
  }
  if (timetable == null) {
    final sem1 = map['sem1'];
    if (sem1 is Map && sem1['timetable'] is Map) {
      timetable = sem1['timetable'] as Map;
    }
  }
  if (timetable == null) {
    final sem2 = map['sem2'];
    if (sem2 is Map && sem2['timetable'] is Map) {
      timetable = sem2['timetable'] as Map;
    }
  }
  if (timetable == null && map['timetable'] is Map) {
    timetable = map['timetable'] as Map;
  }

  if (timetable == null || timetable.isEmpty) return const [];
  return timetable.keys.map((key) => key.toString()).toList()..sort();
}

Future<List<String>> fetchSem1SectionNames({
  required String collegeName,
  required String department,
  required String year,
}) async {
  if (!isSupabaseReady) return const [];

  try {
    final column = _yearColumn[year] ?? 'first';
    // print(column);
    final row = await Supabase.instance.client
        .from('timetables')
        .select(column)
        .eq('college_name', collegeName)
        .eq('department', department)
        .maybeSingle();
    // print(row);
    final data = row?[column];
    // print(data);
    if (data == null) return const [];

    final json = data is String ? jsonDecode(data) : data;
    return extractSectionNames(json);
  } catch (_) {
    return const [];
  }
}


