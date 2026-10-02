import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'utils.dart';
import 'settings_provider.dart';
import 'holidays_provider.dart';
import 'timetable_provider.dart';
import 'stats_provider.dart';
import 'bunked_provider.dart';

/// A single day within a long weekend time span.
class LongWeekendDay {
  final DateTime date;
  final bool isWeekend;
  final bool isHoliday;
  final bool isBunkDay;
  final String? holidayName;

  const LongWeekendDay({
    required this.date,
    required this.isWeekend,
    required this.isHoliday,
    required this.isBunkDay,
    this.holidayName,
  });
}

/// Represents a detected long weekend span around a weekend.
class LongWeekend {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<LongWeekendDay> days;
  final List<DateTime> holidayDates;
  final List<DateTime> bunkDates;
  final List<String> holidayNames;

  const LongWeekend({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.holidayDates,
    required this.bunkDates,
    required this.holidayNames,
  });

  int get totalDays => days.length;
  int get bunkDaysCount => bunkDates.length;
  bool get hasSkippedClasses => bunkDates.isNotEmpty;

  String get formattedDateRange {
    final startFmt = DateFormat('MMM d').format(startDate);
    final endFmt = DateFormat('MMM d, yyyy').format(endDate);
    return '$startFmt - $endFmt';
  }

  String get formattedShortDateRange {
    final startFmt = DateFormat('MMM d').format(startDate);
    final endFmt = DateFormat('MMM d').format(endDate);
    return '$startFmt - $endFmt';
  }
}

/// Impact on an individual class/subject if skipped during a long weekend.
class SkippedClassImpact {
  final String subjectName;
  final String timeRange;
  final String faculty;
  final double currentPercentage;
  final double projectedPercentage;
  final double percentageDrop;
  final int totalClasses;
  final int currentSkipped;
  final int newSkipped;
  final bool isAlreadyBunked;

  const SkippedClassImpact({
    required this.subjectName,
    required this.timeRange,
    required this.faculty,
    required this.currentPercentage,
    required this.projectedPercentage,
    required this.percentageDrop,
    required this.totalClasses,
    required this.currentSkipped,
    required this.newSkipped,
    required this.isAlreadyBunked,
  });
}

/// Detailed breakdown of a single date where classes are skipped.
class LongWeekendBunkDayDetail {
  final DateTime date;
  final int dayIndex;
  final String dayLabel;
  final List<SkippedClassImpact> classes;
  final bool isWholeDayBunked;

  const LongWeekendBunkDayDetail({
    required this.date,
    required this.dayIndex,
    required this.dayLabel,
    required this.classes,
    required this.isWholeDayBunked,
  });

  int get totalClassesToSkip => classes.length;
}

/// Aggregated attendance impact for an entire long weekend.
class LongWeekendImpact {
  final LongWeekend longWeekend;
  final List<LongWeekendBunkDayDetail> bunkDays;
  final int totalClassesSkipped;
  final double currentOverallAttendance;
  final double projectedOverallAttendance;
  final double overallPercentageDrop;
  final bool isSafe;
  final double desiredPercentage;

  const LongWeekendImpact({
    required this.longWeekend,
    required this.bunkDays,
    required this.totalClassesSkipped,
    required this.currentOverallAttendance,
    required this.projectedOverallAttendance,
    required this.overallPercentageDrop,
    required this.isSafe,
    required this.desiredPercentage,
  });
}

/// Core modular algorithm: scans dates and identifies all long weekends.
List<LongWeekend> calculateLongWeekends({
  required Set<DateTime> holidays,
  required Map<DateTime, String> systemHolidays,
  Map<DateTime, String> exams = const {},
  required DateTime startDate,
  required DateTime endDate,
}) {
  final normalizedHolidays = holidays.map(dateOnly).toSet();
  final normalizedExams = exams.keys.map(dateOnly).toSet();
  final start = dateOnly(startDate);
  final end = dateOnly(endDate);

  // Scan every day in a window covering the semester.
  // We align on Saturdays (weekday == 6).
  final scanStart = start.subtract(const Duration(days: 7));
  final scanEnd = end.add(const Duration(days: 7));

  final longWeekends = <LongWeekend>[];
  final processedSaturdays = <DateTime>{};

  for (
    var current = scanStart;
    !current.isAfter(scanEnd);
    current = current.add(const Duration(days: 1))
  ) {
    if (current.weekday != DateTime.saturday) continue;
    final sat = dateOnly(current);
    if (processedSaturdays.contains(sat)) continue;
    processedSaturdays.add(sat);

    final sun = sat.add(const Duration(days: 1));

    // --- Check pre-weekend (Friday, Thursday, ...) ---
    final fri = sat.subtract(const Duration(days: 1));
    final thu = sat.subtract(const Duration(days: 2));

    final preHolidays = <DateTime>[];
    final preBunkDays = <DateTime>[];

    final isFriExam = normalizedExams.contains(fri);
    final isFriHol = normalizedHolidays.contains(fri) && !isFriExam;
    final isThuExam = normalizedExams.contains(thu);
    final isThuHol = normalizedHolidays.contains(thu) && !isThuExam;

    if (isFriHol) {
      preHolidays.add(fri);
      var prev = thu;
      while (normalizedHolidays.contains(prev) && !normalizedExams.contains(prev)) {
        preHolidays.add(prev);
        prev = prev.subtract(const Duration(days: 1));
      }
    } else if (isThuHol && !isFriExam) {
      // Friday is a working day, but can be skipped only if Friday is NOT an exam day
      preBunkDays.add(fri);
      preHolidays.add(thu);
      var prev = thu.subtract(const Duration(days: 1));
      while (normalizedHolidays.contains(prev) && !normalizedExams.contains(prev)) {
        preHolidays.add(prev);
        prev = prev.subtract(const Duration(days: 1));
      }
    }

    // --- Check post-weekend (Monday, Tuesday, ...) ---
    final mon = sun.add(const Duration(days: 1));
    final tue = sun.add(const Duration(days: 2));

    final postHolidays = <DateTime>[];
    final postBunkDays = <DateTime>[];

    final isMonExam = normalizedExams.contains(mon);
    final isMonHol = normalizedHolidays.contains(mon) && !isMonExam;
    final isTueExam = normalizedExams.contains(tue);
    final isTueHol = normalizedHolidays.contains(tue) && !isTueExam;

    if (isMonHol) {
      postHolidays.add(mon);
      var next = tue;
      while (normalizedHolidays.contains(next) && !normalizedExams.contains(next)) {
        postHolidays.add(next);
        next = next.add(const Duration(days: 1));
      }
    } else if (isTueHol && !isMonExam) {
      // Monday is a working day, but can be skipped only if Monday is NOT an exam day
      postBunkDays.add(mon);
      postHolidays.add(tue);
      var next = tue.add(const Duration(days: 1));
      while (normalizedHolidays.contains(next) && !normalizedExams.contains(next)) {
        postHolidays.add(next);
        next = next.add(const Duration(days: 1));
      }
    }

    // If there is any holiday connected before or after the weekend, it forms a long weekend.
    if (preHolidays.isEmpty && postHolidays.isEmpty) {
      continue;
    }

    // Determine the full continuous date span
    final allDates = <DateTime>[
      ...preHolidays,
      ...preBunkDays,
      sat,
      sun,
      ...postBunkDays,
      ...postHolidays,
    ]..sort();

    final lwStart = allDates.first;
    final lwEnd = allDates.last;

    // Filter out spans that do not overlap with the semester at all
    if (lwEnd.isBefore(start) || lwStart.isAfter(end)) {
      continue;
    }

    final holidayDates = [...preHolidays, ...postHolidays]..sort();
    final bunkDates = [...preBunkDays, ...postBunkDays]..sort();

    final holidayNames = <String>[];
    for (final hDate in holidayDates) {
      final name = systemHolidays[dateOnly(hDate)];
      if (name != null && name.trim().isNotEmpty) {
        if (!holidayNames.contains(name.trim())) {
          holidayNames.add(name.trim());
        }
      }
    }

    final days = <LongWeekendDay>[];
    for (
      var d = lwStart;
      !d.isAfter(lwEnd);
      d = d.add(const Duration(days: 1))
    ) {
      final norm = dateOnly(d);
      final isWk = norm.weekday == DateTime.saturday || norm.weekday == DateTime.sunday;
      final isHol = normalizedHolidays.contains(norm);
      final isBunk = bunkDates.contains(norm);
      final holName = systemHolidays[norm];

      days.add(
        LongWeekendDay(
          date: norm,
          isWeekend: isWk,
          isHoliday: isHol,
          isBunkDay: isBunk,
          holidayName: holName,
        ),
      );
    }

    String title;
    if (holidayNames.isNotEmpty) {
      title = '${holidayNames.join(" & ")} Weekend';
    } else {
      final startStr = DateFormat('MMM d').format(lwStart);
      final endStr = DateFormat('MMM d').format(lwEnd);
      title = 'Long Weekend ($startStr - $endStr)';
    }

    longWeekends.add(
      LongWeekend(
        title: title,
        startDate: lwStart,
        endDate: lwEnd,
        days: days,
        holidayDates: holidayDates,
        bunkDates: bunkDates,
        holidayNames: holidayNames,
      ),
    );
  }

  longWeekends.sort((a, b) => a.startDate.compareTo(b.startDate));
  return longWeekends;
}

/// Filters long weekends for a specific month.
List<LongWeekend> calculateLongWeekendsForMonth({
  required DateTime month,
  required Set<DateTime> holidays,
  required Map<DateTime, String> systemHolidays,
  Map<DateTime, String> exams = const {},
  required DateTime startDate,
  required DateTime endDate,
}) {
  final all = calculateLongWeekends(
    holidays: holidays,
    systemHolidays: systemHolidays,
    exams: exams,
    startDate: startDate,
    endDate: endDate,
  );

  return all.where((lw) {
    // A long weekend is shown for the month if any date in its span is in this month
    for (final day in lw.days) {
      if (day.date.year == month.year && day.date.month == month.month) {
        return true;
      }
    }
    return false;
  }).toList();
}

/// Calculates the exact attendance impact for a given long weekend.
LongWeekendImpact calculateLongWeekendImpact({
  required LongWeekend longWeekend,
  required ScheduleData scheduleData,
  required Map<String, Subject> computedSubjects,
  required AttendanceStats overallStats,
  required Map<int, Set<String>> bunkedClasses,
  required DateTime semesterStartDate,
  required double desiredPercentage,
  required bool showCurrentAttendance,
}) {
  final bunkDayDetails = <LongWeekendBunkDayDetail>[];
  var newClassesToSkipCount = 0;

  // Track additional simulated skips per subject across all bunk days of this long weekend
  final addedSkipsPerSubject = <String, int>{};

  for (final bunkDate in longWeekend.bunkDates) {
    final dayIndex = bunkDate.difference(dateOnly(semesterStartDate)).inDays + 1;
    final slots = scheduleData.schedule[dayIndex] ?? [];
    final alreadyBunkedSet = bunkedClasses[dayIndex] ?? {};

    final skippedClasses = <SkippedClassImpact>[];

    for (final slot in slots) {
      final isAlreadyBunked = alreadyBunkedSet.contains(slot.name);
      if (!isAlreadyBunked) {
        addedSkipsPerSubject[slot.name] = (addedSkipsPerSubject[slot.name] ?? 0) + 1;
        newClassesToSkipCount++;
      }

      final subject = computedSubjects[slot.name];
      final totalClasses = subject?.totalClasses ?? 0;
      final heldClasses = subject?.heldClasses ?? 0;
      final currentSkipped = subject?.skipped ?? 0;
      final faculty = subject?.faculty ?? '';

      final double currentPct;
      if (showCurrentAttendance) {
        currentPct = heldClasses == 0
            ? 0.0
            : (heldClasses - currentSkipped) / heldClasses;
      } else {
        currentPct = totalClasses == 0
            ? 0.0
            : (totalClasses - currentSkipped) / totalClasses;
      }

      final int newSkipped = currentSkipped + (isAlreadyBunked ? 0 : 1);
      final double projectedPct;
      if (showCurrentAttendance) {
        final projectedHeld = heldClasses + (isAlreadyBunked ? 0 : 1);
        projectedPct = projectedHeld == 0
            ? 0.0
            : (projectedHeld - newSkipped) / projectedHeld;
      } else {
        projectedPct = totalClasses == 0
            ? 0.0
            : (totalClasses - newSkipped) / totalClasses;
      }

      final percentageDrop = (currentPct - projectedPct) * 100;

      skippedClasses.add(
        SkippedClassImpact(
          subjectName: slot.name,
          timeRange: slot.timeRange,
          faculty: faculty,
          currentPercentage: currentPct,
          projectedPercentage: projectedPct,
          percentageDrop: percentageDrop < 0 ? 0.0 : percentageDrop,
          totalClasses: totalClasses,
          currentSkipped: currentSkipped,
          newSkipped: newSkipped,
          isAlreadyBunked: isAlreadyBunked,
        ),
      );
    }

    final isWholeDayBunked = slots.isNotEmpty &&
        slots.every((s) => alreadyBunkedSet.contains(s.name));

    final dayLabel = DateFormat('EEEE, MMM d').format(bunkDate);

    bunkDayDetails.add(
      LongWeekendBunkDayDetail(
        date: bunkDate,
        dayIndex: dayIndex,
        dayLabel: dayLabel,
        classes: skippedClasses,
        isWholeDayBunked: isWholeDayBunked,
      ),
    );
  }

  // Calculate overall attendance impact
  final totalClasses = overallStats.totalClasses;
  final classesHeld = overallStats.classesHeld;
  final currentMissed = overallStats.missed;
  final currentOverallAttendance = overallStats.attendance;

  final projectedMissed = currentMissed + newClassesToSkipCount;
  final double projectedOverallAttendance;

  if (showCurrentAttendance) {
    final projectedHeld = classesHeld + newClassesToSkipCount;
    projectedOverallAttendance = projectedHeld == 0
        ? 0.0
        : (projectedHeld - projectedMissed) / projectedHeld;
  } else {
    projectedOverallAttendance = totalClasses == 0
        ? 0.0
        : (totalClasses - projectedMissed) / totalClasses;
  }

  final overallDrop = (currentOverallAttendance - projectedOverallAttendance) * 100;
  final isSafe = projectedOverallAttendance >= (desiredPercentage - 0.0001);

  return LongWeekendImpact(
    longWeekend: longWeekend,
    bunkDays: bunkDayDetails,
    totalClassesSkipped: newClassesToSkipCount,
    currentOverallAttendance: currentOverallAttendance,
    projectedOverallAttendance: projectedOverallAttendance,
    overallPercentageDrop: overallDrop < 0 ? 0.0 : overallDrop,
    isSafe: isSafe,
    desiredPercentage: desiredPercentage,
  );
}

// ---------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------

/// Computes all long weekends across the active semester.
final allLongWeekendsProvider = Provider<List<LongWeekend>>((ref) {
  final holidays = ref.watch(allHolidaysProvider);
  final systemHolidays = ref.watch(systemHolidaysProvider);
  final exams = ref.watch(examsProvider);
  final settings = ref.watch(settingsProvider);

  return calculateLongWeekends(
    holidays: holidays,
    systemHolidays: systemHolidays,
    exams: exams,
    startDate: settings.startDate,
    endDate: settings.endDate,
  );
});

/// Computes long weekends for a specific month.
final longWeekendsForMonthProvider =
    Provider.family<List<LongWeekend>, DateTime>((ref, month) {
      final holidays = ref.watch(allHolidaysProvider);
      final systemHolidays = ref.watch(systemHolidaysProvider);
      final exams = ref.watch(examsProvider);
      final settings = ref.watch(settingsProvider);

      return calculateLongWeekendsForMonth(
        month: month,
        holidays: holidays,
        systemHolidays: systemHolidays,
        exams: exams,
        startDate: settings.startDate,
        endDate: settings.endDate,
      );
    });

/// Computes detailed attendance impact for a given long weekend.
final longWeekendImpactProvider =
    Provider.family<LongWeekendImpact, LongWeekend>((ref, longWeekend) {
      final scheduleData = ref.watch(scheduleDataProvider);
      final computedSubjects = ref.watch(computedSubjectsProvider);
      final overallStats = ref.watch(attendanceStatsProvider);
      final bunkedClasses = ref.watch(bunkedProvider);
      final settings = ref.watch(settingsProvider);

      return calculateLongWeekendImpact(
        longWeekend: longWeekend,
        scheduleData: scheduleData,
        computedSubjects: computedSubjects,
        overallStats: overallStats,
        bunkedClasses: bunkedClasses,
        semesterStartDate: settings.startDate,
        desiredPercentage: settings.desiredPercentage,
        showCurrentAttendance: settings.showCurrentAttendance,
      );
    });
