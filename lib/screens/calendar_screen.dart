import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state.dart';
import '../theme/bunk_theme.dart';
import '../widgets/attendance_change_preview.dart';
import '../widgets/bunk_today_button.dart';
import 'long_weekends_screen.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _currentMonth;
  List<DateTime>? _availableMonthsCache;
  DateTime? _cachedStartDate;
  DateTime? _cachedEndDate;
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  List<DateTime> _getAvailableMonths(DateTime start, DateTime end) {
    List<DateTime> months = [];
    DateTime current = DateTime(start.year, start.month, 1);
    DateTime endMonth = DateTime(end.year, end.month, 1);
    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    if (months.isEmpty) months.add(current);
    return months;
  }

  String _formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMMM').format(date).toUpperCase();
  }

  void _showMonthPicker(
    BuildContext context,
    List<DateTime> availableMonths,
    DateTime currentMonth,
  ) {
    int initialIndex = availableMonths.indexWhere(
      (d) => d.year == currentMonth.year && d.month == currentMonth.month,
    );
    if (initialIndex == -1) initialIndex = 0;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: initialIndex,
            ),
            onSelectedItemChanged: (int index) {
              if (_pageController?.hasClients ?? false) {
                _pageController!.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            children: List<Widget>.generate(availableMonths.length, (
              int index,
            ) {
              return Center(
                child: Text(_formatMonthYear(availableMonths[index])),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final uiState = ref.watch(uiProvider);
    final holidays = ref.watch(allHolidaysProvider);
    final examsMap = ref.watch(examsProvider);
    final systemHolidaysMap = ref.watch(systemHolidaysProvider);
    final scheduleData = ref.watch(scheduleDataProvider);

    ref.listen(uiProvider.select((s) => s.currentTab), (previous, current) {
      if (current == 1 && previous != 1) {
        final todayDay = ref.read(uiProvider).todayDay;
        ref.read(uiProvider.notifier).selectDay(todayDay);

        final availableMonths = _getAvailableMonths(
          settings.startDate,
          settings.endDate,
        );
        DateTime todayDate = dateFromDayIndex(settings.startDate, todayDay);
        int initialIndex = availableMonths.indexWhere(
          (d) => d.year == todayDate.year && d.month == todayDate.month,
        );
        if (initialIndex == -1) initialIndex = 0;

        setState(() {
          _currentMonth = availableMonths[initialIndex];
        });

        if (_pageController?.hasClients ?? false) {
          _pageController!.jumpToPage(initialIndex);
        }
      }
    });

    if (_currentMonth == null ||
        _cachedStartDate != settings.startDate ||
        _cachedEndDate != settings.endDate) {
      final availableMonths = _getAvailableMonths(
        settings.startDate,
        settings.endDate,
      );
      _availableMonthsCache = availableMonths;
      _cachedStartDate = settings.startDate;
      _cachedEndDate = settings.endDate;

      DateTime todayDate = dateFromDayIndex(
        settings.startDate,
        uiState.todayDay,
      );
      int initialIndex = availableMonths.indexWhere(
        (d) => d.year == todayDate.year && d.month == todayDate.month,
      );
      if (initialIndex == -1) initialIndex = 0;

      _currentMonth = availableMonths[initialIndex];
      _pageController = PageController(initialPage: initialIndex);
    }
    final availableMonths = _availableMonthsCache!;
    final allLongWeekends = ref.watch(allLongWeekendsProvider);
    final allLwDates = {
      for (final lw in allLongWeekends)
        for (final d in lw.days) dateOnly(d.date),
    };
    final longWeekendsThisMonth = _currentMonth != null
        ? allLongWeekends.where((lw) {
            for (final day in lw.days) {
              if (day.date.year == _currentMonth!.year &&
                  day.date.month == _currentMonth!.month) {
                return true;
              }
            }
            return false;
          }).toList()
        : const <LongWeekend>[];

    final totalDaysSemester =
        settings.endDate.difference(settings.startDate).inDays + 1;
    DateTime? selectedDateObj;
    if (uiState.selectedDay >= 1 && uiState.selectedDay <= totalDaysSemester) {
      selectedDateObj = dateFromDayIndex(
        settings.startDate,
        uiState.selectedDay,
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('CALENDAR', style: BunkTheme.of(context).display)],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.chevron_left,
                  color: BunkTheme.of(context).grey,
                  size: 20,
                ),
                onPressed: () {
                  if (_pageController?.hasClients ?? false) {
                    _pageController!.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              GestureDetector(
                onTap: () =>
                    _showMonthPicker(context, availableMonths, _currentMonth!),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMonthYear(_currentMonth!),
                      style: BunkTheme.of(
                        context,
                      ).bodyBold.copyWith(fontSize: 18),
                    ),
                    // const SizedBox(width: 4),
                    // Icon(
                    //   CupertinoIcons.chevron_down,
                    //   color: BunkTheme.of(context).grey,
                    //   size: 14,
                    // ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.chevron_right,
                  color: BunkTheme.of(context).grey,
                  size: 20,
                ),
                onPressed: () {
                  if (_pageController?.hasClients ?? false) {
                    _pageController!.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  // color: BunkTheme.of(context).white,
                  // borderRadius: BorderRadius.circular(16),
                  // border: Border.all(color: BunkTheme.of(context).lightGrey),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    const double crossAxisSpacing = 16.0;
                    const double mainAxisSpacing = 16.0;
                    final double cellWidth =
                        (availableWidth - (6 * crossAxisSpacing)) / 7.0;
                    final double pageHeight =
                        (cellWidth * 6) + (mainAxisSpacing * 5);

                    return Column(
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 7,
                          crossAxisSpacing: crossAxisSpacing,
                          childAspectRatio: 1.0,
                          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                              .map(
                                (d) => Center(
                                  child: Text(
                                    d,
                                    style: BunkTheme.of(context).body.copyWith(
                                      color: BunkTheme.of(context).grey,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: mainAxisSpacing),
                        SizedBox(
                          height: pageHeight,
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const ClampingScrollPhysics(),
                            onPageChanged: (index) {
                              setState(() {
                                _currentMonth = availableMonths[index];
                              });
                            },
                            itemCount: availableMonths.length,
                            itemBuilder: (context, pageIndex) {
                              final month = availableMonths[pageIndex];

                              final daysInMonth = DateTime(
                                month.year,
                                month.month + 1,
                                0,
                              ).day;
                              final firstDayWeekday = DateTime(
                                month.year,
                                month.month,
                                1,
                              ).weekday;
                              final offset = firstDayWeekday == 7
                                  ? 0
                                  : firstDayWeekday;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: mainAxisSpacing,
                                      crossAxisSpacing: crossAxisSpacing,
                                    ),
                                itemCount: daysInMonth + offset,
                                itemBuilder: (ctx, i) {
                                  if (i < offset) return const SizedBox();
                                  final dayOfMonth = i - offset + 1;
                                  final date = DateTime(
                                    month.year,
                                    month.month,
                                    dayOfMonth,
                                  );

                                  final dayIndex =
                                      date
                                          .difference(settings.startDate)
                                          .inDays +
                                      1;
                                  final isWithinSemester =
                                      dayIndex >= 1 &&
                                      dayIndex <= totalDaysSemester;

                                  final isSelected =
                                      dayIndex == uiState.selectedDay;
                                  final isToday = dayIndex == uiState.todayDay;

                                  final isHol =
                                      isWithinSemester &&
                                      holidays.contains(dateOnly(date));
                                  final dateNorm = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                  );
                                  final isEx =
                                      isWithinSemester &&
                                      examsMap.containsKey(dateNorm);
                                  final isLw =
                                      isWithinSemester &&
                                      allLwDates.contains(dateOnly(date));

                                  final prevDate = date.subtract(
                                    const Duration(days: 1),
                                  );
                                  final nextDate = date.add(
                                    const Duration(days: 1),
                                  );
                                  final extendLeft =
                                      isLw &&
                                      allLwDates.contains(dateOnly(prevDate));
                                  final extendRight =
                                      isLw &&
                                      allLwDates.contains(dateOnly(nextDate));

                                  return CalendarDayCell(
                                    dayOfMonth: dayOfMonth,
                                    dayIndex: dayIndex,
                                    isWithinSemester: isWithinSemester,
                                    isHol: isHol,
                                    isEx: isEx,
                                    isLw: isLw,
                                    extendLeft: extendLeft,
                                    extendRight: extendRight,
                                    spacing: crossAxisSpacing,
                                    isSelected: isSelected,
                                    isToday: isToday,
                                    slots: scheduleData.schedule[dayIndex],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (longWeekendsThisMonth.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) =>
                            LongWeekendsScreen(month: _currentMonth!),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        longWeekendsThisMonth.length == 1
                            ? '1 Long weekend this month'
                            : '${longWeekendsThisMonth.length} Long weekends this month',
                        style: BunkTheme.of(context).body.copyWith(
                          color: BunkTheme.of(context).black,
                          // decoration: TextDecoration.underline,
                          // decorationColor: BunkTheme.of(context).yellow,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: BunkTheme.of(context).black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Builder(
            builder: (context) {
              bool isHoliday(int dIdx) {
                if (dIdx < 1) return false;
                DateTime d = dateFromDayIndex(settings.startDate, dIdx);
                return holidays.contains(dateOnly(d));
              }

              String? getHolidayName(int dIdx) {
                if (dIdx < 1) return null;
                DateTime d = dateFromDayIndex(settings.startDate, dIdx);
                final dNorm = DateTime(d.year, d.month, d.day);
                return systemHolidaysMap[dNorm];
              }

              bool isExam(int dIdx) {
                if (dIdx < 1) return false;
                DateTime d = dateFromDayIndex(settings.startDate, dIdx);
                final dNorm = DateTime(d.year, d.month, d.day);
                return examsMap.containsKey(dNorm);
              }

              String? getExamName(int dIdx) {
                if (dIdx < 1) return null;
                DateTime d = dateFromDayIndex(settings.startDate, dIdx);
                final dNorm = DateTime(d.year, d.month, d.day);
                return examsMap[dNorm];
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isHoliday(uiState.selectedDay) ||
                      selectedDateObj?.weekday == 7 ||
                      selectedDateObj?.weekday == 6 ||
                      isExam(uiState.selectedDay))
                    const SizedBox.shrink()
                  else
                    BunkTodayButton(dayIndex: uiState.selectedDay),

                  if (selectedDateObj != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      'DETAILS FOR ${_formatMonth(selectedDateObj)} ${selectedDateObj.day}',
                      style: BunkTheme.of(context).h2,
                    ),
                    const SizedBox(height: 16),
                    if (isExam(uiState.selectedDay))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: BunkTheme.of(
                              context,
                            ).red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: BunkTheme.of(
                                context,
                              ).red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: BunkTheme.of(context).red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "GO AND STUDY YOU RETARD",
                                textAlign: TextAlign.center,
                                style: BunkTheme.of(context).display.copyWith(
                                  color: BunkTheme.of(context).red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Exam Today: ${getExamName(uiState.selectedDay) ?? 'Scheduled Exam'}",
                                textAlign: TextAlign.center,
                                style: BunkTheme.of(context).bodyBold.copyWith(
                                  color: BunkTheme.of(context).red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isHoliday(uiState.selectedDay))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: BunkTheme.of(
                              context,
                            ).accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: BunkTheme.of(
                                context,
                              ).accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.park_rounded,
                                color: BunkTheme.of(context).accent,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "TIME TO CHILL AND TOUCH SOME GRASS",
                                textAlign: TextAlign.center,
                                style: BunkTheme.of(context).display.copyWith(
                                  color: BunkTheme.of(context).accent,
                                ),
                              ),
                              if (getHolidayName(uiState.selectedDay) !=
                                  null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "Holiday: ${getHolidayName(uiState.selectedDay)}",
                                  textAlign: TextAlign.center,
                                  style: BunkTheme.of(context).bodyBold
                                      .copyWith(
                                        color: BunkTheme.of(context).accent,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else if ((scheduleData
                                .schedule[uiState.selectedDay]
                                ?.length ??
                            0) ==
                        0)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            "No classes today!",
                            style: BunkTheme.of(context).caption,
                          ),
                        ),
                      ),
                    if (!isHoliday(uiState.selectedDay) &&
                        !isExam(uiState.selectedDay))
                      ...(scheduleData.schedule[uiState.selectedDay] ?? []).map(
                        (slot) => CalendarSubjectCard(
                          title: slot.name,
                          time: slot.timeRange.isNotEmpty
                              ? slot.timeRange
                              : 'Time TBA',
                          dayIndex: uiState.selectedDay,
                          isNonNormalDay:
                              isHoliday(uiState.selectedDay) ||
                              isExam(uiState.selectedDay),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class CalendarSubjectCard extends ConsumerWidget {
  final String title;
  final String time;
  final int dayIndex;
  final bool isNonNormalDay;

  const CalendarSubjectCard({
    super.key,
    required this.title,
    required this.time,
    required this.dayIndex,
    this.isNonNormalDay = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDay = ref.watch(uiProvider.select((s) => s.todayDay));
    final checked = ref.watch(
      bunkedProvider.select((b) => b[dayIndex]?.contains(title) == true),
    );
    final sub = ref.watch(computedSubjectsProvider)[title];
    final showCurrent = ref.watch(
      settingsProvider.select((s) => s.showCurrentAttendance),
    );
    final preview = _attendancePreview(
      sub: sub,
      showCurrent: showCurrent,
      checked: checked,
      // A future class is not held yet. Bunking it adds one held and one miss.
      isFuture: dayIndex > todayDay,
    );

    return GestureDetector(
      onTap: () {
        if (!isNonNormalDay) {
          HapticFeedback.lightImpact();
          ref.read(bunkedProvider.notifier).toggleBunk(dayIndex, title);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BunkTheme.of(context).white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BunkTheme.of(context).lightGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: BunkTheme.of(context).bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: BunkTheme.of(context).caption),
                ],
              ),
            ),
            if (!isNonNormalDay) ...[
              AttendanceChangePreview(
                checked: checked,
                currentPct: preview.currentPct,
                nextPct: preview.nextPct,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 90,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(bunkedProvider.notifier)
                          .toggleBunk(dayIndex, title);
                    },
                    child: checked
                        ? Text(
                            'BUNKED!',
                            key: const ValueKey<bool>(true),
                            style: BunkTheme.of(context).button.copyWith(
                              fontSize: 28,
                              color: BunkTheme.of(context).black,
                            ),
                          )
                        : Container(
                            key: const ValueKey<bool>(false),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: BunkTheme.of(context).black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'BUNK',
                              style: BunkTheme.of(context).bodyBold.copyWith(
                                color: BunkTheme.of(context).white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

({int currentPct, int nextPct}) _attendancePreview({
  required Subject? sub,
  required bool showCurrent,
  required bool checked,
  required bool isFuture,
}) {
  if (sub == null) return (currentPct: 0, nextPct: 0);

  if (showCurrent) {
    final held = sub.heldClasses;
    final missed = sub.skipped;
    if (checked) {
      if (held <= 0) return (currentPct: 0, nextPct: 0);
      return (
        currentPct: (((held - (missed - 1)) / held) * 100).toInt(),
        nextPct: (((held - missed) / held) * 100).toInt(),
      );
    }
    if (isFuture) {
      final current = held <= 0 ? 0 : (((held - missed) / held) * 100).toInt();
      final nextHeld = held + 1;
      return (
        currentPct: current,
        nextPct: (((nextHeld - (missed + 1)) / nextHeld) * 100).toInt(),
      );
    }
    if (held <= 0) return (currentPct: 0, nextPct: 0);
    return (
      currentPct: (((held - missed) / held) * 100).toInt(),
      nextPct: (((held - (missed + 1)) / held) * 100).toInt(),
    );
  }

  if (sub.totalClasses <= 0) return (currentPct: 0, nextPct: 0);
  final total = sub.totalClasses;
  final missed = sub.skipped;
  if (checked) {
    return (
      currentPct: (((total - (missed - 1)) / total) * 100).toInt(),
      nextPct: (((total - missed) / total) * 100).toInt(),
    );
  }
  return (
    currentPct: (((total - missed) / total) * 100).toInt(),
    nextPct: (((total - (missed + 1)) / total) * 100).toInt(),
  );
}

class CalendarDayCell extends ConsumerWidget {
  final int dayOfMonth;
  final int dayIndex;
  final bool isWithinSemester;
  final bool isHol;
  final bool isEx;
  final bool isLw;
  final bool extendLeft;
  final bool extendRight;
  final double spacing;
  final bool isSelected;
  final bool isToday;
  final List<ClassSlot>? slots;

  const CalendarDayCell({
    super.key,
    required this.dayOfMonth,
    required this.dayIndex,
    required this.isWithinSemester,
    required this.isHol,
    required this.isEx,
    this.isLw = false,
    this.extendLeft = false,
    this.extendRight = false,
    this.spacing = 16.0,
    required this.isSelected,
    required this.isToday,
    this.slots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool hasMissedClass = false;
    if (isWithinSemester && slots != null) {
      final dayBunks = ref.watch(bunkedProvider.select((b) => b[dayIndex]));
      if (dayBunks != null) {
        hasMissedClass = slots!.any((slot) => dayBunks.contains(slot.name));
      }
    }

    Widget cell = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected
            ? BunkTheme.of(context).black
            : CupertinoColors.transparent,
        shape: BoxShape.circle,
        border: (isToday && !isSelected)
            ? Border.all(
                color: BunkTheme.of(context).grey.withValues(alpha: 0.5),
                width: 1,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$dayOfMonth',
            style: BunkTheme.of(context).bodyBold.copyWith(
              fontSize: MediaQuery.sizeOf(context).width >= 410 ? 16 : 12,
              color: isSelected
                  ? (isHol
                        ? BunkTheme.of(context).accent
                        : (isEx
                              ? BunkTheme.of(context).red
                              : BunkTheme.of(context).white))
                  : (isHol
                        ? BunkTheme.of(context).accent
                        : (isEx
                              ? BunkTheme.of(context).red
                              : (isWithinSemester
                                    ? BunkTheme.of(context).black
                                    : BunkTheme.of(context).grey))),
            ),
          ),
          if (hasMissedClass)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                CupertinoIcons.circle_filled,
                size: 4,
                color: isSelected
                    ? BunkTheme.of(context).white
                    : BunkTheme.of(context).red,
              ),
            ),
        ],
      ),
    );

    if (isLw) {
      cell = CustomPaint(
        painter: DashedSpanBorderPainter(
          color: BunkTheme.of(context).yellow,
          strokeWidth: 1.5,
          dashLength: 3.5,
          gapLength: 2.5,
          radius: 10.0,
          extendLeft: extendLeft,
          extendRight: extendRight,
          spacing: spacing,
        ),
        child: cell,
      );
    }

    return Semantics(
      label:
          "$dayOfMonth, ${isSelected ? 'selected' : ''} ${isHol ? 'holiday' : ''} ${isEx ? 'exam' : ''} ${isLw ? 'long weekend' : ''}",
      child: GestureDetector(
        onTap: () {
          if (isWithinSemester) {
            HapticFeedback.selectionClick();
            ref.read(uiProvider.notifier).selectDay(dayIndex);
          }
        },
        child: cell,
      ),
    );
  }
}

/// Custom painter to draw a continuous dashed/dotted rounded rectangle border across a long weekend span.
class DashedSpanBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;
  final bool extendLeft;
  final bool extendRight;
  final double spacing;

  const DashedSpanBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 3.5,
    this.gapLength = 2.5,
    this.radius = 10.0,
    this.extendLeft = false,
    this.extendRight = false,
    this.spacing = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final halfGap = spacing / 2;
    final halfStroke = strokeWidth / 2;

    final top = halfStroke;
    final bottom = size.height - halfStroke;
    final left = extendLeft ? -halfGap : halfStroke;
    final right = extendRight ? size.width + halfGap : size.width - halfStroke;

    final path = Path();

    if (!extendLeft && !extendRight) {
      // Single day in row: full rounded rectangle
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        Radius.circular(radius),
      );
      path.addRRect(rrect);
    } else if (!extendLeft && extendRight) {
      // Left end of span (e.g. Day 18): left rounded cap (convex), open right
      path.moveTo(right, top);
      path.lineTo(left + radius, top);
      path.arcToPoint(
        Offset(left, top + radius),
        radius: Radius.circular(radius),
        clockwise: false,
      );
      path.lineTo(left, bottom - radius);
      path.arcToPoint(
        Offset(left + radius, bottom),
        radius: Radius.circular(radius),
        clockwise: false,
      );
      path.lineTo(right, bottom);
    } else if (extendLeft && extendRight) {
      // Middle of span (e.g. Day 19): top and bottom horizontal lines
      path.moveTo(left, top);
      path.lineTo(right, top);
      path.moveTo(left, bottom);
      path.lineTo(right, bottom);
    } else if (extendLeft && !extendRight) {
      // Right end of span (e.g. Day 20): right rounded cap (convex), open left
      path.moveTo(left, top);
      path.lineTo(right - radius, top);
      path.arcToPoint(
        Offset(right, top + radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(right, bottom - radius);
      path.arcToPoint(
        Offset(right - radius, bottom),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(left, bottom);
    }

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedSpanBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.radius != radius ||
        oldDelegate.extendLeft != extendLeft ||
        oldDelegate.extendRight != extendRight ||
        oldDelegate.spacing != spacing;
  }
}
