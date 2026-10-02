import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bunk/state.dart';
import 'package:bunk/screens/settings_screen.dart';
import 'package:bunk/screens/home_screen.dart';
import 'package:bunk/theme/bunk_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Contact Us SettingsState tests', () {
    test('SettingsState defaults and copyWith for hasSeenContactUsPrompt', () {
      final now = DateTime.now();
      final state = SettingsState(startDate: now, endDate: now);
      expect(state.hasSeenContactUsPrompt, false);

      final updated = state.copyWith(hasSeenContactUsPrompt: true);
      expect(updated.hasSeenContactUsPrompt, true);
    });

    test('SettingsState serialization round-trip for hasSeenContactUsPrompt', () {
      final now = DateTime.now();
      final state = SettingsState(
        startDate: now,
        endDate: now,
        hasSeenContactUsPrompt: true,
      );
      final json = state.toJson();
      expect(json['hasSeenContactUsPrompt'], true);

      final deserialized = SettingsState.fromJson(json);
      expect(deserialized.hasSeenContactUsPrompt, true);
    });

    test('SettingsNotifier setHasSeenContactUsPrompt updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(settingsProvider).hasSeenContactUsPrompt, false);

      await notifier.setHasSeenContactUsPrompt(true);
      expect(container.read(settingsProvider).hasSeenContactUsPrompt, true);
    });
  });

  group('SettingsScreen Contact Us widget tests', () {
    testWidgets('Displays Contact Us tile in settings screen and opens bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) => SettingsNotifier(ref)),
          holidaysProvider.overrideWith((ref) => HolidaysNotifier()),
          examRangesProvider.overrideWithValue([]),
          currentSemesterProvider.overrideWithValue('Sem 4'),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: BunkTheme(
            data: BunkThemeData.light,
            child: const CupertinoApp(
              localizationsDelegates: [
                DefaultMaterialLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
              ],
              home: SettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Privacy Policy" and "Contact Us" tiles are visible
      expect(find.text('Privacy Policy'), findsOneWidget);
      final contactUsFinder = find.text('Contact Us');
      await tester.ensureVisible(contactUsFinder);
      await tester.pumpAndSettle();
      expect(contactUsFinder, findsOneWidget);

      // Tap Contact Us
      await tester.tap(contactUsFinder);
      await tester.pumpAndSettle();

      // Modal bottom sheet should open with title, email, and button
      expect(find.text('CONTACT US'), findsOneWidget);
      expect(find.text('bunkfounders@gmail.com'), findsOneWidget);
      expect(find.text('SEND SUGGESTION'), findsOneWidget);

      // Attempt to send empty suggestion
      await tester.tap(find.text('SEND SUGGESTION'));
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.text('Please type a suggestion before sending.'), findsOneWidget);

      // Enter a suggestion
      await tester.enterText(
        find.byType(CupertinoTextField).last,
        'Please add support for custom lab groups!',
      );
      await tester.pumpAndSettle();

      // Tap send suggestion
      await tester.tap(find.text('SEND SUGGESTION'));
      await tester.pumpAndSettle();

      // Success view should appear
      expect(find.text('SUGGESTION SENT!'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);

      // Tap DONE to close
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      expect(find.text('CONTACT US'), findsNothing);
    });
  });

  group('HomeScreen Contact Us popup tests', () {
    testWidgets('Shows popup for returning user who has not seen Contact Us prompt', (tester) async {
      final now = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) {
            final notifier = SettingsNotifier(ref);
            notifier.state = SettingsState(
              startDate: now,
              endDate: now.add(const Duration(days: 90)),
              isFirstLaunch: false,
              hasSeenAttendanceTogglePrompt: true,
              hasSeenContactUsPrompt: false,
            );
            return notifier;
          }),
          scheduleDataProvider.overrideWithValue(ScheduleData({}, {})),
          allHolidaysProvider.overrideWithValue(<DateTime>{}),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: BunkTheme(
            data: BunkThemeData.light,
            child: const CupertinoApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check popup dialog appears
      expect(find.text('GOT FEEDBACK? ROAST US'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);

      // Tap Maybe Later
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();

      expect(find.text('GOT FEEDBACK? ROAST US'), findsNothing);
      expect(container.read(settingsProvider).hasSeenContactUsPrompt, true);
    });
  });
}
