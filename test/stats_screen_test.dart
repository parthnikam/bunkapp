import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bunk/theme/bunk_theme.dart';
import 'package:bunk/screens/stats_screen.dart';
import 'package:bunk/state.dart';
import 'package:bunk/widgets/subject_stats_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createStatsScreen({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: BunkTheme(
        data: BunkThemeData.fromName('Light'),
        child: const CupertinoApp(home: StatsScreen()),
      ),
    );
  }

  group('StatsScreen Layout & Alignment Tests', () {
    testWidgets('Tapping outside an open subject stat dismisses its details', (
      tester,
    ) async {
      const subjectStats = SubjectStatSummary(
        name: 'Math',
        faculty: '',
        totalClasses: 10,
        heldClasses: 10,
        skipped: 1,
        attended: 9,
        percentage: 0.9,
        skipBalance: 4,
        classesToAttend: 0,
      );
      final schedule = ScheduleData(
        {
          for (var day = 1; day <= 10; day++)
            day: [ClassSlot(name: 'Math', timeRange: '9-10 AM')],
        },
        {'Math': Subject('Math', 10, 1, heldClasses: 10)},
      );
      final container = ProviderContainer(
        overrides: [scheduleDataProvider.overrideWithValue(schedule)],
      );
      final bunkedNotifier = container.read(bunkedProvider.notifier);
      await bunkedNotifier.initialize(DateTime(2026, 1, 1));
      bunkedNotifier.state = {
        1: {'Math'},
      };
      container.read(uiProvider.notifier).setTodayDay(10);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: BunkTheme(
            data: BunkThemeData.fromName('Light'),
            child: MaterialApp(
              home: Scaffold(
                body: SubjectStatsCard(
                  stats: subjectStats,
                  desiredPercentage: 0.75,
                  statsFilter: 'Overall',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('MATH'));
      await tester.pumpAndSettle();

      expect(find.text('Missed Dates'), findsOneWidget);

      final percentagePosition = tester.getCenter(find.text('90.0%').last);
      await tester.tapAt(percentagePosition);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(percentagePosition);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '80');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Attendance updated'), findsOneWidget);
      expect(bunkedNotifier.state[10], contains('Math'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('80.0%').last, findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Missed Dates'), findsNothing);
      container.dispose();
    });

    testWidgets(
      'Filters and stats columns are horizontally aligned with each other',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();

        await tester.pumpWidget(createStatsScreen(container: container));
        await tester.pumpAndSettle();

        // Find filter texts
        final overallFilter = find.text('OVERALL');
        final thisMonthFilter = find.text('THIS MONTH');
        final thisWeekFilter = find.text('THIS WEEK');

        expect(overallFilter, findsOneWidget);
        expect(thisMonthFilter, findsOneWidget);
        expect(thisWeekFilter, findsOneWidget);

        // With default settings (showCurrentAttendance = false), label is CLASSES
        final totalClassesLabel = find.text('CLASSES');
        final attendedLabel = find.text('ATTENDED');
        final missedLabel = find.text('MISSED');

        expect(totalClassesLabel, findsOneWidget);
        expect(attendedLabel, findsOneWidget);
        expect(missedLabel, findsOneWidget);

        // Verify center X coordinates match between filters and corresponding stats
        final overallCenter = tester.getCenter(overallFilter);
        final totalClassesCenter = tester.getCenter(totalClassesLabel);
        expect((overallCenter.dx - totalClassesCenter.dx).abs(), lessThan(1.0));

        final thisMonthCenter = tester.getCenter(thisMonthFilter);
        final attendedCenter = tester.getCenter(attendedLabel);
        expect((thisMonthCenter.dx - attendedCenter.dx).abs(), lessThan(1.0));

        final thisWeekCenter = tester.getCenter(thisWeekFilter);
        final missedCenter = tester.getCenter(missedLabel);
        expect((thisWeekCenter.dx - missedCenter.dx).abs(), lessThan(1.0));

        // Now toggle showCurrentAttendance to true
        container
            .read(settingsProvider.notifier)
            .setShowCurrentAttendance(true);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        final classesHeldLabel = find.text('HELD');
        expect(classesHeldLabel, findsOneWidget);
        final classesHeldCenter = tester.getCenter(classesHeldLabel);
        expect((overallCenter.dx - classesHeldCenter.dx).abs(), lessThan(1.0));
      },
    );

    testWidgets('Tapping filter switches statsFilter in UI state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();

      await tester.pumpWidget(createStatsScreen(container: container));
      await tester.pumpAndSettle();

      expect(container.read(uiProvider).statsFilter, 'Overall');

      await tester.tap(find.text('THIS MONTH'));
      await tester.pumpAndSettle();

      expect(container.read(uiProvider).statsFilter, 'This Month');

      await tester.tap(find.text('THIS WEEK'));
      await tester.pumpAndSettle();

      expect(container.read(uiProvider).statsFilter, 'This Week');
    });

    for (final size in [
      const Size(320, 568), // Small screen (iPhone SE 1st gen)
      const Size(360, 640), // Compact Android
      const Size(375, 667), // iPhone 8/SE 2
      const Size(390, 844), // iPhone 14
      const Size(430, 932), // iPhone 15 Pro Max
    ]) {
      testWidgets('Renders without overflow on screen width ${size.width}', (
        tester,
      ) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();

        await tester.pumpWidget(createStatsScreen(container: container));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('STATISTICS'), findsOneWidget);
        expect(find.text('OVERALL'), findsOneWidget);
        expect(find.text('THIS MONTH'), findsOneWidget);
        expect(find.text('THIS WEEK'), findsOneWidget);
      });
    }
  });
}
