import 'package:flutter/foundation.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/bunk_theme.dart';
import '../../../widgets/bunk_button.dart';
import '../../../widgets/bunk_text_field.dart';
import '../../../state.dart';
import '../../../timetable_fetch.dart';

class DetailsPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const DetailsPage({super.key, required this.onNext});

  @override
  ConsumerState<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends ConsumerState<DetailsPage> {
  final TextEditingController _nameController = TextEditingController();

  void _showYearPicker(BuildContext context) {
    final years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
    final year = ref.read(settingsProvider).year;
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
              initialItem: years.indexOf(year).clamp(0, years.length - 1),
            ),
            onSelectedItemChanged: (int selectedItem) {
              final selectedYear = years[selectedItem];
              ref.read(settingsProvider.notifier).setYear(selectedYear);

              fetchSem1SectionNames(
                    collegeName: ref.read(settingsProvider).collegeName,
                    department: ref.read(settingsProvider).department,
                    year: selectedYear,
                  )
                  .then((sections) {
                    if (sections.isNotEmpty && mounted) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSection(sections.first);
                    }
                  })
                  .catchError((_) {});
            },
            children: List<Widget>.generate(years.length, (int index) {
              return Center(child: Text(years[index]));
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _showSectionPicker(BuildContext context) async {
    final settings = ref.read(settingsProvider);
    var loadingShown = false;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
    loadingShown = true;

    List<String> sections = const [];
    try {
      sections = await fetchSem1SectionNames(
        collegeName: settings.collegeName,
        department: settings.department,
        year: settings.year,
      );
    } catch (_) {
      sections = const [];
    }

    if (loadingShown && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      loadingShown = false;
    }
    if (!context.mounted) return;

    // Fall back to local/default sections so the picker still works offline.
    if (sections.isEmpty) {
      sections = List<String>.from(ref.read(availableSectionsProvider));
    }

    if (sections.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('No Sections Found'),
          content: const Text('Could not find sections for this year.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    final selected = ref.read(settingsProvider).selectedSection;
    if (!sections.contains(selected)) {
      await ref.read(settingsProvider.notifier).setSection(sections.first);
    }

    if (!context.mounted) return;

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
              initialItem: sections
                  .indexOf(ref.read(settingsProvider).selectedSection)
                  .clamp(0, sections.length - 1),
            ),
            onSelectedItemChanged: (int selectedItem) {
              ref
                  .read(settingsProvider.notifier)
                  .setSection(sections[selectedItem]);
            },
            children: List<Widget>.generate(sections.length, (int index) {
              return Center(child: Text(sections[index]));
            }),
          ),
        ),
      ),
    );
  }

  void _showCollegePicker(BuildContext context) {
    final colleges = SettingsNotifier.availableColleges;
    final college = ref.read(settingsProvider).collegeName;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: colleges
                  .indexOf(college)
                  .clamp(0, colleges.length - 1),
            ),
            onSelectedItemChanged: (int selectedItem) {
              final selectedCollege = colleges[selectedItem];
              final departments =
                  SettingsNotifier.collegeDepartments[selectedCollege] ??
                  const ['MIT'];
              ref
                  .read(settingsProvider.notifier)
                  .setCollegeName(selectedCollege);

              fetchSem1SectionNames(
                    collegeName: selectedCollege,
                    department: departments.first,
                    year: '1st Year',
                  )
                  .then((sections) {
                    if (sections.isNotEmpty && mounted) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSection(sections.first);
                    }
                  })
                  .catchError((_) {});
            },
            children: List<Widget>.generate(colleges.length, (int index) {
              return Center(child: Text(colleges[index]));
            }),
          ),
        ),
      ),
    );
  }

  void _showDepartmentPicker(BuildContext context) {
    final college = ref.read(settingsProvider).collegeName;
    final departments =
        SettingsNotifier.collegeDepartments[college] ?? const ['MIT'];
    final department = ref.read(settingsProvider).department;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32.0,
            scrollController: FixedExtentScrollController(
              initialItem: departments
                  .indexOf(department)
                  .clamp(0, departments.length - 1),
            ),
            onSelectedItemChanged: (int selectedItem) {
              final selectedDepartment = departments[selectedItem];
              ref
                  .read(settingsProvider.notifier)
                  .setDepartment(selectedDepartment);

              fetchSem1SectionNames(
                    collegeName: ref.read(settingsProvider).collegeName,
                    department: selectedDepartment,
                    year: '1st Year',
                  )
                  .then((sections) {
                    if (sections.isNotEmpty && mounted) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSection(sections.first);
                    }
                  })
                  .catchError((_) {});
            },
            children: List<Widget>.generate(departments.length, (int index) {
              return Center(child: Text(departments[index]));
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1 OF 2', style: BunkTheme.of(context).bodyBold),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildProgressLine(true),
                        _buildProgressLine(false),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'TELL US\nABOUT YOU',
                      style: BunkTheme.of(context).display,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'ll personalize your experience based on your details.',
                      style: BunkTheme.of(
                        context,
                      ).caption.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    BunkTextField(
                      label: 'Full Name (optional)',
                      placeholder:
                          defaultTargetPlatform == TargetPlatform.android
                          ? 'Mike Hawk'
                          : 'Mike Hunt',
                      prefixIcon: CupertinoIcons.person,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 24),
                    BunkTextField(
                      label: 'College Name',
                      isDropdown: true,
                      value: settings.collegeName,
                      prefixIcon: CupertinoIcons.building_2_fill,
                      onTap: () => _showCollegePicker(context),
                    ),
                    const SizedBox(height: 24),
                    BunkTextField(
                      label: 'Department',
                      isDropdown: true,
                      value: settings.department,
                      prefixIcon: CupertinoIcons.collections,
                      onTap: () => _showDepartmentPicker(context),
                    ),
                    const SizedBox(height: 24),
                    BunkTextField(
                      label: 'Year',
                      isDropdown: true,
                      value: settings.year,
                      prefixIcon: CupertinoIcons.calendar,
                      onTap: () => _showYearPicker(context),
                    ),
                    const SizedBox(height: 24),
                    BunkTextField(
                      label: 'Section',
                      isDropdown: true,
                      value: settings.selectedSection,
                      prefixIcon: CupertinoIcons.square_grid_2x2,
                      onTap: () => _showSectionPicker(context),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: BunkTheme.of(context).white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BunkTheme.of(context).lightGrey,
                        ),
                      ),
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
                                    Text(
                                      'DESIRED %',
                                      style: BunkTheme.of(context).bodyBold,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: CupertinoSlider(
                                    value: settings.desiredPercentage,
                                    min: 0.50,
                                    max: 0.95,
                                    divisions: 100,
                                    activeColor: BunkTheme.of(context).black,
                                    thumbColor: BunkTheme.of(context).black,
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
                            '${(settings.desiredPercentage * 100).round()}%',
                            style: BunkTheme.of(context).display.copyWith(
                              color: BunkTheme.of(context).black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: BunkTheme.of(context).white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BunkTheme.of(context).lightGrey,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
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
                                    Text(
                                      'CURRENT ATTENDANCE',
                                      style: BunkTheme.of(context).bodyBold,
                                    ),
                                    const SizedBox(height: 2),
                                    // Text(
                                    //   settings.showCurrentAttendance
                                    //       ? 'Based on classes held till date'
                                    //       : 'Based on total semester classes',
                                    //   style: BunkTheme.of(
                                    //     context,
                                    //   ).caption.copyWith(fontSize: 12),
                                    // ),
                                  ],
                                ),
                              ),
                              CupertinoSwitch(
                                value: settings.showCurrentAttendance,
                                activeTrackColor: BunkTheme.of(context).accent,
                                onChanged: (val) {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setShowCurrentAttendance(val);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: BunkTheme.of(
                                context,
                              ).grey.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: BunkTheme.of(context).lightGrey,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  CupertinoIcons.info_circle,
                                  color: BunkTheme.of(context).grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'When enabled, attendance % is calculated from classes held up to today. When disabled, overall attendance projects across all semester classes.',
                                    style: BunkTheme.of(context).caption
                                        .copyWith(
                                          fontSize: 12,
                                          height: 1.35,
                                          color: BunkTheme.of(context).black,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Spacer(),
                    const SizedBox(height: 24),
                    BunkButton(
                      text: 'CONTINUE',
                      onPressed: () {
                        final name = _nameController.text.trim();
                        ref.read(settingsProvider.notifier).setName(name);
                        widget.onNext();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressLine(bool active) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        height: 4,
        decoration: BoxDecoration(
          color: active
              ? BunkTheme.of(context).black
              : BunkTheme.of(context).lightGrey,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
