import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state.dart';
import '../theme/bunk_theme.dart';
import '../widgets/attendance_change_preview.dart';
import '../widgets/bunk_today_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPrompts();
    });
  }

  void _checkAndShowPrompts() {
    if (_dialogShown || !mounted) return;
    final settings = ref.read(settingsProvider);
    if (!settings.isFirstLaunch && !settings.hasSeenAttendanceTogglePrompt) {
      _dialogShown = true;
      _showAttendanceFeatureDialog(context);
    } else if (!settings.isFirstLaunch && !settings.hasSeenContactUsPrompt) {
      _dialogShown = true;
      _showContactUsFeatureDialog(context);
    } else if (!settings.isFirstLaunch && !settings.hasSeenLongWeekendsPrompt) {
      _dialogShown = true;
      _showLongWeekendsFeatureDialog(context);
    }
  }

  void _showAttendanceFeatureDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: Text(
            'NEW: ATTENDANCE MODES',
            style: BunkTheme.of(context).h2.copyWith(fontSize: 18),
          ),
          content: Column(
            children: [
              Text(
                'You can now switch attendance modes.',
                style: BunkTheme.of(context).body.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BunkTheme.of(
                    context,
                  ).lightGrey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: BunkTheme.of(context).bodyBold),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: BunkTheme.of(context).caption.copyWith(
                                fontSize: 12,
                                color: BunkTheme.of(context).black,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Current: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text:
                                      'Calculated only from classes held till date.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: BunkTheme.of(context).bodyBold),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: BunkTheme.of(context).caption.copyWith(
                                fontSize: 12,
                                color: BunkTheme.of(context).black,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Overall: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: 'Projected across the entire semester.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Keep Overall'),
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setHasSeenAttendanceTogglePrompt(true);
                Navigator.pop(ctx);
                _dialogShown = false;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _checkAndShowPrompts(),
                );
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Switch to Current'),
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setShowCurrentAttendance(true);
                ref
                    .read(settingsProvider.notifier)
                    .setHasSeenAttendanceTogglePrompt(true);
                Navigator.pop(ctx);
                _dialogShown = false;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _checkAndShowPrompts(),
                );
              },
            ),
            CupertinoDialogAction(
              child: const Text('Go to Settings'),
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setHasSeenAttendanceTogglePrompt(true);
                Navigator.pop(ctx);
                ref.read(uiProvider.notifier).setTab(3);
              },
            ),
          ],
        );
      },
    );
  }

  void _showContactUsFeatureDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: Text(
            'GOT FEEDBACK? ROAST US',
            style: BunkTheme.of(context).h2.copyWith(fontSize: 18),
          ),
          content: Column(
            children: [
              Text(
                'Have a feature in mind, found a pesky bug, or want to share your bunk masterplan? We’re all ears!',
                style: BunkTheme.of(context).body.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BunkTheme.of(
                    context,
                  ).lightGrey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: BunkTheme.of(context).caption.copyWith(
                      fontSize: 12,
                      color: BunkTheme.of(context).black,
                    ),
                    children: const [
                      TextSpan(text: 'Slide into our inbox anytime under\n'),
                      TextSpan(
                        text: 'Settings > Contact Us',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Maybe Later'),
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setHasSeenContactUsPrompt(true);
                Navigator.pop(ctx);
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Go to Settings'),
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setHasSeenContactUsPrompt(true);
                Navigator.pop(ctx);
                ref.read(uiProvider.notifier).setTab(3);
              },
            ),
          ],
        );
      },
    );
  }

  void _showLongWeekendsFeatureDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: Text(
            'NEW: LONG WEEKENDS',
            style: BunkTheme.of(context).h2.copyWith(fontSize: 18),
          ),
          content: Column(
            children: [
              Text(
                'Spot long weekends directly on your calendar and plan your time off with zero guesswork.',
                style: BunkTheme.of(context).body.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Container(
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: BunkTheme.of(
              //       context,
              //     ).lightGrey.withValues(alpha: 0.35),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Row(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text('• ', style: BunkTheme.of(context).bodyBold),
              //           Expanded(
              //             child: RichText(
              //               text: TextSpan(
              //                 style: BunkTheme.of(context).caption.copyWith(
              //                   fontSize: 12,
              //                   color: BunkTheme.of(context).black,
              //                 ),
              //                 children: const [
              //                   TextSpan(
              //                     text: 'Calendar Outlines: ',
              //                     style: TextStyle(fontWeight: FontWeight.bold),
              //                   ),
              //                   TextSpan(
              //                     text:
              //                         'Highlighted with continuous dashed outlines on your monthly calendar.',
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 6),
              //       Row(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text('• ', style: BunkTheme.of(context).bodyBold),
              //           Expanded(
              //             child: RichText(
              //               text: TextSpan(
              //                 style: BunkTheme.of(context).caption.copyWith(
              //                   fontSize: 12,
              //                   color: BunkTheme.of(context).black,
              //                 ),
              //                 children: const [
              //                   TextSpan(
              //                     text: 'Attendance Impact: ',
              //                     style: TextStyle(fontWeight: FontWeight.bold),
              //                   ),
              //                   TextSpan(
              //                     text:
              //                         'See exact skipped classes and projected percentage drops before deciding.',
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 6),
              //       Row(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text('• ', style: BunkTheme.of(context).bodyBold),
              //           Expanded(
              //             child: RichText(
              //               text: TextSpan(
              //                 style: BunkTheme.of(context).caption.copyWith(
              //                   fontSize: 12,
              //                   color: BunkTheme.of(context).black,
              //                 ),
              //                 children: const [
              //                   TextSpan(
              //                     text: 'Exam Protection: ',
              //                     style: TextStyle(fontWeight: FontWeight.bold),
              //                   ),
              //                   TextSpan(
              //                     text:
              //                         'Classes on exam days are never skipped.',
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Got It'),
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setHasSeenLongWeekendsPrompt(true);
                Navigator.pop(ctx);
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('View Calendar'),
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setHasSeenLongWeekendsPrompt(true);
                Navigator.pop(ctx);
                ref.read(uiProvider.notifier).setTab(1);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(settingsProvider.select((s) => s.name));
    final currentSem = ref.watch(currentSemesterProvider);
    ref.watch(attendanceStatsProvider.select((s) => s.safeBunks));
    final todayDay = ref.watch(uiProvider.select((s) => s.todayDay));
    final scheduleData = ref.watch(scheduleDataProvider);
    final startDate = ref.watch(settingsProvider.select((s) => s.startDate));
    final canBunkToday = ref.watch(canBunkTodayProvider);
    final examsMap = ref.watch(examsProvider);
    final systemHolidaysMap = ref.watch(systemHolidaysProvider);
    final allHolidays = ref.watch(allHolidaysProvider);

    final currentDate = dateFromDayIndex(startDate, todayDay);

    final isHoliday = allHolidays.any((h) {
      return h.year == currentDate.year &&
          h.month == currentDate.month &&
          h.day == currentDate.day;
    });
    final holidayName =
        systemHolidaysMap[DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        )];

    final isExam = examsMap.containsKey(
      DateTime(currentDate.year, currentDate.month, currentDate.day),
    );
    final examName =
        examsMap[DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        )];

    final todayClasses = scheduleData.schedule[todayDay] ?? [];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.trim().isEmpty
                          ? 'HELLO THERE'
                          : 'HELLO, ${name.toUpperCase()}',
                      style: BunkTheme.of(context).display,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentSem != null
                          ? '${currentSem.toUpperCase()} • ${_getFormattedDate(currentDate)}'
                          : _getFormattedDate(currentDate),
                      style: BunkTheme.of(context).body.copyWith(
                        color: BunkTheme.of(context).grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BunkTheme.of(context).white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BunkTheme.of(context).lightGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAN I BUNK TODAY?',
                  style: BunkTheme.of(context).body.copyWith(
                    color: BunkTheme.of(context).grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      canBunkToday ? 'YES' : 'NO',
                      style: BunkTheme.of(context).display,
                    ),
                    const SizedBox(width: 12),
                    // Container(
                    //   width: 12,
                    //   height: 12,
                    //   decoration: BoxDecoration(
                    //     shape: BoxShape.circle,
                    //     color: canBunkToday
                    //         ? BunkTheme.of(context).accent
                    //         : BunkTheme.of(context).red,
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  canBunkToday
                      ? "You're safe to take the day off."
                      : "Don't even think about it.",
                  style: BunkTheme.of(context).body,
                ),
              ],
            ),
          ),
          if (!isHoliday && !isExam) ...[
            const SizedBox(height: 16),
            BunkTodayButton(dayIndex: todayDay),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLASSES TODAY',
                style: BunkTheme.of(context).body.copyWith(
                  color: BunkTheme.of(context).grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isHoliday)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BunkTheme.of(context).accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BunkTheme.of(context).accent.withValues(alpha: 0.3),
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
                    style: BunkTheme.of(
                      context,
                    ).display.copyWith(color: BunkTheme.of(context).accent),
                  ),
                  if (holidayName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Holiday: $holidayName",
                      textAlign: TextAlign.center,
                      style: BunkTheme.of(
                        context,
                      ).bodyBold.copyWith(color: BunkTheme.of(context).accent),
                    ),
                  ],
                ],
              ),
            )
          else if (isExam)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BunkTheme.of(context).red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BunkTheme.of(context).red.withValues(alpha: 0.3),
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
                    style: BunkTheme.of(
                      context,
                    ).display.copyWith(color: BunkTheme.of(context).red),
                  ),
                  if (examName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Exam Today: $examName",
                      textAlign: TextAlign.center,
                      style: BunkTheme.of(
                        context,
                      ).bodyBold.copyWith(color: BunkTheme.of(context).red),
                    ),
                  ],
                ],
              ),
            )
          else if (todayClasses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No classes today!",
                  style: BunkTheme.of(context).caption,
                ),
              ),
            )
          else
            Column(
              children: todayClasses
                  .map(
                    (slot) => TodaySubjectCard(
                      title: slot.name,
                      time: slot.timeRange.isNotEmpty
                          ? slot.timeRange
                          : 'Time TBA',
                      isNonNormalDay: isHoliday || isExam,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final dayName = weekdays[date.weekday - 1];
    final monthName = months[date.month - 1];
    final day = date.day;

    String suffix = 'th';
    if (day % 10 == 1 && day != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day != 12) {
      suffix = 'nd';
    } else if (day % 10 == 3 && day != 13) {
      suffix = 'rd';
    }

    return '$dayName, $day$suffix $monthName'.toUpperCase();
  }
}

class TodaySubjectCard extends ConsumerWidget {
  final String title;
  final String time;
  final bool isNonNormalDay;

  const TodaySubjectCard({
    super.key,
    required this.title,
    required this.time,
    this.isNonNormalDay = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDay = ref.watch(uiProvider.select((s) => s.todayDay));
    final checked = ref.watch(
      bunkedProvider.select((b) => b[todayDay]?.contains(title) == true),
    );
    final sub = ref.watch(computedSubjectsProvider)[title];
    final showCurrent = ref.watch(
      settingsProvider.select((s) => s.showCurrentAttendance),
    );

    int currentPct = 0;
    int nextPct = 0;

    if (sub != null) {
      if (showCurrent) {
        final held = sub.heldClasses;
        final missed = sub.skipped;
        if (held > 0) {
          if (checked) {
            currentPct = (((held - (missed - 1)) / held) * 100).toInt();
            nextPct = (((held - missed) / held) * 100).toInt();
          } else {
            currentPct = (((held - missed) / held) * 100).toInt();
            nextPct = (((held - (missed + 1)) / held) * 100).toInt();
          }
        }
      } else {
        if (sub.totalClasses > 0) {
          final total = sub.totalClasses;
          final missed = sub.skipped;
          if (checked) {
            currentPct = (((total - (missed - 1)) / total) * 100).toInt();
            nextPct = (((total - missed) / total) * 100).toInt();
          } else {
            currentPct = (((total - missed) / total) * 100).toInt();
            nextPct = (((total - (missed + 1)) / total) * 100).toInt();
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BunkTheme.of(context).white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BunkTheme.of(context).lightGrey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                // const SizedBox(height: 4),
                Text(
                  time,
                  style: MediaQuery.sizeOf(context).width >= 410
                      ? BunkTheme.of(context).caption.copyWith(fontSize: 12)
                      : BunkTheme.of(context).caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          AttendanceChangePreview(
            checked: checked,
            currentPct: currentPct,
            nextPct: nextPct,
          ),
          const SizedBox(width: 16),
          if (!isNonNormalDay)
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(bunkedProvider.notifier)
                        .toggleBunk(todayDay, title);
                  },

                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
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
            ),
        ],
      ),
    );
  }
}
