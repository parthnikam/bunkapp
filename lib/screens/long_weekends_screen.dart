import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state.dart';
import '../theme/bunk_theme.dart';

class LongWeekendsScreen extends ConsumerWidget {
  final DateTime month;

  const LongWeekendsScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final longWeekends = ref.watch(longWeekendsForMonthProvider(month));
    final theme = BunkTheme.of(context);
    final monthLabel = DateFormat('MMMM yyyy').format(month).toUpperCase();

    return CupertinoPageScaffold(
      backgroundColor: theme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                    alignment: Alignment.centerLeft,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.lightGrey),
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_back,
                        color: theme.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('LONG WEEKENDS', style: theme.display),
                  const SizedBox(height: 2),
                  Text(
                    monthLabel,
                    style: theme.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Main Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                children: [
                  if (longWeekends.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.lightGrey),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.calendar_badge_minus,
                            size: 48,
                            color: theme.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Long Weekends this month',
                            style: theme.bodyBold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are no holidays adjacent to weekends in $monthLabel.',
                            style: theme.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...longWeekends.map(
                      (lw) => LongWeekendCard(longWeekend: lw),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A clean, simple card displaying a single long weekend and its details.
class LongWeekendCard extends ConsumerWidget {
  final LongWeekend longWeekend;

  const LongWeekendCard({super.key, required this.longWeekend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = BunkTheme.of(context);
    final lw = longWeekend;
    final impact = ref.watch(longWeekendImpactProvider(lw));

    final dateRangeStr = lw.formattedDateRange.toUpperCase();
    String subStatusText;
    if (!lw.hasSkippedClasses) {
      subStatusText = 'No classes to be skipped';
    } else {
      final skipDayLabels = lw.bunkDates
          .map((d) => DateFormat('EEEE').format(d))
          .join(', ');
      subStatusText = 'Requires skipping $skipDayLabels';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title & Dates
          Text(dateRangeStr, style: theme.bodyBold.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            lw.title,
            style: theme.body.copyWith(fontSize: 14, color: theme.black),
          ),
          const SizedBox(height: 2),
          Text(
            subStatusText,
            style: theme.caption.copyWith(
              fontSize: 12,
              color: lw.hasSkippedClasses ? theme.grey : theme.accent,
            ),
          ),
          const SizedBox(height: 12),

          // Day sequence chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lw.days.map((d) {
              final dayName = DateFormat('E, MMM d').format(d.date);
              String roleText;
              Color pillBg;
              Color pillFg;

              if (d.isHoliday) {
                roleText = d.holidayName?.isNotEmpty == true
                    ? d.holidayName!
                    : 'Holiday';
                pillBg = theme.yellow.withValues(alpha: 0.2);
                pillFg = theme.black;
              } else if (d.isBunkDay) {
                roleText = 'Skip Class';
                pillBg = theme.grey.withValues(alpha: 0.15);
                pillFg = theme.red;
              } else {
                roleText = 'Weekend';
                pillBg = theme.lightGrey.withValues(alpha: 0.15);
                pillFg = theme.grey;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayName.toUpperCase(),
                      style: theme.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: pillFg,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      roleText,
                      style: theme.caption.copyWith(
                        fontSize: 10,
                        color: pillFg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Skipped classes list
          if (lw.hasSkippedClasses) ...[
            const SizedBox(height: 16),
            ...impact.bunkDays.map(
              (bunkDay) => _buildBunkDaySection(context, bunkDay),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBunkDaySection(
    BuildContext context,
    LongWeekendBunkDayDetail bunkDay,
  ) {
    final theme = BunkTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            bunkDay.dayLabel.toUpperCase(),
            style: theme.body.copyWith(
              fontWeight: FontWeight.normal,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (bunkDay.classes.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'No classes scheduled on this day.',
              style: theme.caption,
            ),
          )
        else
          ...bunkDay.classes.map((cls) => SkippedClassTile(impact: cls)),
      ],
    );
  }
}

/// A tile presenting a single class scheduled on a skipped day with its attendance drop.
class SkippedClassTile extends StatelessWidget {
  final SkippedClassImpact impact;

  const SkippedClassTile({super.key, required this.impact});

  @override
  Widget build(BuildContext context) {
    final theme = BunkTheme.of(context);

    final currentStr =
        '${(impact.currentPercentage * 100).toStringAsFixed(1)}%';
    final projectedStr =
        '${(impact.projectedPercentage * 100).toStringAsFixed(1)}%';
    // final dropStr = '-${impact.percentageDrop.toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.lightGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  impact.subjectName.toUpperCase(),
                  style: theme.bodyBold.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  impact.faculty.isNotEmpty
                      ? '${impact.timeRange} • ${impact.faculty}'
                      : impact.timeRange,
                  style: theme.caption.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentStr,
                    style: theme.caption.copyWith(
                      fontSize: 14,
                      color: theme.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(CupertinoIcons.arrow_right, size: 10, color: theme.grey),
                  const SizedBox(width: 4),
                  Text(
                    projectedStr,
                    style: theme.bodyBold.copyWith(
                      fontSize: 14,
                      color: theme.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              // Text(
              //   dropStr,
              //   style: theme.caption.copyWith(
              //     fontSize: 10,
              //     fontWeight: FontWeight.bold,
              //     color: theme.red,
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
