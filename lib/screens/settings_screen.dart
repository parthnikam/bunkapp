import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state.dart';
import '../timetable_fetch.dart';
import '../theme/bunk_theme.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final holidays = ref.watch(holidaysProvider);
    final examRanges = ref.watch(examRangesProvider);
    final currentSem = ref.watch(currentSemesterProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('SETTINGS', style: BunkTheme.of(context).display)],
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () => _showEditProfileDialog(context, ref, settings),
            child: _buildCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: BunkTheme.of(context).black,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          settings.initials,
                          style: BunkTheme.of(
                            context,
                          ).h2.copyWith(color: BunkTheme.of(context).white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (settings.name.trim().isEmpty
                                    ? 'STUDENT'
                                    : settings.name)
                                .toUpperCase(),
                            style: BunkTheme.of(context).bodyBold,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSem != null
                                ? '${settings.year} • $currentSem • ${settings.selectedSection}'
                                : '${settings.year} • ${settings.selectedSection}',
                            style: BunkTheme.of(context).caption,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: BunkTheme.of(context).grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Schedule: Holidays, Exam Dates, Timetable
          const SizedBox(height: 16),

          _buildCard(
            context,
            child: Column(
              children: [
                SettingsTile(
                  title: 'Holidays',
                  value: '${holidays.length} Holidays',
                  prefixIcon: CupertinoIcons.calendar_today,
                  showBorder: true,
                  onTap: () => _showHolidaysActionSheet(context, ref),
                ),
                SettingsTile(
                  title: 'Exam Dates',
                  value: examRanges.isEmpty
                      ? 'None'
                      : '${examRanges.length} Period${examRanges.length == 1 ? '' : 's'}',
                  prefixIcon: CupertinoIcons.doc_text,
                  showBorder: true,
                  onTap: () => _showExamsActionSheet(context, ref),
                ),
                SettingsTile(
                  title: 'Timetable',
                  value: settings.selectedSection.toUpperCase(),
                  prefixIcon: CupertinoIcons.time,
                  showBorder: false,
                  onTap: () => _showTimetable(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Theme (Alone)
          _buildCard(
            context,
            child: SettingsTile(
              title: 'Theme',
              value: settings.activeTheme,
              prefixIcon: CupertinoIcons.paintbrush,
              showBorder: false,
              onTap: () => _showThemePicker(context, ref, settings),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Current Attendance & Percentage
          _buildCard(
            context,
            child: Column(
              children: [
                _buildAttendanceModeTile(
                  context,
                  ref,
                  settings,
                  showBorder: true,
                ),
                _buildPercentageSlider(context, ref, settings),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Erase All Data, About & Privacy Policy
          _buildCard(
            context,
            child: Column(
              children: [
                SettingsTile(
                  title: 'Erase All Data',
                  prefixIcon: CupertinoIcons.trash,
                  valueColor: CupertinoColors.destructiveRed,
                  showBorder: true,
                  onTap: () => _showResetDataConfirmation(context, ref),
                ),
                SettingsTile(
                  title: 'About',
                  prefixIcon: CupertinoIcons.info,
                  showBorder: true,
                  onTap: () => _showAbout(context),
                ),
                SettingsTile(
                  title: 'Privacy Policy',
                  prefixIcon: CupertinoIcons.shield,
                  showBorder: false,
                  onTap: () => _launchPrivacyPolicy(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Contact Us
          _buildCard(
            context,
            child: SettingsTile(
              title: 'Contact Us',
              prefixIcon: CupertinoIcons.mail,
              showBorder: false,
              onTap: () => _showContactUs(context),
            ),
          ),

          const SizedBox(height: 100), // Bottom padding for navbar
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: BunkTheme.of(context).white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BunkTheme.of(context).lightGrey),
      ),
      child: child,
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    String tempName = settings.name;
    String tempYear = settings.year;
    String tempSection = settings.selectedSection;
    // Prefer remote sections if already loaded; otherwise local/default so the
    // section button is never disabled on open.
    List<String> availableSections =
        ref.read(availableSectionsAsyncProvider).valueOrNull ??
        ref.read(availableSectionsProvider);
    var isLoadingSections = false;
    var didStartInitialLoad = false;
    void Function(void Function())? dialogSetState;

    Future<void> loadSectionsForYear(String year) async {
      dialogSetState?.call(() => isLoadingSections = true);
      final sections = await fetchSem1SectionNames(
        collegeName: settings.collegeName,
        department: settings.department,
        year: year,
      );
      dialogSetState?.call(() {
        if (sections.isNotEmpty) {
          availableSections = sections;
          if (!sections.contains(tempSection)) {
            tempSection = sections.first;
          }
        }
        isLoadingSections = false;
      });
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            // Start remote refresh once setState is available.
            if (!didStartInitialLoad) {
              didStartInitialLoad = true;
              Future.microtask(() => loadSectionsForYear(tempYear));
            }
            return CupertinoAlertDialog(
              title: const Text('Edit Profile'),
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    placeholder: 'Name',
                    controller: TextEditingController(text: tempName)
                      ..selection = TextSelection.collapsed(
                        offset: tempName.length,
                      ),
                    onChanged: (val) => tempName = val,
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(tempYear, style: BunkTheme.of(context).body),
                    onPressed: () {
                      final years = [
                        '1st Year',
                        '2nd Year',
                        '3rd Year',
                        '4th Year',
                      ];
                      _showPicker(ctx, years, years.indexOf(tempYear), (idx) {
                        final year = years[idx];
                        setState(() => tempYear = year);
                        loadSectionsForYear(year);
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: availableSections.isEmpty
                        ? null
                        : () {
                            _showPicker(
                              ctx,
                              availableSections,
                              availableSections
                                  .indexOf(tempSection)
                                  .clamp(0, availableSections.length - 1),
                              (idx) => setState(
                                () => tempSection = availableSections[idx],
                              ),
                            );
                          },
                    child: isLoadingSections
                        ? const CupertinoActivityIndicator()
                        : Text(tempSection, style: BunkTheme.of(context).body),
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Save'),
                  onPressed: () async {
                    if (tempYear != settings.year ||
                        tempSection != settings.selectedSection) {
                      showCupertinoDialog(
                        context: context,
                        builder: (confirmCtx) => CupertinoAlertDialog(
                          title: const Text('Warning'),
                          content: const Text(
                            'Changing your section or year will reset all your attendance data. Do you want to continue?',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(confirmCtx),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Continue'),
                              onPressed: () async {
                                await fetchTimetable(
                                  collegeName: settings.collegeName,
                                  department: settings.department,
                                  year: tempYear,
                                  selectedSection: tempSection,
                                );
                                ref.invalidate(rawDataProvider);
                                ref
                                    .read(settingsProvider.notifier)
                                    .completeOnboarding(
                                      tempName,
                                      tempYear,
                                      settings.collegeName,
                                      settings.department,
                                      tempSection,
                                    );
                                ref.read(bunkedProvider.notifier).clear();
                                if (context.mounted) {
                                  Navigator.pop(confirmCtx);
                                  Navigator.pop(ctx);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    } else {
                      ref
                          .read(settingsProvider.notifier)
                          .completeOnboarding(
                            tempName,
                            tempYear,
                            settings.collegeName,
                            settings.department,
                            tempSection,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPicker(
    BuildContext context,
    List<String> items,
    int initialIndex,
    ValueChanged<int> onSelected,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: initialIndex.clamp(0, items.length - 1),
            ),
            onSelectedItemChanged: onSelected,
            children: List<Widget>.generate(items.length, (int index) {
              return Center(child: Text(items[index]));
            }),
          ),
        ),
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final themes = BunkThemeData.allThemes;
    _showPicker(
      context,
      themes,
      themes.indexOf(settings.activeTheme).clamp(0, themes.length - 1),
      (idx) {
        ref.read(settingsProvider.notifier).setTheme(themes[idx]);
      },
    );
  }

  void _showDatePicker(
    BuildContext context,
    DateTime initialDate,
    ValueChanged<DateTime> onSelected, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    DateTime tempDate = initialDate;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  CupertinoButton(
                    child: Text(
                      'Done',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                    onPressed: () {
                      onSelected(tempDate);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (date) {
                    tempDate = date;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.isAtSameMomentAs(end)) return _formatDate(start);
    return '${_formatDate(start)} – ${_formatDate(end)}';
  }

  void _showHolidaysActionSheet(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Consumer(
        builder: (context, ref, child) {
          final userHolidays = ref.watch(holidaysProvider);
          final systemHolidaysMap = ref.watch(systemHolidaysProvider);

          final allDates = <DateTime>{
            ...userHolidays,
            ...systemHolidaysMap.keys,
          }.toList();
          allDates.sort();

          return CupertinoActionSheet(
            title: const Text('Holidays'),
            message: const Text(
              'Swipe a user-added holiday left to remove it.',
            ),
            actions: <Widget>[
              if (allDates.isEmpty)
                CupertinoActionSheetAction(
                  onPressed: () {},
                  child: Text(
                    'No holidays yet',
                    style: TextStyle(
                      color: BunkTheme.of(context).grey,
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              for (final date in allDates)
                Builder(
                  builder: (context) {
                    final isUserHoliday = userHolidays.contains(date);
                    final isSystemHoliday = systemHolidaysMap.containsKey(date);

                    final title = isSystemHoliday
                        ? (systemHolidaysMap[date] ?? 'Holiday')
                        : 'User Holiday';

                    final itemWidget = CupertinoActionSheetAction(
                      onPressed: () {},
                      child: Column(
                        children: [
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: BunkTheme.of(context).black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              color: BunkTheme.of(context).accent,
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isUserHoliday) {
                      return Dismissible(
                        key: ValueKey(date.toIso8601String()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          ref
                              .read(holidaysProvider.notifier)
                              .removeHoliday(date);
                        },
                        background: Container(
                          color: BunkTheme.of(context).red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(
                            CupertinoIcons.delete,
                            color: BunkTheme.of(context).white,
                          ),
                        ),
                        child: itemWidget,
                      );
                    } else {
                      return itemWidget;
                    }
                  },
                ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _showDatePicker(
                    context,
                    DateTime.now(),
                    (date) {
                      ref.read(holidaysProvider.notifier).addHoliday(date);
                    },
                    minDate: settings.startDate,
                    maxDate: settings.endDate,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: BunkTheme.of(context).black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Add Holiday',
                      style: TextStyle(
                        color: BunkTheme.of(context).white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Done',
                style: TextStyle(color: BunkTheme.of(context).black),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExamsActionSheet(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Consumer(
        builder: (context, ref, child) {
          final examRanges = ref.watch(examRangesProvider);

          return CupertinoActionSheet(
            title: const Text('Exam Dates'),
            message: const Text(
              'Exam periods from your timetable (date ranges).',
            ),
            actions: <Widget>[
              if (examRanges.isEmpty)
                CupertinoActionSheetAction(
                  onPressed: () {},
                  child: Text(
                    'No exam dates scheduled',
                    style: TextStyle(
                      color: BunkTheme.of(context).grey,
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              for (final range in examRanges)
                CupertinoActionSheetAction(
                  onPressed: () {},
                  child: Column(
                    children: [
                      Text(
                        range.label,
                        style: TextStyle(
                          color: BunkTheme.of(context).red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateRange(range.start, range.end),
                        style: TextStyle(
                          color: BunkTheme.of(context).black,
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Done',
                style: TextStyle(color: BunkTheme.of(context).black),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget _buildNotificationTile(BuildContext context, WidgetRef ref, SettingsState settings) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //     decoration: BoxDecoration(
  //       border: Border(
  //         bottom: BorderSide(color: BunkTheme.of(context).lightGrey, width: 1),
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(CupertinoIcons.bell, color: BunkTheme.of(context).black, size: 24),
  //         const SizedBox(width: 16),
  //         Expanded(child: Text('NOTIFICATIONS', style: BunkTheme.of(context).bodyBold)),
  //         CupertinoSwitch(
  //           value: settings.notificationsEnabled,
  //           activeTrackColor: BunkTheme.of(context).accent,
  //           onChanged: (val) => ref
  //               .read(settingsProvider.notifier)
  //               .setNotificationsEnabled(val),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showResetDataConfirmation(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Erase All Data?'),
        content: const Text(
          'This will erase ALL your data including preferences, attendance records, holidays, and reset everything to defaults. This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Erase Everything'),
            onPressed: () {
              ref.read(bunkedProvider.notifier).clear();
              ref.read(holidaysProvider.notifier).clearAll();
              ref.read(settingsProvider.notifier).resetData();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceModeTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings, {
    bool showBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: BunkTheme.of(context).lightGrey,
                  width: 1,
                ),
              ),
            )
          : null,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.chart_pie,
            color: BunkTheme.of(context).black,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Attendance', style: BunkTheme.of(context).body),
                const SizedBox(height: 2),
                Text(
                  settings.showCurrentAttendance
                      ? 'Based on classes held till date'
                      : 'Based on all semester classes',
                  style: BunkTheme.of(context).caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: settings.showCurrentAttendance,
            activeTrackColor: BunkTheme.of(context).accent,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              ref.read(settingsProvider.notifier).setShowCurrentAttendance(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageSlider(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final pct = (settings.desiredPercentage * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.speedometer,
                      color: BunkTheme.of(context).black,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text('Desired %', style: BunkTheme.of(context).body),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlider(
                    value: settings.desiredPercentage,
                    min: 0.60,
                    max: 0.95,
                    divisions: 100,
                    activeColor: BunkTheme.of(context).black,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      ref
                          .read(settingsProvider.notifier)
                          .setDesiredPercentage(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$pct%',
            style: BunkTheme.of(
              context,
            ).display.copyWith(color: BunkTheme.of(context).black),
          ),
        ],
      ),
    );
  }

  void _showTimetable(BuildContext context, WidgetRef ref) {
    final tt = ref.read(rawTimetableProvider);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: BunkTheme.of(context).white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TIMETABLE', style: BunkTheme.of(context).h1),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Done',
                      style: TextStyle(color: BunkTheme.of(context).black),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final day in ['MON', 'TUE', 'WED', 'THU', 'FRI']) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: BunkTheme.of(context).black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.calendar,
                              color: BunkTheme.of(context).white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            day,
                            style: BunkTheme.of(
                              context,
                            ).h2.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    if ((tt[day] ?? []).isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No classes',
                          style: BunkTheme.of(context).caption,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: BunkTheme.of(context).white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BunkTheme.of(context).lightGrey,
                          ),
                        ),
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < (tt[day] ?? []).length;
                              i++
                            ) ...[
                              Builder(
                                builder: (context) {
                                  final slot = tt[day]![i];
                                  final isBreak =
                                      slot['activity']!.toLowerCase().contains(
                                        'break',
                                      ) ||
                                      slot['activity']!.toLowerCase().contains(
                                        'lunch',
                                      );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            slot['time']!,
                                            style: BunkTheme.of(context).caption
                                                .copyWith(
                                                  color: isBreak
                                                      ? BunkTheme.of(
                                                          context,
                                                        ).grey
                                                      : BunkTheme.of(
                                                          context,
                                                        ).black,
                                                  fontWeight: isBreak
                                                      ? FontWeight.normal
                                                      : FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 32,
                                          color: BunkTheme.of(
                                            context,
                                          ).lightGrey,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                        ),
                                        Icon(
                                          isBreak
                                              ? CupertinoIcons.time
                                              : CupertinoIcons.book,
                                          color: isBreak
                                              ? BunkTheme.of(context).grey
                                              : BunkTheme.of(context).black,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            slot['activity']!,
                                            style: BunkTheme.of(context).body
                                                .copyWith(
                                                  color: isBreak
                                                      ? BunkTheme.of(
                                                          context,
                                                        ).grey
                                                      : BunkTheme.of(
                                                          context,
                                                        ).black,
                                                  fontWeight: isBreak
                                                      ? FontWeight.normal
                                                      : FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              if (i < (tt[day] ?? []).length - 1)
                                Container(
                                  height: 1,
                                  color: BunkTheme.of(context).lightGrey,
                                  margin: const EdgeInsets.only(left: 120),
                                ),
                            ],
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://www.freeprivacypolicy.com/live/08c80610-d651-42ee-8bce-8f069bd97c94',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _sendEmailSuggestion(String text) async {
    String encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'bunkfounders@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Bunk App Suggestion / Feedback',
        'body': text,
      }),
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (_) {}
  }

  void _showAbout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('BUNK', style: BunkTheme.of(context).h1),
        content: Column(
          children: [
            // const SizedBox(height: 8),
            // Text('Version 1.0.0', style: BunkTheme.of(context).caption),
            const SizedBox(height: 8),
            Text(
              'Track your attendance, plan your bunks, stay above 75%.',
              style: BunkTheme.of(context).body.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'Privacy Policy',
              style: TextStyle(color: BunkTheme.of(context).grey),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _launchPrivacyPolicy();
            },
          ),
          CupertinoDialogAction(
            child: Text(
              'OK',
              style: TextStyle(color: BunkTheme.of(context).black),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showContactUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final textController = TextEditingController();
        var copied = false;
        var isSubmitted = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final safeBottom = MediaQuery.of(context).padding.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                decoration: BoxDecoration(
                  color: BunkTheme.of(context).white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(24, 12, 24, safeBottom + 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: BunkTheme.of(context).lightGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CONTACT US', style: BunkTheme.of(context).h1),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: BunkTheme.of(context).background,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 16,
                                color: BunkTheme.of(context).grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isSubmitted) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: BunkTheme.of(
                                context,
                              ).green.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.checkmark_alt,
                              color: BunkTheme.of(context).green,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'SUGGESTION SENT!',
                            style: BunkTheme.of(context).h2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Thanks for helping make Bunk better.\nWe review all feedback seriously!',
                            textAlign: TextAlign.center,
                            style: BunkTheme.of(context).body.copyWith(
                              color: BunkTheme.of(context).grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: BunkTheme.of(context).black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'DONE',
                                style: BunkTheme.of(
                                  context,
                                ).button.copyWith(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Email Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: BunkTheme.of(context).background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: BunkTheme.of(context).lightGrey,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.mail_solid,
                                color: BunkTheme.of(context).black,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'bunkfounders@gmail.com',
                                  style: BunkTheme.of(context).body,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    const ClipboardData(
                                      text: 'bunkfounders@gmail.com',
                                    ),
                                  );
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    copied = true;
                                  });
                                  Future.delayed(
                                    const Duration(seconds: 2),
                                    () {
                                      if (context.mounted) {
                                        setState(() {
                                          copied = false;
                                        });
                                      }
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: copied
                                        ? BunkTheme.of(
                                            context,
                                          ).green.withValues(alpha: 0.15)
                                        : BunkTheme.of(context).white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: copied
                                          ? BunkTheme.of(context).green
                                          : BunkTheme.of(context).lightGrey,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        copied
                                            ? CupertinoIcons.checkmark
                                            : CupertinoIcons.doc_on_doc,
                                        size: 14,
                                        color: copied
                                            ? BunkTheme.of(context).green
                                            : BunkTheme.of(context).black,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        copied ? 'Copied' : 'Copy',
                                        style: BunkTheme.of(context).caption
                                            .copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: copied
                                                  ? BunkTheme.of(context).green
                                                  : BunkTheme.of(context).black,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'YOUR SUGGESTION',
                          style: BunkTheme.of(context).bodyBold.copyWith(
                            fontSize: 13,
                            color: BunkTheme.of(context).grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: BunkTheme.of(context).background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: errorMessage != null
                                  ? BunkTheme.of(context).red
                                  : BunkTheme.of(context).lightGrey,
                            ),
                          ),
                          child: CupertinoTextField(
                            controller: textController,
                            minLines: 4,
                            maxLines: 7,
                            placeholder:
                                'Have a feature in mind or found something buggy? Tell us here...',
                            placeholderStyle: BunkTheme.of(context).body
                                .copyWith(
                                  color: BunkTheme.of(context).grey,
                                  fontSize: 14,
                                ),
                            style: BunkTheme.of(
                              context,
                            ).body.copyWith(fontSize: 14),
                            decoration: null,
                            padding: EdgeInsets.zero,
                            cursorColor: BunkTheme.of(context).black,
                            onChanged: (val) {
                              if (errorMessage != null &&
                                  val.trim().isNotEmpty) {
                                setState(() {
                                  errorMessage = null;
                                });
                              }
                            },
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            errorMessage!,
                            style: BunkTheme.of(context).caption.copyWith(
                              color: BunkTheme.of(context).red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () async {
                            final text = textController.text.trim();
                            if (text.isEmpty) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                errorMessage =
                                    'Please type a suggestion before sending.';
                              });
                              return;
                            }
                            HapticFeedback.mediumImpact();
                            setState(() {
                              isSubmitted = true;
                            });
                            await _sendEmailSuggestion(text);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: BunkTheme.of(context).black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.paperplane_fill,
                                  color: BunkTheme.of(context).white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SEND SUGGESTION',
                                  style: BunkTheme.of(
                                    context,
                                  ).button.copyWith(fontSize: 22),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: _launchPrivacyPolicy,
                            child: Text(
                              'Privacy Policy',
                              style: BunkTheme.of(context).caption.copyWith(
                                fontSize: 12,
                                color: BunkTheme.of(context).grey,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
