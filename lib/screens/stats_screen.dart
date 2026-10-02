import 'package:bunk/widgets/subject_stats_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state.dart';
import '../theme/bunk_theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _filters = ['Overall', 'This Month', 'This Week'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow watches so scrolling / tab switches don't rebuild this tree
    // with fresh Subject instances and re-running list layout.
    final statsFilter = ref.watch(uiProvider.select((s) => s.statsFilter));
    final stats = ref.watch(filteredStatsProvider);
    final subjectCount = stats.subjectStats.length;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLargeScreen = screenWidth >= 410;
    final isCompactScreen = screenWidth < 375;

    final horizontalPadding = isCompactScreen ? 16.0 : 24.0;
    final filterFontSize = isLargeScreen
        ? 14.0
        : (isCompactScreen ? 12.0 : 13.0);
    final filterPaddingH = isLargeScreen
        ? 16.0
        : (isCompactScreen ? 8.0 : 12.0);
    final filterPaddingV = isCompactScreen ? 6.0 : 8.0;

    final statNumberFontSize = isLargeScreen
        ? 48.0
        : (isCompactScreen ? 36.0 : 42.0);
    final statLabelFontSize = isLargeScreen
        ? 12.0
        : (isCompactScreen ? 10.0 : 11.0);

    // header(1) + filters(1) + summary(1) + spacing+title(1) + subjects + bottom pad
    final itemCount = 4 + subjectCount + 1;

    return SafeArea(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'STATISTICS',
                      style: BunkTheme.of(context).display,
                    ),
                  ),
                ),
              ],
            );
          }
          if (index == 1) {
            return Padding(
              padding: EdgeInsets.only(
                top: isCompactScreen ? 16 : 24,
                bottom: isCompactScreen ? 16 : 24,
              ),
              child: Row(
                children: _filters.map((filter) {
                  final isActive = statsFilter == filter;
                  return Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(uiProvider.notifier).setStatsFilter(filter);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(
                            horizontal: filterPaddingH,
                            vertical: filterPaddingV,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? BunkTheme.of(context).black
                                : CupertinoColors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              filter.toUpperCase(),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: BunkTheme.of(context).body.copyWith(
                                color: isActive
                                    ? BunkTheme.of(context).white
                                    : BunkTheme.of(context).grey,
                                fontSize: filterFontSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }
          if (index == 2) {
            final showCurrent = ref.watch(
              settingsProvider.select((s) => s.showCurrentAttendance),
            );
            return Row(
              children: [
                _buildStatColumn(
                  context,
                  showCurrent ? 'HELD' : 'CLASSES',
                  showCurrent ? stats.held : stats.total,
                  numberFontSize: statNumberFontSize,
                  labelFontSize: statLabelFontSize,
                ),
                _buildStatColumn(
                  context,
                  'ATTENDED',
                  stats.attended,
                  numberFontSize: statNumberFontSize,
                  labelFontSize: statLabelFontSize,
                ),
                _buildStatColumn(
                  context,
                  'MISSED',
                  stats.missed,
                  isDestructive: true,
                  numberFontSize: statNumberFontSize,
                  labelFontSize: statLabelFontSize,
                ),
              ],
            );
          }
          if (index == 3) {
            return Padding(
              padding: EdgeInsets.only(
                top: isCompactScreen ? 32 : 48,
                bottom: isCompactScreen ? 12 : 16,
              ),
              child: Text('SUBJECT-WISE', style: BunkTheme.of(context).h2),
            );
          }
          final subjectIndex = index - 4;
          if (subjectIndex >= 0 && subjectIndex < subjectCount) {
            final sub = stats.subjectStats[subjectIndex];
            return RepaintBoundary(
              child: SubjectStatsCard(
                key: ValueKey('subject-${sub.name}-${stats.filter}'),
                stats: sub,
                desiredPercentage: stats.desiredPercentage,
                statsFilter: stats.filter,
              ),
            );
          }
          return const SizedBox(height: 100);
        },
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    int value, {
    bool isDestructive = false,
    required double numberFontSize,
    required double labelFontSize,
  }) {
    // Static numbers — no TweenAnimationBuilder. Count-up animations restarted
    // from 0 whenever the row left and re-entered the viewport (grey/jitter).
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: BunkTheme.of(context).display.copyWith(
                fontSize: numberFontSize,
                color: isDestructive
                    ? CupertinoColors.destructiveRed
                    : BunkTheme.of(context).black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: BunkTheme.of(context).body.copyWith(
                color: BunkTheme.of(context).grey,
                fontSize: labelFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
