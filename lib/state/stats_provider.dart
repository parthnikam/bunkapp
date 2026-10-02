import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'utils.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';
import 'bunked_provider.dart';
import 'holidays_provider.dart';
import 'timetable_provider.dart';

final computedSubjectsProvider = Provider<Map<String, Subject>>((ref) {
  final scheduleData = ref.watch(scheduleDataProvider);
  final bunkedClasses = ref.watch(bunkedProvider);
  final todayDay = safeInt(ref.watch(uiProvider.select((s) => s.todayDay)), 1);
  final holidays = ref.watch(allHolidaysProvider);
  final examsMap = ref.watch(examsProvider);
  final settings = ref.watch(settingsProvider);

  final subjects = <String, Subject>{};
  for (final entry in scheduleData.subjects.entries) {
    subjects[entry.key] = entry.value.copyWith(heldClasses: 0, skipped: 0);
  }

  for (final entry in scheduleData.schedule.entries) {
    final i = entry.key;
    final daySlots = entry.value;

    final currentDate = dateFromDayIndex(settings.startDate, i);
    final isHolidayDay = isHolidayDate(holidays, currentDate);
    final isExamDay = examsMap.containsKey(dateOnly(currentDate));

    if (!isHolidayDay && !isExamDay) {
      final isPastOrToday = i <= todayDay;
      for (final slot in daySlots) {
        final currentSub = subjects[slot.name];
        if (currentSub != null) {
          final bunked = bunkedClasses[i]?.contains(slot.name) == true;
          subjects[slot.name] = currentSub.copyWith(
            heldClasses: currentSub.heldClasses + (isPastOrToday || bunked ? 1 : 0),
            skipped: currentSub.skipped + (bunked ? 1 : 0),
          );
        }
      }
    }
  }

  return subjects;
});

final attendanceStatsProvider = Provider<AttendanceStats>((ref) {
  final scheduleData = ref.watch(scheduleDataProvider);
  final subjects = ref.watch(computedSubjectsProvider);
  final settings = ref.watch(settingsProvider);
  final todayDay = safeInt(ref.watch(uiProvider.select((s) => s.todayDay)), 1);
  final bunkedClasses = ref.watch(bunkedProvider);
  final holidays = ref.watch(allHolidaysProvider);
  final examsMap = ref.watch(examsProvider);

  final totalClasses = safeInt(
    subjects.values.fold<int>(0, (sum, s) => sum + safeInt(s.totalClasses)),
  );
  final classesHeld = safeInt(
    subjects.values.fold<int>(0, (sum, s) => sum + safeInt(s.heldClasses)),
  );
  final missed = safeInt(
    subjects.values.fold<int>(0, (sum, s) => sum + safeInt(s.skipped)),
  );
  var classesAttended = classesHeld - missed;
  if (classesAttended < 0) classesAttended = 0;
  final double attendance;
  if (settings.showCurrentAttendance) {
    attendance = classesHeld == 0 ? 0.0 : classesAttended / classesHeld;
  } else {
    attendance =
        totalClasses == 0 ? 0.0 : (totalClasses - missed) / totalClasses;
  }
  final desired = settings.desiredPercentage.isFinite
      ? settings.desiredPercentage.clamp(0.0, 0.99)
      : 0.75;
  final rawSafe = (totalClasses * (1 - desired) - missed);
  final safeBunks = clampInt(rawSafe.isFinite ? rawSafe.floor() : 0, 0, 999);

  final history = <double>[];
  var heldSoFar = 0;
  var missedSoFar = 0;
  for (int i = 1; i <= todayDay; i++) {
    if (scheduleData.schedule.containsKey(i)) {
      DateTime date = dateFromDayIndex(settings.startDate, i);
      bool isHoliday = isHolidayDate(holidays, date);
      bool isExam = examsMap.containsKey(dateOnly(date));
      if (!isHoliday && !isExam) {
        for (var c in scheduleData.schedule[i]!) {
          heldSoFar++;
          if (bunkedClasses[i]?.contains(c.name) == true) {
            missedSoFar++;
          }
        }
      }
    }
    history.add(heldSoFar == 0 ? 0.0 : (heldSoFar - missedSoFar) / heldSoFar);
  }

  double trend = 0.0;
  if (history.length >= 2) {
    trend = history.last - history[history.length - 2];
  }

  return AttendanceStats(
    totalClasses: totalClasses,
    classesHeld: classesHeld,
    missed: missed,
    classesAttended: classesAttended,
    attendance: attendance,
    safeBunks: safeBunks,
    dailyHistory: history,
    trend: trend,
  );
});

({int skipBalance, int classesToAttend}) _skipPlanning({
  required int total,
  required int missedSoFar,
  required double desiredPercentage,
}) {
  var skipBalance = 0;
  var classesToAttend = 0;
  final desired = desiredPercentage.isFinite
      ? desiredPercentage.clamp(0.0, 0.99)
      : 0.75;
  if (desired > 0 && desired < 1 && total > 0) {
    final allowedMisses = (total * (1 - desired)).floor();
    skipBalance = allowedMisses - missedSoFar;
    final recovery = (missedSoFar - total * (1 - desired)) / (1 - desired);
    classesToAttend = recovery.isFinite ? recovery.ceil() : 0;
  }
  if (skipBalance < 0) skipBalance = 0;
  if (classesToAttend < 0) classesToAttend = 0;
  return (skipBalance: skipBalance, classesToAttend: classesToAttend);
}

SubjectStatSummary _subjectStatSummary({
  required Subject display,
  required Subject overall,
  required double desiredPercentage,
  required bool showCurrentAttendance,
}) {
  final attended = display.attendedClasses;
  final double rawPercentage;
  if (showCurrentAttendance) {
    rawPercentage = display.heldClasses == 0
        ? 0.0
        : (display.heldClasses - display.skipped) / display.heldClasses;
  } else {
    rawPercentage = display.totalClasses == 0
        ? 0.0
        : (display.totalClasses - display.skipped) / display.totalClasses;
  }
  final percentage = rawPercentage.isFinite ? rawPercentage : 0.0;
  final plan = _skipPlanning(
    total: overall.totalClasses,
    missedSoFar: overall.skipped,
    desiredPercentage: desiredPercentage,
  );
  final faculty = display.faculty.trim().isNotEmpty
      ? display.faculty.trim()
      : overall.faculty.trim();
  return SubjectStatSummary(
    name: display.name,
    faculty: faculty,
    totalClasses: display.totalClasses,
    heldClasses: display.heldClasses,
    skipped: display.skipped,
    attended: attended,
    percentage: percentage,
    skipBalance: plan.skipBalance,
    classesToAttend: plan.classesToAttend,
  );
}

final filteredStatsProvider = Provider<FilteredStats>((ref) {
  final statsFilter = ref.watch(uiProvider.select((s) => s.statsFilter));
  final todayDay = safeInt(ref.watch(uiProvider.select((s) => s.todayDay)), 1);
  final desiredPercentage = ref.watch(
    settingsProvider.select((s) => s.desiredPercentage),
  );
  final showCurrentAttendance = ref.watch(
    settingsProvider.select((s) => s.showCurrentAttendance),
  );
  final startDate = ref.watch(settingsProvider.select((s) => s.startDate));
  final scheduleData = ref.watch(scheduleDataProvider);
  final bunkedClasses = ref.watch(bunkedProvider);
  final overallStats = ref.watch(attendanceStatsProvider);
  final computedSubjects = ref.watch(computedSubjectsProvider);
  final holidays = ref.watch(allHolidaysProvider);
  final examsMap = ref.watch(examsProvider);

  List<SubjectStatSummary> buildSummaries(
    Map<String, Subject> displaySubjects,
  ) {
    return displaySubjects.values
        .map(
          (sub) => _subjectStatSummary(
            display: sub,
            overall: computedSubjects[sub.name] ?? sub,
            desiredPercentage: desiredPercentage,
            showCurrentAttendance: showCurrentAttendance,
          ),
        )
        .toList(growable: false);
  }

  if (statsFilter == 'Overall') {
    return FilteredStats(
      total: safeInt(overallStats.totalClasses),
      held: safeInt(overallStats.classesHeld),
      missed: safeInt(overallStats.missed),
      attended: safeInt(overallStats.classesAttended),
      attendance: overallStats.attendance.isFinite
          ? overallStats.attendance
          : 0.0,
      desiredPercentage: desiredPercentage,
      filter: statsFilter,
      subjectStats: buildSummaries(computedSubjects),
    );
  }

  bool isDayInFilter(int day) {
    if (statsFilter == 'This Week') {
      return (day - 1) ~/ 7 == (todayDay - 1) ~/ 7;
    }
    if (statsFilter == 'This Month') {
      final todayDate = dateFromDayIndex(startDate, todayDay);
      final date = dateFromDayIndex(startDate, day);
      return date.year == todayDate.year && date.month == todayDate.month;
    }
    return true;
  }

  var countTotal = 0;
  var countHeld = 0;
  var countMissed = 0;
  final filteredSubjects = <String, Subject>{};
  for (var entry in computedSubjects.entries) {
    filteredSubjects[entry.key] = Subject(
      entry.key,
      0,
      0,
      heldClasses: 0,
      faculty: entry.value.faculty,
    );
  }

  scheduleData.schedule.forEach((day, classes) {
    final dayIndex = safeInt(day);
    if (!isDayInFilter(dayIndex)) return;
    final date = dateFromDayIndex(startDate, dayIndex);
    final isHoliday = isHolidayDate(holidays, date);
    final isExam = examsMap.containsKey(dateOnly(date));
    if (isHoliday || isExam) return;

    final isPastOrToday = dayIndex <= todayDay;
    final classCount = classes.length;
    countTotal += classCount;
    if (isPastOrToday) {
      countHeld += classCount;
    }

    for (var c in classes) {
      final bunked = bunkedClasses[dayIndex]?.contains(c.name) == true;
      if (bunked) {
        countMissed++;
      }
      final cur = filteredSubjects[c.name];
      if (cur == null) continue;
      filteredSubjects[c.name] = cur.copyWith(
        totalClasses: cur.totalClasses + 1,
        heldClasses: cur.heldClasses + (isPastOrToday || bunked ? 1 : 0),
        skipped: cur.skipped + (bunked ? 1 : 0),
      );
    }
  });

  var attended = countHeld - countMissed;
  if (attended < 0) attended = 0;
  final double attendance;
  if (showCurrentAttendance) {
    attendance = countHeld == 0 ? 0.0 : attended / countHeld;
  } else {
    attendance =
        countTotal == 0 ? 0.0 : (countTotal - countMissed) / countTotal;
  }

  return FilteredStats(
    total: countTotal,
    held: countHeld,
    missed: countMissed,
    attended: attended,
    attendance: attendance,
    desiredPercentage: desiredPercentage,
    filter: statsFilter,
    subjectStats: buildSummaries(filteredSubjects),
  );
});

final todayStatsProvider = Provider<({int classes, int attended})>((ref) {
  final uiState = ref.watch(uiProvider);
  final scheduleData = ref.watch(scheduleDataProvider);
  final bunkedClasses = ref.watch(bunkedProvider);
  final settings = ref.watch(settingsProvider);
  final holidays = ref.watch(allHolidaysProvider);
  final examsMap = ref.watch(examsProvider);

  DateTime todayDate = dateFromDayIndex(settings.startDate, uiState.todayDay);
  bool isHoliday = isHolidayDate(holidays, todayDate);
  bool isExam = examsMap.containsKey(dateOnly(todayDate));

  if (isHoliday || isExam) {
    return (classes: 0, attended: 0);
  }

  final todayClasses = scheduleData.schedule[uiState.todayDay] ?? [];
  int classes = todayClasses.length;
  int attended =
      classes -
      todayClasses
          .where((s) => bunkedClasses[uiState.todayDay]?.contains(s.name) == true)
          .length;

  return (classes: classes, attended: attended);
});

final canBunkTodayProvider = Provider<bool>((ref) {
  final scheduleData = ref.watch(scheduleDataProvider);
  final subjects = ref.watch(computedSubjectsProvider);
  final todayDay = ref.watch(uiProvider.select((s) => s.todayDay));
  final settings = ref.watch(settingsProvider);
  ref.watch(bunkedProvider);

  final todayClasses = scheduleData.schedule[todayDay] ?? [];

  if (todayClasses.isEmpty) return true;

  for (final slot in todayClasses) {
    final sub = subjects[slot.name];
    if (sub == null || sub.totalClasses == 0) continue;

    int simulatedSkipped = sub.skipped + 1;

    double nextPct = (sub.totalClasses - simulatedSkipped) / sub.totalClasses;
    if (nextPct < (settings.desiredPercentage - 0.0001)) {
      return false;
    }
  }
  return true;
});
