import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bunk/state.dart';
import 'package:bunk/screens/home_screen.dart';
import 'package:bunk/screens/calendar_screen.dart';
import 'package:bunk/screens/long_weekends_screen.dart';
import 'package:bunk/theme/bunk_theme.dart';

void main() {
  group('Long Weekends Calculation Logic', () {
    final semesterStart = DateTime(2026, 8, 1);
    final semesterEnd = DateTime(2026, 12, 15);

    test('detects 3-day long weekend when Friday is a holiday', () {
      // 2026-08-14 is a Friday. Sat is 08-15, Sun is 08-16.
      final holidays = {DateTime(2026, 8, 14)};
      final systemHolidays = {DateTime(2026, 8, 14): 'Independence Eve'};

      final results = calculateLongWeekends(
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(results.length, 1);
      final lw = results.first;
      expect(lw.startDate, DateTime(2026, 8, 14));
      expect(lw.endDate, DateTime(2026, 8, 16));
      expect(lw.totalDays, 3);
      expect(lw.bunkDaysCount, 0);
      expect(lw.hasSkippedClasses, isFalse);
      expect(lw.holidayNames, contains('Independence Eve'));
    });

    test('detects 3-day long weekend when Monday is a holiday', () {
      // 2026-08-17 is a Monday. Sat is 08-15, Sun is 08-16.
      final holidays = {DateTime(2026, 8, 17)};
      final systemHolidays = {DateTime(2026, 8, 17): 'Parsi New Year'};

      final results = calculateLongWeekends(
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(results.length, 1);
      final lw = results.first;
      expect(lw.startDate, DateTime(2026, 8, 15));
      expect(lw.endDate, DateTime(2026, 8, 17));
      expect(lw.totalDays, 3);
      expect(lw.bunkDaysCount, 0);
      expect(lw.hasSkippedClasses, isFalse);
      expect(lw.holidayNames, contains('Parsi New Year'));
    });

    test('detects 4-day long weekend when Thursday is a holiday (skipping Friday)', () {
      // 2026-08-13 is Thursday. Friday 08-14 is working day. Sat 08-15, Sun 08-16.
      final holidays = {DateTime(2026, 8, 13)};
      final systemHolidays = {DateTime(2026, 8, 13): 'Janmashtami'};

      final results = calculateLongWeekends(
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(results.length, 1);
      final lw = results.first;
      expect(lw.startDate, DateTime(2026, 8, 13));
      expect(lw.endDate, DateTime(2026, 8, 16));
      expect(lw.totalDays, 4);
      expect(lw.bunkDaysCount, 1);
      expect(lw.hasSkippedClasses, isTrue);
      expect(lw.bunkDates, contains(DateTime(2026, 8, 14))); // Friday
      expect(lw.holidayNames, contains('Janmashtami'));
    });

    test('detects 4-day long weekend when Tuesday is a holiday (skipping Monday)', () {
      // Sat 08-15, Sun 08-16, Mon 08-17 is working, Tue 08-18 is holiday.
      final holidays = {DateTime(2026, 8, 18)};
      final systemHolidays = {DateTime(2026, 8, 18): 'Regional Holiday'};

      final results = calculateLongWeekends(
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(results.length, 1);
      final lw = results.first;
      expect(lw.startDate, DateTime(2026, 8, 15));
      expect(lw.endDate, DateTime(2026, 8, 18));
      expect(lw.totalDays, 4);
      expect(lw.bunkDaysCount, 1);
      expect(lw.hasSkippedClasses, isTrue);
      expect(lw.bunkDates, contains(DateTime(2026, 8, 17))); // Monday
      expect(lw.holidayNames, contains('Regional Holiday'));
    });

    test('detects 6-day long weekend with Thursday and Tuesday holidays', () {
      // Thu 08-13 (H), Fri 08-14 (Bunk), Sat 08-15, Sun 08-16, Mon 08-17 (Bunk), Tue 08-18 (H)
      final holidays = {DateTime(2026, 8, 13), DateTime(2026, 8, 18)};
      final systemHolidays = {
        DateTime(2026, 8, 13): 'Festival A',
        DateTime(2026, 8, 18): 'Festival B',
      };

      final results = calculateLongWeekends(
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(results.length, 1);
      final lw = results.first;
      expect(lw.startDate, DateTime(2026, 8, 13));
      expect(lw.endDate, DateTime(2026, 8, 18));
      expect(lw.totalDays, 6);
      expect(lw.bunkDaysCount, 2);
      expect(lw.bunkDates, [DateTime(2026, 8, 14), DateTime(2026, 8, 17)]);
    });

    test('does not form long weekend if bunk day is an exam day', () {
      // Thursday 08-13 is holiday, but Friday 08-14 is an EXAM day!
      // Student cannot skip class on exam days, so no long weekend is formed.
      final holidays = {DateTime(2026, 8, 13)};
      final systemHolidays = {DateTime(2026, 8, 13): 'Janmashtami'};
      final exams = {DateTime(2026, 8, 14): 'Mid Term Exam'};

      final results = calculateLongWeekends(
        holidays: holidays,
        systemHolidays: systemHolidays,
        exams: exams,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(results.isEmpty, isTrue);
    });

    test('does not form long weekend if post-weekend bunk day is an exam day', () {
      // Tuesday 08-18 is holiday, but Monday 08-17 is an EXAM day!
      final holidays = {DateTime(2026, 8, 18)};
      final systemHolidays = {DateTime(2026, 8, 18): 'Holiday'};
      final exams = {DateTime(2026, 8, 17): 'End Term Exam'};

      final results = calculateLongWeekends(
        holidays: holidays,
        systemHolidays: systemHolidays,
        exams: exams,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(results.isEmpty, isTrue);
    });

    test('filters long weekends by month accurately', () {
      // Aug long weekend + Oct long weekend
      final holidays = {
        DateTime(2026, 8, 14), // Friday in Aug
        DateTime(2026, 10, 2), // Friday in Oct
      };
      final systemHolidays = {
        DateTime(2026, 8, 14): 'Aug Holiday',
        DateTime(2026, 10, 2): 'Gandhi Jayanti',
      };

      final augWeekends = calculateLongWeekendsForMonth(
        month: DateTime(2026, 8, 1),
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );

      expect(augWeekends.length, 1);
      expect(augWeekends.first.holidayNames, contains('Aug Holiday'));

      final sepWeekends = calculateLongWeekendsForMonth(
        month: DateTime(2026, 9, 1),
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );
      expect(sepWeekends.isEmpty, isTrue);

      final octWeekends = calculateLongWeekendsForMonth(
        month: DateTime(2026, 10, 1),
        holidays: holidays,
        systemHolidays: systemHolidays,
        startDate: semesterStart,
        endDate: semesterEnd,
      );
      expect(octWeekends.length, 1);
      expect(octWeekends.first.holidayNames, contains('Gandhi Jayanti'));
    });
  });

  group('Attendance Impact Calculation', () {
    test('calculates exact overall and subject percentage drop', () {
      final semesterStart = DateTime(2026, 8, 1);
      // Tuesday 2026-08-18 is holiday -> Bunk Monday 2026-08-17 (Day index 17)
      final lw = LongWeekend(
        title: 'Test Weekend',
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 8, 18),
        days: [
          LongWeekendDay(date: DateTime(2026, 8, 15), isWeekend: true, isHoliday: false, isBunkDay: false),
          LongWeekendDay(date: DateTime(2026, 8, 16), isWeekend: true, isHoliday: false, isBunkDay: false),
          LongWeekendDay(date: DateTime(2026, 8, 17), isWeekend: false, isHoliday: false, isBunkDay: true),
          LongWeekendDay(date: DateTime(2026, 8, 18), isWeekend: false, isHoliday: true, isBunkDay: false),
        ],
        holidayDates: [DateTime(2026, 8, 18)],
        bunkDates: [DateTime(2026, 8, 17)],
        holidayNames: ['Test Holiday'],
      );

      final schedule = <int, List<ClassSlot>>{
        17: [
          ClassSlot(name: 'Math', timeRange: '09:00 - 10:00'),
          ClassSlot(name: 'Physics', timeRange: '10:00 - 11:00'),
        ],
      };
      final subjects = <String, Subject>{
        'Math': Subject('Math', 20, 2, heldClasses: 10, faculty: 'Prof. A'),
        'Physics': Subject('Physics', 20, 0, heldClasses: 10, faculty: 'Prof. B'),
      };
      final scheduleData = ScheduleData(schedule, subjects);

      final overallStats = AttendanceStats(
        totalClasses: 40,
        classesHeld: 20,
        missed: 2,
        classesAttended: 18,
        attendance: 38 / 40, // 95%
        safeBunks: 8,
        dailyHistory: [0.95],
        trend: 0.0,
      );

      final impact = calculateLongWeekendImpact(
        longWeekend: lw,
        scheduleData: scheduleData,
        computedSubjects: subjects,
        overallStats: overallStats,
        bunkedClasses: {},
        semesterStartDate: semesterStart,
        desiredPercentage: 0.75,
        showCurrentAttendance: false,
      );

      expect(impact.totalClassesSkipped, 2);
      expect(impact.currentOverallAttendance, 0.95);
      // New attendance = (40 - (2 + 2)) / 40 = 36 / 40 = 0.90 (90%)
      expect(impact.projectedOverallAttendance, 0.90);
      expect(impact.overallPercentageDrop, closeTo(5.0, 0.01));
      expect(impact.isSafe, isTrue);

      expect(impact.bunkDays.length, 1);
      final bunkDay = impact.bunkDays.first;
      expect(bunkDay.classes.length, 2);

      final mathImpact = bunkDay.classes.firstWhere((c) => c.subjectName == 'Math');
      expect(mathImpact.currentPercentage, (20 - 2) / 20); // 90%
      expect(mathImpact.projectedPercentage, (20 - 3) / 20); // 85%
      expect(mathImpact.percentageDrop, closeTo(5.0, 0.01));
    });
  });

  group('UI Integration Tests', () {
    testWidgets('CalendarScreen displays long weekend link and opens LongWeekendsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final startDate = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 11, 30);
      // Friday Aug 14 is holiday
      final holidays = {DateTime(2026, 8, 14)};
      final systemHolidays = {DateTime(2026, 8, 14): 'Independence Eve'};

      final scheduleData = ScheduleData({}, {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(ref)..state = SettingsState(
                startDate: startDate,
                endDate: endDate,
                isFirstLaunch: false,
                isInitialized: true,
              ),
            ),
            allHolidaysProvider.overrideWithValue(holidays),
            systemHolidaysProvider.overrideWithValue(systemHolidays),
            scheduleDataProvider.overrideWithValue(scheduleData),
            uiProvider.overrideWith(
              (ref) => UiNotifier()..state = const UiState(
                selectedDay: 14,
                todayDay: 1,
                currentTab: 1,
              ),
            ),
          ],
          child: const BunkTheme(
            data: BunkThemeData.light,
            child: CupertinoApp(
              home: CalendarScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the link under the calendar and scroll to it if needed
      final linkFinder = find.text('1 Long weekend this month');
      await tester.ensureVisible(linkFinder);
      expect(linkFinder, findsOneWidget);

      // Tap link to navigate to LongWeekendsScreen
      await tester.tap(linkFinder);
      await tester.pumpAndSettle();

      // Verify LongWeekendsScreen is visible with direct details
      expect(find.text('LONG WEEKENDS'), findsOneWidget);
      expect(find.text('AUGUST 2026'), findsOneWidget);
      expect(find.text('Independence Eve Weekend'), findsOneWidget);
      expect(find.text('No classes to be skipped'), findsOneWidget);
    });

    testWidgets('LongWeekendsScreen renders with skipped classes and attendance drop', (tester) async {
      final startDate = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 11, 30);
      // Thursday Aug 13 is holiday -> Bunk Friday Aug 14
      final holidays = {DateTime(2026, 8, 13)};
      final systemHolidays = {DateTime(2026, 8, 13): 'Janmashtami'};

      final schedule = <int, List<ClassSlot>>{
        14: [
          ClassSlot(name: 'Data Structures', timeRange: '09:00 - 10:00'),
          ClassSlot(name: 'Algorithms', timeRange: '10:00 - 11:00'),
        ],
      };
      final subjects = <String, Subject>{
        'Data Structures': Subject('Data Structures', 20, 0, heldClasses: 10, faculty: 'Dr. Smith'),
        'Algorithms': Subject('Algorithms', 20, 0, heldClasses: 10, faculty: 'Dr. Doe'),
      };
      final scheduleData = ScheduleData(schedule, subjects);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(ref)..state = SettingsState(
                startDate: startDate,
                endDate: endDate,
                desiredPercentage: 0.75,
                isFirstLaunch: false,
                isInitialized: true,
              ),
            ),
            allHolidaysProvider.overrideWithValue(holidays),
            systemHolidaysProvider.overrideWithValue(systemHolidays),
            scheduleDataProvider.overrideWithValue(scheduleData),
          ],
          child: BunkTheme(
            data: BunkThemeData.dark,
            child: CupertinoApp(
              home: LongWeekendsScreen(month: DateTime(2026, 8, 1)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LONG WEEKENDS'), findsOneWidget);
      expect(find.text('Requires skipping Friday'), findsOneWidget);

      // Verify skipped classes directly visible
      expect(find.text('DATA STRUCTURES'), findsOneWidget);
      expect(find.text('ALGORITHMS'), findsOneWidget);
      expect(find.textContaining('09:00 - 10:00'), findsOneWidget);
      expect(find.textContaining('Dr. Smith'), findsOneWidget);
    });

    testWidgets('CalendarScreen displays plural link when multiple long weekends exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final startDate = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 11, 30);
      // Friday Aug 7 & Friday Aug 21
      final holidays = {DateTime(2026, 8, 7), DateTime(2026, 8, 21)};
      final systemHolidays = {
        DateTime(2026, 8, 7): 'Holiday 1',
        DateTime(2026, 8, 21): 'Holiday 2',
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(ref)..state = SettingsState(
                startDate: startDate,
                endDate: endDate,
                isFirstLaunch: false,
                isInitialized: true,
              ),
            ),
            allHolidaysProvider.overrideWithValue(holidays),
            systemHolidaysProvider.overrideWithValue(systemHolidays),
            scheduleDataProvider.overrideWithValue(const ScheduleData({}, {})),
            uiProvider.overrideWith(
              (ref) => UiNotifier()..state = const UiState(
                selectedDay: 1,
                todayDay: 1,
                currentTab: 1,
              ),
            ),
          ],
          child: const BunkTheme(
            data: BunkThemeData.light,
            child: CupertinoApp(
              home: CalendarScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final linkFinder = find.text('2 Long weekends this month');
      await tester.ensureVisible(linkFinder);
      expect(linkFinder, findsOneWidget);
    });

    testWidgets('CalendarScreen does not display link when 0 long weekends in month', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final startDate = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 11, 30);
      // No holidays in Aug
      final holidays = <DateTime>{};
      final systemHolidays = <DateTime, String>{};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(ref)..state = SettingsState(
                startDate: startDate,
                endDate: endDate,
                isFirstLaunch: false,
                isInitialized: true,
              ),
            ),
            allHolidaysProvider.overrideWithValue(holidays),
            systemHolidaysProvider.overrideWithValue(systemHolidays),
            scheduleDataProvider.overrideWithValue(const ScheduleData({}, {})),
            uiProvider.overrideWith(
              (ref) => UiNotifier()..state = const UiState(
                selectedDay: 1,
                todayDay: 1,
                currentTab: 1,
              ),
            ),
          ],
          child: const BunkTheme(
            data: BunkThemeData.light,
            child: CupertinoApp(
              home: CalendarScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Long weekend'), findsNothing);
    });

    testWidgets('LongWeekendsScreen renders cleanly across all themes', (tester) async {
      final holidays = {DateTime(2026, 8, 14)};
      final systemHolidays = {DateTime(2026, 8, 14): 'Independence Eve'};

      for (final themeName in BunkThemeData.allThemes) {
        final themeData = BunkThemeData.fromName(themeName);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(
                (ref) => SettingsNotifier(ref)..state = SettingsState(
                  startDate: DateTime(2026, 8, 1),
                  endDate: DateTime(2026, 11, 30),
                  activeTheme: themeName,
                  isFirstLaunch: false,
                  isInitialized: true,
                ),
              ),
              allHolidaysProvider.overrideWithValue(holidays),
              systemHolidaysProvider.overrideWithValue(systemHolidays),
              scheduleDataProvider.overrideWithValue(const ScheduleData({}, {})),
            ],
            child: BunkTheme(
              data: themeData,
              child: CupertinoApp(
                home: LongWeekendsScreen(month: DateTime(2026, 8, 1)),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('LONG WEEKENDS'), findsOneWidget);
        expect(find.text('AUGUST 2026'), findsOneWidget);
      }
    });

    testWidgets('CalendarScreen paints DashedSpanBorderPainter on long weekend days with continuous span', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final startDate = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 11, 30);
      // Friday Aug 14 is holiday -> Aug 14 (Fri, col 5), Aug 15 (Sat, col 6), Aug 16 (Sun, col 0)
      final holidays = {DateTime(2026, 8, 14)};
      final systemHolidays = {DateTime(2026, 8, 14): 'Independence Eve'};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(
              (ref) => SettingsNotifier(ref)..state = SettingsState(
                startDate: startDate,
                endDate: endDate,
                isFirstLaunch: false,
                isInitialized: true,
              ),
            ),
            allHolidaysProvider.overrideWithValue(holidays),
            systemHolidaysProvider.overrideWithValue(systemHolidays),
            scheduleDataProvider.overrideWithValue(const ScheduleData({}, {})),
            uiProvider.overrideWith(
              (ref) => UiNotifier()..state = const UiState(
                selectedDay: 1,
                todayDay: 1,
                currentTab: 1,
              ),
            ),
          ],
          child: const BunkTheme(
            data: BunkThemeData.light,
            child: CupertinoApp(
              home: CalendarScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find CustomPaint widgets with DashedSpanBorderPainter
      final customPaintFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is DashedSpanBorderPainter,
      );

      // Days 14, 15, 16 should have the dashed rounded span border
      expect(customPaintFinder, findsNWidgets(3));

      // Verify span connection on Friday Aug 14, Saturday Aug 15, and Sunday Aug 16
      final painters = tester.widgetList<CustomPaint>(customPaintFinder).map((cp) => cp.painter as DashedSpanBorderPainter).toList();
      // Aug 14 (Fri, col 5): start of long weekend -> extends right to Saturday
      expect(painters.any((p) => !p.extendLeft && p.extendRight), isTrue);
      // Aug 15 (Sat, col 6): middle of span -> extends left to Friday and right to Sunday
      expect(painters.any((p) => p.extendLeft && p.extendRight), isTrue);
      // Aug 16 (Sun, col 0, new row): end of span -> extends left to Saturday and closes on right
      expect(painters.any((p) => p.extendLeft && !p.extendRight), isTrue);
    });
  });

  group('Long Weekends Prompt Tests', () {
    test('SettingsState defaults and copyWith for hasSeenLongWeekendsPrompt', () {
      final now = DateTime.now();
      final state = SettingsState(startDate: now, endDate: now);
      expect(state.hasSeenLongWeekendsPrompt, false);

      final updated = state.copyWith(hasSeenLongWeekendsPrompt: true);
      expect(updated.hasSeenLongWeekendsPrompt, true);
    });

    test('SettingsState serialization round-trip for hasSeenLongWeekendsPrompt', () {
      final now = DateTime.now();
      final state = SettingsState(
        startDate: now,
        endDate: now,
        hasSeenLongWeekendsPrompt: true,
      );
      final json = state.toJson();
      expect(json['hasSeenLongWeekendsPrompt'], true);

      final deserialized = SettingsState.fromJson(json);
      expect(deserialized.hasSeenLongWeekendsPrompt, true);
    });

    test('SettingsNotifier setHasSeenLongWeekendsPrompt updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(settingsProvider).hasSeenLongWeekendsPrompt, false);

      await notifier.setHasSeenLongWeekendsPrompt(true);
      expect(container.read(settingsProvider).hasSeenLongWeekendsPrompt, true);
    });

    testWidgets('HomeScreen displays Long Weekends popup for normal users and navigates on View Calendar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final startDate = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 12, 15);

      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(ref)..state = SettingsState(
              startDate: startDate,
              endDate: endDate,
              isFirstLaunch: false,
              isInitialized: true,
              hasSeenAttendanceTogglePrompt: true,
              hasSeenContactUsPrompt: true,
              hasSeenLongWeekendsPrompt: false,
            ),
          ),
          allHolidaysProvider.overrideWithValue(const {}),
          systemHolidaysProvider.overrideWithValue(const {}),
          scheduleDataProvider.overrideWithValue(const ScheduleData({}, {})),
          attendanceStatsProvider.overrideWithValue(
            const AttendanceStats(
              totalClasses: 10,
              classesHeld: 10,
              missed: 0,
              classesAttended: 10,
              attendance: 1.0,
              safeBunks: 2,
              dailyHistory: [],
              trend: 0.0,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BunkTheme(
            data: BunkThemeData.dark,
            child: CupertinoApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.text('NEW: LONG WEEKENDS'), findsOneWidget);
      expect(
        find.text(
          'Spot long weekends directly on your calendar and plan your time off with zero guesswork.',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Calendar Outlines'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Attendance Impact'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Exam Protection'),
        ),
        findsOneWidget,
      );

      // Tap 'View Calendar'
      await tester.tap(find.text('View Calendar'));
      await tester.pumpAndSettle();

      // Verify prompt is marked seen and calendar tab selected
      expect(container.read(settingsProvider).hasSeenLongWeekendsPrompt, true);
      expect(container.read(uiProvider).currentTab, 1);
    });
  });
}
