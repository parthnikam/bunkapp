import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../timetable_fetch.dart';
import 'utils.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';
import 'bunked_provider.dart';
import 'holidays_provider.dart';
import 'timetable_provider.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  await ref.read(rawDataProvider.future);
  await ref.read(settingsProvider.notifier).initialize();
  final settings = ref.read(settingsProvider);

  await ref.read(bunkedProvider.notifier).initialize(settings.startDate);
  await ref.read(holidaysProvider.notifier).initialize();
  await ref.read(uiProvider.notifier).initialize();

  final prefs = await SharedPreferences.getInstance();
  final lastFetch = prefs.getInt('last_fetch_time') ?? 0;
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final twoDaysMs = 2 * 24 * 60 * 60 * 1000;

  if (!settings.isFirstLaunch && (nowMs - lastFetch > twoDaysMs)) {
    await fetchTimetable(
      collegeName: settings.collegeName,
      department: settings.department,
      year: settings.year,
      selectedSection: settings.selectedSection,
    );
    ref.invalidate(rawDataProvider);
  }

  final rawData = await ref.read(rawDataProvider.future);

  // Always pick sem1/sem2 from today's date vs semester start/end dates.
  final activeSemKey = resolveActiveSemesterKey(rawData);
  final activeSemMap = semesterMap(rawData, activeSemKey);

  final startDateStr =
      activeSemMap?['start_date']?.toString() ??
      rawData?['current_sem_start_date']?.toString() ??
      rawData?['start_date']?.toString() ??
      rawData?['year_start_date']?.toString();
  final endDateStr =
      activeSemMap?['end_date']?.toString() ??
      rawData?['current_sem_end_date']?.toString() ??
      rawData?['end_date']?.toString() ??
      rawData?['year_end_date']?.toString();

  final parsedStart = tryParseDate(startDateStr);
  final parsedEnd = tryParseDate(endDateStr);

  if (parsedStart != null) {
    await ref.read(settingsProvider.notifier).setStartDate(parsedStart);
    ref.read(bunkedProvider.notifier).updateStartDate(parsedStart);
  }
  if (parsedEnd != null) {
    await ref.read(settingsProvider.notifier).setEndDate(parsedEnd);
  }

  // Keep persisted payload markers in sync with the live date resolution.
  if (activeSemKey != null && rawData != null) {
    final updated = Map<String, dynamic>.from(rawData);
    updated['current_sem'] = activeSemKey;
    if (parsedStart != null) {
      final ymd =
          '${parsedStart.year}${parsedStart.month.toString().padLeft(2, '0')}${parsedStart.day.toString().padLeft(2, '0')}';
      updated['current_sem_start_date'] = ymd;
      await prefs.setString('current_sem_start_date', ymd);
    }
    if (parsedEnd != null) {
      final ymd =
          '${parsedEnd.year}${parsedEnd.month.toString().padLeft(2, '0')}${parsedEnd.day.toString().padLeft(2, '0')}';
      updated['current_sem_end_date'] = ymd;
      await prefs.setString('current_sem_end_date', ymd);
    }
    await prefs.setString('timetable_payload', jsonEncode(updated));
    // Refresh in-memory payload so consumers see the updated current_sem.
    ref.invalidate(rawDataProvider);
    await ref.read(rawDataProvider.future);
  }

  final updatedSettings = ref.read(settingsProvider);
  ref
      .read(uiProvider.notifier)
      .syncTodayDay(
        startDate: updatedSettings.startDate,
        endDate: updatedSettings.endDate,
      );
});
