import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bunk/theme/bunk_theme.dart';
import 'package:bunk/screens/onboarding/pages/details_page.dart';
import 'package:bunk/screens/home_screen.dart';
import 'package:bunk/screens/settings_screen.dart';
import 'package:bunk/state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
    ProviderContainer? container,
  }) {
    return ProviderScope(
      parent: container,
      child: BunkTheme(
        data: BunkThemeData.fromName('Light'),
        child: CupertinoApp(
          home: child,
        ),
      ),
    );
  }

  testWidgets('DetailsPage displays CURRENT ATTENDANCE switch and info box', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();

    await tester.pumpWidget(
      createTestWidget(
        child: DetailsPage(onNext: () {}),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    final titleFinder = find.text('CURRENT ATTENDANCE');
    await tester.ensureVisible(titleFinder);
    await tester.pumpAndSettle();

    expect(titleFinder, findsOneWidget);
    expect(
      find.text(
        'When enabled, attendance % is calculated from classes held up to today. When disabled, overall attendance projects across all semester classes.',
      ),
      findsOneWidget,
    );

    // Toggle switch
    final switchFinder = find.byType(CupertinoSwitch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).showCurrentAttendance, true);
  });

  testWidgets('SettingsScreen displays CURRENT ATTENDANCE switch and updates state', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();

    await tester.pumpWidget(
      createTestWidget(
        child: const SettingsScreen(),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    final titleFinder = find.text('Current Attendance');
    await tester.ensureVisible(titleFinder);
    await tester.pumpAndSettle();

    expect(titleFinder, findsOneWidget);

    // Find the toggle
    final switches = find.byType(CupertinoSwitch);
    expect(switches, findsWidgets);

    await tester.tap(switches.first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).showCurrentAttendance, true);
  });

  testWidgets('HomeScreen shows announcement popup for pre-existing users and allows action', (tester) async {
    final container = ProviderContainer();
    // Simulate pre-existing user who has not seen the prompt
    final now = DateTime.now();
    container.read(settingsProvider.notifier).state = SettingsState(
      isFirstLaunch: false,
      hasSeenAttendanceTogglePrompt: false,
      startDate: now,
      endDate: now,
    );

    await tester.pumpWidget(
      createTestWidget(
        child: const HomeScreen(),
        container: container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW: ATTENDANCE MODES'), findsOneWidget);
    expect(find.text('Switch to Current'), findsOneWidget);
    expect(find.text('Keep Overall'), findsOneWidget);

    // Tap "Switch to Current"
    await tester.tap(find.text('Switch to Current'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).showCurrentAttendance, true);
    expect(container.read(settingsProvider).hasSeenAttendanceTogglePrompt, true);
    expect(find.text('NEW: ATTENDANCE MODES'), findsNothing);
  });
}
