import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/bunk_theme.dart';
import '../state.dart';

/// Pure display card — all percentages / skip planning come precomputed.
/// No TweenAnimationBuilder: ListView recycle must not flash empty bars.
class SubjectStatsCard extends ConsumerWidget {
  final SubjectStatSummary stats;
  final double desiredPercentage;
  final String statsFilter;

  const SubjectStatsCard({
    super.key,
    required this.stats,
    required this.desiredPercentage,
    required this.statsFilter,
  });

  Color _progressColor(BuildContext context) {
    if (stats.percentage < desiredPercentage) {
      return BunkTheme.of(context).red;
    }
    if (stats.percentage >= desiredPercentage + 0.05) {
      return BunkTheme.of(context).green;
    }
    return BunkTheme.of(context).yellow;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressColor = _progressColor(context);
    final pctLabel = '${(stats.percentage * 100).toStringAsFixed(1)}%';
    final barFactor = stats.percentage.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showSubjectDetails(context, ref, progressColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BunkTheme.of(context).white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BunkTheme.of(context).lightGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.name.toUpperCase(),
                        style: BunkTheme.of(
                          context,
                        ).bodyBold.copyWith(fontSize: 18),
                      ),
                      if (stats.faculty.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          stats.faculty,
                          style: BunkTheme.of(context).body.copyWith(
                            fontSize: 13,
                            color: BunkTheme.of(context).grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  pctLabel,
                  style: BunkTheme.of(
                    context,
                  ).bodyBold.copyWith(fontSize: 18, color: progressColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: BunkTheme.of(context).lightGrey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: 6,
                        width: constraints.maxWidth * barFactor,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPill(context, 'Skip balance: ${stats.skipBalance}'),
                  const SizedBox(width: 8),
                  _buildPill(
                    context,
                    'Held ${stats.heldClasses} of ${stats.totalClasses}',
                  ),
                  const SizedBox(width: 8),
                  _buildPill(
                    context,
                    'Missed ${stats.skipped} of ${stats.heldClasses}',
                  ),
                  const SizedBox(width: 8),
                  // _buildPill(
                  //   context,
                  //   'For ${(desiredPercentage * 100).round()}%, attend ${stats.classesToAttend} classes in a row',
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDetails(
    BuildContext context,
    WidgetRef ref,
    Color progressColor,
  ) {
    // Missed-date list is only needed on open — keep list scroll free of it.
    final scheduleData = ref.read(scheduleDataProvider);
    final bunkedClasses = ref.read(bunkedProvider);
    final settings = ref.read(settingsProvider);
    final uiState = ref.read(uiProvider);
    final faculty = stats.faculty;

    bool isDayInFilter(int day) {
      if (statsFilter == 'This Week') {
        return (day - 1) ~/ 7 == (uiState.todayDay - 1) ~/ 7;
      }
      if (statsFilter == 'This Month') {
        final todayDate = dateFromDayIndex(
          settings.startDate,
          uiState.todayDay,
        );
        final date = dateFromDayIndex(settings.startDate, day);
        return date.year == todayDate.year && date.month == todayDate.month;
      }
      return true;
    }

    Future<List<DateTime>> fetchMissedDates() async {
      return await Future.microtask(() {
        final missedDates = <DateTime>[];
        for (var day in scheduleData.schedule.keys) {
          if (day > uiState.todayDay) continue;
          if (!isDayInFilter(day)) continue;
          final hasSubject =
              scheduleData.schedule[day]?.any((s) => s.name == stats.name) ==
              true;
          if (hasSubject && bunkedClasses[day]?.contains(stats.name) == true) {
            missedDates.add(dateFromDayIndex(settings.startDate, day));
          }
        }
        missedDates.sort((a, b) => b.compareTo(a));
        return missedDates;
      });
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String formatDate(DateTime d) {
      return '${weekdayNames[d.weekday - 1]}, ${monthNames[d.month - 1]} ${d.day}, ${d.year}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final maxHeight = MediaQuery.of(context).size.height * 0.85;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: BunkTheme.of(context).white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            // Fixed handle + scrollable body so long content (missed dates)
            // is never clipped below the fold.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: BunkTheme.of(context).lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.name.toUpperCase(),
                          style: BunkTheme.of(
                            context,
                          ).bodyBold.copyWith(fontSize: 24),
                        ),
                        if (faculty.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            faculty,
                            style: BunkTheme.of(context).body.copyWith(
                              color: BunkTheme.of(context).grey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(stats.percentage * 100).toStringAsFixed(1)}%',
                              style: BunkTheme.of(context).bodyBold.copyWith(
                                fontSize: 36,
                                color: progressColor,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                'Attendance',
                                style: BunkTheme.of(context).body.copyWith(
                                  color: BunkTheme.of(context).grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // if (faculty.isNotEmpty)
                        // _buildDetailRow(context, 'Faculty', faculty),
                        _buildDetailRow(
                          context,
                          'Total Classes',
                          stats.totalClasses.toString(),
                        ),
                        _buildDetailRow(
                          context,
                          'Classes Held',
                          stats.heldClasses.toString(),
                        ),
                        _buildDetailRow(
                          context,
                          'Attended',
                          stats.attended.toString(),
                        ),
                        _buildDetailRow(
                          context,
                          'Missed',
                          stats.skipped.toString(),
                          textColor: BunkTheme.of(context).red,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          context,
                          'Skip Balance',
                          '${stats.skipBalance} classes',
                          Icons.event_available,
                        ),
                        const SizedBox(height: 12),

                        // _buildInfoCard(
                        //   context,
                        //   'To reach ${(desiredPercentage * 100).round()}%',
                        //   '${stats.classesToAttend} classes in a row',
                        //   Icons.trending_up,
                        // ),
                        const SizedBox(height: 24),
                        Text(
                          'Missed Dates',
                          style: BunkTheme.of(
                            context,
                          ).bodyBold.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<DateTime>>(
                          future: fetchMissedDates(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final missedDatesList = snapshot.data ?? [];

                            if (missedDatesList.isEmpty) {
                              return Text(
                                'No missed classes for this subject!',
                                style: BunkTheme.of(context).body.copyWith(
                                  color: BunkTheme.of(context).green,
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List<Widget>.generate(
                                missedDatesList.length,
                                (index) {
                                  return Column(
                                    children: [
                                      if (index > 0) const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.event_busy,
                                              color: BunkTheme.of(context).red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                formatDate(
                                                  missedDatesList[index],
                                                ),
                                                style: BunkTheme.of(
                                                  context,
                                                ).body,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: BunkTheme.of(
              context,
            ).body.copyWith(color: BunkTheme.of(context).grey, fontSize: 16),
          ),
          Text(
            value,
            style: BunkTheme.of(
              context,
            ).body.copyWith(fontSize: 16, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BunkTheme.of(context).background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BunkTheme.of(context).lightGrey),
      ),
      child: Row(
        children: [
          Icon(icon, color: BunkTheme.of(context).black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BunkTheme.of(context).body.copyWith(
                    color: BunkTheme.of(context).grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: BunkTheme.of(context).bodyBold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BunkTheme.of(context).white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BunkTheme.of(context).lightGrey),
      ),
      child: Text(
        text,
        style: BunkTheme.of(
          context,
        ).body.copyWith(fontSize: 12, color: BunkTheme.of(context).grey),
      ),
    );
  }
}
