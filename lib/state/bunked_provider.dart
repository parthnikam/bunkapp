import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

class BunkedClassesNotifier extends StateNotifier<Map<int, Set<String>>> {
  Timer? _saveTimer;
  DateTime? _startDate;

  BunkedClassesNotifier() : super({});

  Future<void> initialize(DateTime startDate) async {
    _startDate = startDate;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('bunked_classes_data');
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final list = map['bunked_classes'] as List<dynamic>;

        final newMap = <int, Set<String>>{};
        for (final item in list) {
          final dateStr = item['date'] as String;
          final className = item['class'] as String;
          final parsedDate = DateTime.parse(dateStr);
          final dayIndex = _dayIndexFromDate(startDate, parsedDate);
          if (dayIndex >= 1) {
            newMap.putIfAbsent(dayIndex, () => {}).add(className);
          }
        }
        state = newMap;
        return;
      } catch (e) {
        // Fallback below
      }
    }

    final bunkedList = prefs.getStringList('bunkedClasses') ?? [];
    final newMap = <int, Set<String>>{};
    for (final item in bunkedList) {
      final parts = item.split('-');
      if (parts.length >= 2) {
        final dayIndex = int.tryParse(parts[0]);
        if (dayIndex != null) {
          final className = parts.sublist(1).join('-');
          newMap.putIfAbsent(dayIndex, () => {}).add(className);
        }
      }
    }
    state = newMap;
  }

  void updateStartDate(DateTime newStartDate) {
    if (_startDate != null && !_startDate!.isAtSameMomentAs(newStartDate)) {
      final newMap = <int, Set<String>>{};
      for (final entry in state.entries) {
        final oldDayIndex = entry.key;
        final actualDate = dateFromDayIndex(_startDate!, oldDayIndex);
        final newDayIndex = _dayIndexFromDate(newStartDate, actualDate);
        if (newDayIndex >= 1) {
          newMap[newDayIndex] = Set<String>.from(entry.value);
        }
      }
      state = newMap;
      _startDate = newStartDate;
      _scheduleSave();
    } else {
      _startDate = newStartDate;
    }
  }

  int _dayIndexFromDate(DateTime start, DateTime target) {
    return DateTime(
          target.year,
          target.month,
          target.day,
        ).difference(DateTime(start.year, start.month, start.day)).inDays +
        1;
  }

  void clear() {
    state = {};
    _scheduleSave();
  }

  void toggleBunk(int day, String subject) {
    final newState = Map<int, Set<String>>.from(state);
    final daySet = Set<String>.from(newState[day] ?? {});
    if (daySet.contains(subject)) {
      daySet.remove(subject);
      if (daySet.isEmpty) {
        newState.remove(day);
      } else {
        newState[day] = daySet;
      }
    } else {
      daySet.add(subject);
      newState[day] = daySet;
    }
    state = newState;
    _scheduleSave();
  }

  void toggleBunkWholeDay(int day, List<String> classes) {
    final newState = Map<int, Set<String>>.from(state);
    final daySet = Set<String>.from(newState[day] ?? {});
    
    final allBunked = classes.every((subject) => daySet.contains(subject));
    
    for (var subject in classes) {
      if (allBunked) {
        daySet.remove(subject);
      } else {
        daySet.add(subject);
      }
    }
    
    if (daySet.isEmpty) {
      newState.remove(day);
    } else {
      newState[day] = daySet;
    }
    
    state = newState;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_startDate == null) return;
      final prefs = await SharedPreferences.getInstance();

      final list = <Map<String, String>>[];
      for (final entry in state.entries) {
        final dayIndex = entry.key;
        final date = dateFromDayIndex(_startDate!, dayIndex);
        final dateStr =
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        
        for (final className in entry.value) {
          list.add({'date': dateStr, 'class': className});
        }
      }

      final jsonStr = jsonEncode({'bunked_classes': list});
      await prefs.setString('bunked_classes_data', jsonStr);
    });
  }
}

final bunkedProvider =
    StateNotifierProvider<BunkedClassesNotifier, Map<int, Set<String>>>(
      (ref) => BunkedClassesNotifier(),
    );
