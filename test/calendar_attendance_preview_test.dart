import 'package:bunk/screens/calendar_screen.dart';
import 'package:bunk/state.dart';
import 'package:bunk/theme/bunk_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget card({
    required int dayIndex,
    required int todayDay,
    required bool showCurrent,
    required ScheduleData schedule,
  }) {
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(ref)
            ..state = SettingsState(
              startDate: DateTime(2026, 8, 3),
              endDate: DateTime(2026, 12, 15),
              showCurrentAttendance: showCurrent,
              isFirstLaunch: false,
              isInitialized: true,
            ),
        ),
        scheduleDataProvider.overrideWithValue(schedule),
        uiProvider.overrideWith(
          (ref) => UiNotifier()
            ..state = UiState(todayDay: todayDay, selectedDay: dayIndex),
        ),
      ],
      child: BunkTheme(
        data: BunkThemeData.light,
        child: CupertinoApp(
          home: Center(
            child: CalendarSubjectCard(
              title: 'Math',
              time: '9:00 - 10:00',
              dayIndex: dayIndex,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('calendar card shows the drop from bunking a held class', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final schedule = ScheduleData(
      {
        1: [ClassSlot(name: 'Math', timeRange: '9:00 - 10:00')],
      },
      {'Math': Subject('Math', 10, 0)},
    );

    await tester.pumpWidget(
      card(
        dayIndex: 1,
        todayDay: 1,
        showCurrent: false,
        schedule: schedule,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);

    await tester.tap(find.text('BUNK'));
    await tester.pumpAndSettle();

    expect(find.text('BUNKED!'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('future class in current mode adds the class to held and missed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Day 1 is today (already held). Day 2 has not been held yet.
    final schedule = ScheduleData(
      {
        1: [ClassSlot(name: 'Math', timeRange: '9:00 - 10:00')],
        2: [ClassSlot(name: 'Math', timeRange: '9:00 - 10:00')],
      },
      {'Math': Subject('Math', 2, 0)},
    );

    await tester.pumpWidget(
      card(dayIndex: 2, todayDay: 1, showCurrent: true, schedule: schedule),
    );
    await tester.pumpAndSettle();

    // 1/1 held now, bunking the future class makes it 1/2.
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });
}
