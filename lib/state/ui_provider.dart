import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'utils.dart';

class UiNotifier extends StateNotifier<UiState> {
  UiNotifier() : super(const UiState());

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final filter = prefs.getString('statsFilter') ?? 'Overall';
    state = state.copyWith(statsFilter: filter);
  }

  void setTab(int index) => state = state.copyWith(currentTab: index);

  void setStatsFilter(String filter) async {
    state = state.copyWith(statsFilter: filter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('statsFilter', filter);
  }

  void selectDay(int day) => state = state.copyWith(selectedDay: day);
  void setTodayDay(int day) => state = state.copyWith(todayDay: day);

  /// Recompute which semester day-index corresponds to the real calendar today.
  void syncTodayDay({required DateTime startDate, required DateTime endDate}) {
    final dayIndex = computeTodayDayIndex(startDate, endDate);
    state = state.copyWith(todayDay: dayIndex, selectedDay: dayIndex);
  }
}

final uiProvider = StateNotifierProvider<UiNotifier, UiState>(
  (ref) => UiNotifier(),
);
