import 'utils.dart';

// ---------------------------------------------------------
// Models
// ---------------------------------------------------------

class Subject {
  final String name;

  /// Planned classes across the whole semester (or filter window).
  final int totalClasses;

  /// Classes that have already occurred (start → today, non-holiday/exam).
  final int heldClasses;

  /// Bunked among [heldClasses] only.
  final int skipped;
  final String faculty;

  Subject(
    String? name,
    dynamic totalClasses,
    dynamic skipped, {
    dynamic heldClasses,
    String? faculty,
  }) : name = safeString(name),
       totalClasses = safeInt(totalClasses),
       heldClasses = safeInt(heldClasses),
       skipped = safeInt(skipped),
       faculty = safeString(faculty);

  int get attendedClasses {
    final value = heldClasses - skipped;
    return value < 0 ? 0 : value;
  }

  /// Attendance projected across full semester / filter window.
  double get percentage =>
      totalClasses == 0 ? 0.0 : (totalClasses - skipped) / totalClasses;

  Subject copyWith({
    String? name,
    dynamic totalClasses,
    dynamic heldClasses,
    dynamic skipped,
    String? faculty,
  }) {
    return Subject(
      name ?? this.name,
      totalClasses ?? this.totalClasses,
      skipped ?? this.skipped,
      heldClasses: heldClasses ?? this.heldClasses,
      faculty: faculty ?? this.faculty,
    );
  }
}

/// A single class occurrence on a day (subject + formatted time range).
class ClassSlot {
  final String name;
  final String timeRange;

  ClassSlot({String? name, String? timeRange})
    : name = safeString(name),
      timeRange = safeString(timeRange);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSlot && other.name == name && other.timeRange == timeRange;

  @override
  int get hashCode => Object.hash(name, timeRange);
}

class SettingsState {
  final bool isFirstLaunch;
  final bool isInitialized;
  final String name;
  final String collegeName;
  final String department;
  final String year;
  final String selectedSection;
  final bool notificationsEnabled;
  final double desiredPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final String activeTheme;
  final bool showCurrentAttendance;
  final bool hasSeenAttendanceTogglePrompt;
  final bool hasSeenContactUsPrompt;
  final bool hasSeenLongWeekendsPrompt;

  const SettingsState({
    this.isFirstLaunch = true,
    this.isInitialized = false,
    this.name = '',
    this.collegeName = 'MAHE',
    this.department = 'MIT',
    this.year = '1st Year',
    this.selectedSection = 'A Section',
    this.notificationsEnabled = false,
    this.desiredPercentage = 0.75,
    required this.startDate,
    required this.endDate,
    this.activeTheme = 'Light',
    this.showCurrentAttendance = false,
    this.hasSeenAttendanceTogglePrompt = false,
    this.hasSeenContactUsPrompt = false,
    this.hasSeenLongWeekendsPrompt = false,
  });

  SettingsState copyWith({
    bool? isFirstLaunch,
    bool? isInitialized,
    String? name,
    String? collegeName,
    String? department,
    String? year,
    String? selectedSection,
    bool? notificationsEnabled,
    double? desiredPercentage,
    DateTime? startDate,
    DateTime? endDate,
    String? activeTheme,
    bool? showCurrentAttendance,
    bool? hasSeenAttendanceTogglePrompt,
    bool? hasSeenContactUsPrompt,
    bool? hasSeenLongWeekendsPrompt,
  }) {
    return SettingsState(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      isInitialized: isInitialized ?? this.isInitialized,
      name: name ?? this.name,
      collegeName: collegeName ?? this.collegeName,
      department: department ?? this.department,
      year: year ?? this.year,
      selectedSection: selectedSection ?? this.selectedSection,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      desiredPercentage: desiredPercentage ?? this.desiredPercentage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activeTheme: activeTheme ?? this.activeTheme,
      showCurrentAttendance:
          showCurrentAttendance ?? this.showCurrentAttendance,
      hasSeenAttendanceTogglePrompt:
          hasSeenAttendanceTogglePrompt ?? this.hasSeenAttendanceTogglePrompt,
      hasSeenContactUsPrompt:
          hasSeenContactUsPrompt ?? this.hasSeenContactUsPrompt,
      hasSeenLongWeekendsPrompt:
          hasSeenLongWeekendsPrompt ?? this.hasSeenLongWeekendsPrompt,
    );
  }

  Map<String, dynamic> toJson() => {
    'isFirstLaunch': isFirstLaunch,
    'isInitialized': isInitialized,
    'name': name,
    'collegeName': collegeName,
    'department': department,
    'year': year,
    'selectedSection': selectedSection,
    'notificationsEnabled': notificationsEnabled,
    'desiredPercentage': desiredPercentage,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'activeTheme': activeTheme,
    'showCurrentAttendance': showCurrentAttendance,
    'hasSeenAttendanceTogglePrompt': hasSeenAttendanceTogglePrompt,
    'hasSeenContactUsPrompt': hasSeenContactUsPrompt,
    'hasSeenLongWeekendsPrompt': hasSeenLongWeekendsPrompt,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      isFirstLaunch: json['isFirstLaunch'] ?? true,
      isInitialized: json['isInitialized'] ?? false,
      name: json['name'] ?? '',
      collegeName: json['collegeName'] ?? 'MAHE',
      department: json['department'] ?? 'MIT',
      year: json['year'] ?? '1st Year',
      selectedSection: json['selectedSection'] ?? 'A Section',
      notificationsEnabled: json['notificationsEnabled'] ?? false,
      desiredPercentage:
          (json['desiredPercentage'] as num?)?.toDouble() ?? 0.75,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      activeTheme: json['activeTheme'] ?? 'Light',
      showCurrentAttendance: json['showCurrentAttendance'] ?? false,
      hasSeenAttendanceTogglePrompt:
          json['hasSeenAttendanceTogglePrompt'] ?? false,
      hasSeenContactUsPrompt: json['hasSeenContactUsPrompt'] ?? false,
      hasSeenLongWeekendsPrompt: json['hasSeenLongWeekendsPrompt'] ?? false,
    );
  }

  String get initials {
    if (name.trim().isEmpty) return 'BK';
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }
}

class UiState {
  final int currentTab;
  final String statsFilter;
  final int selectedDay;
  final int todayDay;

  const UiState({
    this.currentTab = 0,
    this.statsFilter = 'Overall',
    this.selectedDay = 1,
    this.todayDay = 1,
  });

  UiState copyWith({
    int? currentTab,
    String? statsFilter,
    int? selectedDay,
    int? todayDay,
  }) {
    return UiState(
      currentTab: currentTab ?? this.currentTab,
      statsFilter: statsFilter ?? this.statsFilter,
      selectedDay: selectedDay ?? this.selectedDay,
      todayDay: todayDay ?? this.todayDay,
    );
  }
}

class ScheduleData {
  final Map<int, List<ClassSlot>> schedule;
  final Map<String, Subject> subjects;
  const ScheduleData(this.schedule, this.subjects);
}

class AttendanceStats {
  /// Full-semester planned class count.
  final int totalClasses;

  /// Classes that have occurred from semester start through today.
  final int classesHeld;
  final int missed;
  final int classesAttended;
  final double attendance;
  final int safeBunks;
  final List<double> dailyHistory;
  final double trend;

  const AttendanceStats({
    required this.totalClasses,
    required this.classesHeld,
    required this.missed,
    required this.classesAttended,
    required this.attendance,
    required this.safeBunks,
    required this.dailyHistory,
    required this.trend,
  });
}

/// Precomputed per-subject stats for the stats page (no build-time math).
class SubjectStatSummary {
  final String name;
  final String faculty;

  /// Planned classes in the active filter window.
  final int totalClasses;

  /// Held classes in the active filter window.
  final int heldClasses;
  final int skipped;
  final int attended;
  final double percentage;

  /// Semester-wide skip buffer (not filter-scoped).
  final int skipBalance;

  /// Consecutive classes to attend to recover semester target.
  final int classesToAttend;

  const SubjectStatSummary({
    required this.name,
    required this.faculty,
    required this.totalClasses,
    required this.heldClasses,
    required this.skipped,
    required this.attended,
    required this.percentage,
    required this.skipBalance,
    required this.classesToAttend,
  });
}

class FilteredStats {
  /// Planned classes in scope (full semester for Overall).
  final int total;

  /// Classes that have already occurred in scope.
  final int held;
  final int missed;
  final int attended;
  final double attendance;
  final double desiredPercentage;
  final String filter;

  /// Fully precomputed subject rows for the UI.
  final List<SubjectStatSummary> subjectStats;

  const FilteredStats({
    required this.total,
    required this.held,
    required this.missed,
    required this.attended,
    required this.attendance,
    required this.desiredPercentage,
    required this.filter,
    required this.subjectStats,
  });
}
