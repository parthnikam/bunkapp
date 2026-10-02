import 'package:bunk/main.dart';
import 'package:bunk/state.dart';
import 'package:bunk/theme/bunk_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BunkThemeData Brightness Tests', () {
    test('All theme presets have correct isDark and brightness values', () {
      final darkThemeNames = [
        'Dark',
        'Gruvbox Dark',
        'One Dark',
        'Tokyo Night',
        'Dracula',
      ];

      final lightThemeNames = [
        'Light',
        'Gruvbox Light',
        'One Light',
        'Tokyo Night Light',
        'Dracula Light',
      ];

      for (final name in darkThemeNames) {
        final theme = BunkThemeData.fromName(name);
        expect(theme.isDark, isTrue, reason: '$name should be dark');
        expect(
          theme.brightness,
          equals(Brightness.dark),
          reason: '$name brightness should be dark',
        );
      }

      for (final name in lightThemeNames) {
        final theme = BunkThemeData.fromName(name);
        expect(theme.isDark, isFalse, reason: '$name should be light');
        expect(
          theme.brightness,
          equals(Brightness.light),
          reason: '$name brightness should be light',
        );
      }
    });
  });

  group('BunkApp CupertinoTheme Brightness Integration', () {
    testWidgets('CupertinoTheme inherits Brightness.dark for Gruvbox Dark', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) {
            final notifier = SettingsNotifier(ref);
            notifier.state = SettingsState(
              startDate: DateTime(2026, 1, 1),
              endDate: DateTime(2026, 6, 1),
              activeTheme: 'Gruvbox Dark',
              isFirstLaunch: false,
              hasSeenAttendanceTogglePrompt: true,
              hasSeenContactUsPrompt: true,
            );
            return notifier;
          }),
          appInitProvider.overrideWith((ref) async => true),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BunkApp(),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(AppRoot));
      final cupertinoTheme = CupertinoTheme.of(context);
      expect(cupertinoTheme.brightness, equals(Brightness.dark));
    });

    testWidgets('CupertinoTheme inherits Brightness.light for Light theme', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) {
            final notifier = SettingsNotifier(ref);
            notifier.state = SettingsState(
              startDate: DateTime(2026, 1, 1),
              endDate: DateTime(2026, 6, 1),
              activeTheme: 'Light',
              isFirstLaunch: false,
              hasSeenAttendanceTogglePrompt: true,
              hasSeenContactUsPrompt: true,
            );
            return notifier;
          }),
          appInitProvider.overrideWith((ref) async => true),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BunkApp(),
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(AppRoot));
      final cupertinoTheme = CupertinoTheme.of(context);
      expect(cupertinoTheme.brightness, equals(Brightness.light));
    });
  });
}
