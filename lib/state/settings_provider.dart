import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'utils.dart';
import 'ui_provider.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const collegeDepartments = {
    'MAHE': ['MIT', 'MLS', 'DLHS', 'DOC'],
  };

  static List<String> get availableColleges => collegeDepartments.keys.toList();

  final Ref _ref;
  Timer? _saveTimer;

  SettingsNotifier(this._ref)
    : super(SettingsState(startDate: DateTime.now(), endDate: DateTime.now()));

  void _syncTodayDay(DateTime start, DateTime end) {
    _ref.read(uiProvider.notifier).syncTodayDay(startDate: start, endDate: end);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveNow();
    });
  }

  Future<void> _saveNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_data', jsonEncode(state.toJson()));
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('profile_data');
    if (data != null) {
      try {
        state = SettingsState.fromJson(
          jsonDecode(data),
        ).copyWith(isInitialized: true);
      } catch (_) {}
    } else {
      state = state.copyWith(isInitialized: true);
    }

    final yearStartStr =
        prefs.getString('current_sem_start_date') ??
        prefs.getString('year_start_date');
    final yearEndStr =
        prefs.getString('current_sem_end_date') ??
        prefs.getString('year_end_date');
    if (yearStartStr != null && yearEndStr != null) {
      final startDate = dateOnly(
        tryParseDate(yearStartStr) ?? state.startDate,
      );
      final endDate = dateOnly(tryParseDate(yearEndStr) ?? state.endDate);
      state = state.copyWith(startDate: startDate, endDate: endDate);
    }
  }

  void setTheme(String theme) {
    state = state.copyWith(activeTheme: theme);
    _scheduleSave();
  }

  Future<void> completeOnboarding(
    String newName,
    String newYear,
    String newCollegeName,
    String newDepartment,
    String newSection,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final yearStart =
        prefs.getString('current_sem_start_date') ??
        prefs.getString('year_start_date');
    final yearEnd =
        prefs.getString('current_sem_end_date') ??
        prefs.getString('year_end_date');
    final start = dateOnly(tryParseDate(yearStart) ?? state.startDate);
    final end = dateOnly(tryParseDate(yearEnd) ?? state.endDate);

    state = state.copyWith(
      isFirstLaunch: false,
      hasSeenAttendanceTogglePrompt: true,
      hasSeenContactUsPrompt: true,
      hasSeenLongWeekendsPrompt: true,
      name: newName,
      collegeName: newCollegeName,
      department: newDepartment,
      year: newYear,
      selectedSection: newSection,
      startDate: start,
      endDate: end,
    );
    await prefs.setString('selected_section', newSection);
    await _saveNow(); // Immediate save for onboarding
    _syncTodayDay(start, end);
  }

  Future<void> setStartDate(DateTime date) async {
    state = state.copyWith(startDate: dateOnly(date));
    await _saveNow();
    _syncTodayDay(state.startDate, state.endDate);
  }

  Future<void> setEndDate(DateTime date) async {
    state = state.copyWith(endDate: dateOnly(date));
    await _saveNow();
    _syncTodayDay(state.startDate, state.endDate);
  }

  void setNotificationsEnabled(bool val) {
    state = state.copyWith(notificationsEnabled: val);
    _scheduleSave();
  }

  void setDesiredPercentage(double val) {
    state = state.copyWith(desiredPercentage: val);
    _scheduleSave();
  }

  void setShowCurrentAttendance(bool val) {
    state = state.copyWith(showCurrentAttendance: val);
    _scheduleSave();
  }

  Future<void> setHasSeenAttendanceTogglePrompt(bool val) async {
    state = state.copyWith(hasSeenAttendanceTogglePrompt: val);
    await _saveNow();
  }

  Future<void> setHasSeenContactUsPrompt(bool val) async {
    state = state.copyWith(hasSeenContactUsPrompt: val);
    await _saveNow();
  }

  Future<void> setHasSeenLongWeekendsPrompt(bool val) async {
    state = state.copyWith(hasSeenLongWeekendsPrompt: val);
    await _saveNow();
  }

  Future<void> setSection(String section) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_section', section);
    state = state.copyWith(selectedSection: section);
    await _saveNow();
  }

  Future<void> setCollegeName(String collegeName) async {
    final departments = collegeDepartments[collegeName] ?? const ['MIT'];
    final defaultDept = departments.first;
    const defaultYear = '1st Year';
    const defaultSection = 'A Section';
    state = state.copyWith(
      collegeName: collegeName,
      department: defaultDept,
      year: defaultYear,
      selectedSection: defaultSection,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_section', defaultSection);
    _scheduleSave();
  }

  Future<void> setDepartment(String department) async {
    const defaultYear = '1st Year';
    const defaultSection = 'A Section';
    state = state.copyWith(
      department: department,
      year: defaultYear,
      selectedSection: defaultSection,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_section', defaultSection);
    _scheduleSave();
  }

  Future<void> setYear(String year) async {
    const defaultSection = 'A Section';
    state = state.copyWith(
      year: year,
      selectedSection: defaultSection,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_section', defaultSection);
    _scheduleSave();
  }

  Future<void> setName(String name) async {
    state = state.copyWith(name: name);
    _scheduleSave();
  }

  Future<void> resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = SettingsState(
      isFirstLaunch: true,
      isInitialized: true,
      collegeName: 'MAHE',
      department: 'MIT',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      showCurrentAttendance: false,
      hasSeenAttendanceTogglePrompt: false,
      hasSeenContactUsPrompt: false,
      hasSeenLongWeekendsPrompt: false,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref);
  },
);
