import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bunk/state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsState attendance mode tests', () {
    test('SettingsState defaults and copyWith', () {
      final now = DateTime.now();
      final state = SettingsState(startDate: now, endDate: now);
      expect(state.showCurrentAttendance, false);
      expect(state.hasSeenAttendanceTogglePrompt, false);

      final updated = state.copyWith(
        showCurrentAttendance: true,
        hasSeenAttendanceTogglePrompt: true,
      );
      expect(updated.showCurrentAttendance, true);
      expect(updated.hasSeenAttendanceTogglePrompt, true);
    });

    test('SettingsState serialization round-trip', () {
      final now = DateTime.now();
      final state = SettingsState(
        startDate: now,
        endDate: now,
        showCurrentAttendance: true,
        hasSeenAttendanceTogglePrompt: true,
      );
      final json = state.toJson();
      expect(json['showCurrentAttendance'], true);
      expect(json['hasSeenAttendanceTogglePrompt'], true);

      final deserialized = SettingsState.fromJson(json);
      expect(deserialized.showCurrentAttendance, true);
      expect(deserialized.hasSeenAttendanceTogglePrompt, true);
    });
  });

  group('Attendance calculation tests', () {
    test(
      'Batch subject bunk updates preserve other records and persist',
      () async {
        final startDate = DateTime(2026, 1, 1);
        final notifier = BunkedClassesNotifier();
        await notifier.initialize(startDate);
        notifier.state = {
          1: {'Maths', 'Physics'},
          2: {'Physics'},
        };

        notifier.setBunksForSubject([1], 'Maths', bunked: false);
        notifier.setBunksForSubject([3], 'Maths', bunked: true);

        expect(notifier.state, {
          1: {'Physics'},
          2: {'Physics'},
          3: {'Maths'},
        });

        await Future<void>.delayed(const Duration(milliseconds: 600));
        final prefs = await SharedPreferences.getInstance();
        final persistedBunks = prefs.getString('bunked_classes_data')!;
        expect(persistedBunks, contains('2026-01-01'));
        expect(persistedBunks, contains('2026-01-03'));
        expect(persistedBunks, contains('Physics'));
        expect(persistedBunks, contains('Maths'));
      },
    );

    test('Calculates overall attendance vs current attendance correctly', () {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) => SettingsNotifier(ref)),
          scheduleDataProvider.overrideWithValue(
            ScheduleData(
              {
                1: [ClassSlot(name: 'Maths', timeRange: '9-10 AM')],
                2: [ClassSlot(name: 'Maths', timeRange: '9-10 AM')],
                3: [ClassSlot(name: 'Maths', timeRange: '9-10 AM')],
                4: [ClassSlot(name: 'Maths', timeRange: '9-10 AM')],
              },
              {
                'Maths': Subject(
                  'Maths',
                  4,
                  0,
                  heldClasses: 0,
                  faculty: 'Prof X',
                ),
              },
            ),
          ),
          bunkedProvider.overrideWith((ref) {
            final notifier = BunkedClassesNotifier();
            // Bunk day 1
            notifier.state = {
              1: {'Maths'},
            };
            return notifier;
          }),
        ],
      );

      // Set todayDay = 2 (so 2 classes held, 1 bunked, 4 total classes planned)
      container.read(uiProvider.notifier).setTodayDay(2);

      // Default: overall attendance (total: 4, missed: 1 => 3/4 = 75%)
      final overallStats = container.read(attendanceStatsProvider);
      expect(overallStats.totalClasses, 4);
      expect(overallStats.classesHeld, 2);
      expect(overallStats.missed, 1);
      expect(overallStats.classesAttended, 1);
      expect(overallStats.attendance, 0.75); // (4 - 1) / 4 = 75%

      final filteredOverall = container.read(filteredStatsProvider);
      expect(filteredOverall.attendance, 0.75);
      expect(filteredOverall.subjectStats.first.percentage, 0.75);

      // Switch to current attendance (held: 2, missed: 1 => 1/2 = 50%)
      container.read(settingsProvider.notifier).setShowCurrentAttendance(true);

      final currentStats = container.read(attendanceStatsProvider);
      expect(currentStats.attendance, 0.50); // (2 - 1) / 2 = 50%

      final filteredCurrent = container.read(filteredStatsProvider);
      expect(filteredCurrent.attendance, 0.50);
      expect(filteredCurrent.subjectStats.first.percentage, 0.50);
    });
  });
}
