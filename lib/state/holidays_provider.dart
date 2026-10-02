import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'timetable_provider.dart';
import 'utils.dart';

class HolidaysNotifier extends StateNotifier<List<DateTime>> {
  HolidaysNotifier() : super([]);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final holidaysList = prefs.getStringList('holidays') ?? [];
    state = holidaysList
        .map((e) {
          try {
            return dateOnly(DateTime.parse(e));
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .toList();
  }

  void addHoliday(DateTime date) async {
    final holidayDate = dateOnly(date);
    if (!state.any((d) => d.isAtSameMomentAs(holidayDate))) {
      final newState = [...state, holidayDate]..sort();
      state = newState;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'holidays',
        state.map((e) => e.toIso8601String()).toList(),
      );
    }
  }

  void removeHoliday(DateTime date) async {
    final holidayDate = dateOnly(date);
    final newState =
        state.where((d) => !d.isAtSameMomentAs(holidayDate)).toList();
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'holidays',
      state.map((e) => e.toIso8601String()).toList(),
    );
  }

  void clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('holidays');
  }
}

final holidaysProvider =
    StateNotifierProvider<HolidaysNotifier, List<DateTime>>(
      (ref) => HolidaysNotifier(),
    );

/// System holidays from timetable payload:
/// `sem1.holidays` / `sem2.holidays` / root `holidays`
/// as `{ "Independence Day": "20260815", ... }`.
final systemHolidaysProvider = Provider<Map<DateTime, String>>((ref) {
  final rawData = ref.watch(rawDataProvider).valueOrNull;
  return parseHolidayEntries(holidaySourceMaps(rawData));
});

final allHolidaysProvider = Provider<Set<DateTime>>((ref) {
  final userHolidays = ref.watch(holidaysProvider).map(dateOnly);
  final sysHolidays = ref.watch(systemHolidaysProvider).keys;
  return {...userHolidays, ...sysHolidays};
});

/// Exam periods as continuous ranges (for settings / display).
/// ```
/// mid_term_start_date / mid_term_end_date → ExamRange("Mid Term", …)
/// end_term_start_date / end_term_end_date → ExamRange("End Term", …)
/// ```
final examRangesProvider = Provider<List<ExamRange>>((ref) {
  final rawData = ref.watch(rawDataProvider).valueOrNull;
  return parseExamRanges(examSourceMaps(rawData));
});

/// Exam days expanded from [examRangesProvider] for day-level checks
/// (calendar, stats, timetable counting).
final examsProvider = Provider<Map<DateTime, String>>((ref) {
  final ranges = ref.watch(examRangesProvider);
  final out = <DateTime, String>{};
  for (final range in ranges) {
    for (
      var d = range.start;
      !d.isAfter(range.end);
      d = d.add(const Duration(days: 1))
    ) {
      out[dateOnly(d)] = range.label;
    }
  }
  return out;
});
