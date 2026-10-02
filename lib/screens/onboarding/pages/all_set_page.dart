import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/bunk_theme.dart';
import '../../../widgets/bunk_button.dart';
import '../../../state.dart';
import '../../../timetable_fetch.dart';

class AllSetPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const AllSetPage({super.key, required this.onNext});

  @override
  ConsumerState<AllSetPage> createState() => _AllSetPageState();
}

class _AllSetPageState extends ConsumerState<AllSetPage> {
  bool _isFinishing = false;

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final settings = ref.read(settingsProvider);

    try {
      // Best-effort timetable download — never block finishing onboarding.
      await fetchTimetable(
        collegeName: settings.collegeName,
        department: settings.department,
        year: settings.year,
        selectedSection: settings.selectedSection,
      );
    } catch (_) {
      // Ignore; user can still enter the app without remote data.
    }

    if (!mounted) return;

    ref.invalidate(rawDataProvider);

    await ref
        .read(settingsProvider.notifier)
        .completeOnboarding(
          settings.name,
          settings.year,
          settings.collegeName,
          settings.department,
          settings.selectedSection,
        );

    // startDate may have changed from the freshly fetched timetable — align
    // "today" to the real calendar day against the new semester start.
    final updated = ref.read(settingsProvider);
    ref
        .read(uiProvider.notifier)
        .syncTodayDay(startDate: updated.startDate, endDate: updated.endDate);

    if (!mounted) return;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2 OF 2', style: BunkTheme.of(context).bodyBold),
              Text(
                'SKIP',
                style: BunkTheme.of(
                  context,
                ).bodyBold.copyWith(color: BunkTheme.of(context).background),
              ), // Invisible placeholder to keep alignment
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressLine(context, true),
              _buildProgressLine(context, true),
            ],
          ),
          const SizedBox(height: 48),
          Text('YOU\'RE\nALL SET!', style: BunkTheme.of(context).display),
          const SizedBox(height: 16),
          Text(
            'Let\'s help you make the most of your semester.',
            style: BunkTheme.of(context).caption.copyWith(fontSize: 16),
          ),
          Expanded(
            child: kIsWeb
                ? const WebInstallGuide()
                : Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: BunkTheme.of(context).black,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 80,
                          color: BunkTheme.of(context).white,
                        ),
                      ),
                    ),
                  ),
          ),
          if (_isFinishing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CupertinoActivityIndicator()),
            )
          else
            BunkButton(
              text: 'LET\'S GO!',
              onPressed: _finishOnboarding,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(BuildContext context, bool active) {
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

class WebInstallGuide extends StatefulWidget {
  const WebInstallGuide({super.key});

  @override
  State<WebInstallGuide> createState() => _WebInstallGuideState();
}

class _WebInstallGuideState extends State<WebInstallGuide> {
  int _selectedPlatform = 0; // 0 for iOS, 1 for Android

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) {
      _selectedPlatform = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BunkTheme.of(context).lightGrey,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: BunkTheme.of(context).grey.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: BunkTheme.of(context).black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BunkTheme.of(context).background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.app_badge,
                        color: BunkTheme.of(context).black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add App to Home Screen',
                            style: BunkTheme.of(context).h2,
                          ),
                          Text(
                            'For the best experience',
                            style: BunkTheme.of(context).caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Custom Segmented Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: BunkTheme.of(context).background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlatform = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedPlatform == 0
                                  ? BunkTheme.of(context).lightGrey
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _selectedPlatform == 0
                                  ? [
                                      BoxShadow(
                                        color: BunkTheme.of(
                                          context,
                                        ).black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'iOS',
                              style: BunkTheme.of(context).bodyBold.copyWith(
                                color: _selectedPlatform == 0
                                    ? BunkTheme.of(context).black
                                    : BunkTheme.of(context).grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlatform = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedPlatform == 1
                                  ? BunkTheme.of(context).lightGrey
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _selectedPlatform == 1
                                  ? [
                                      BoxShadow(
                                        color: BunkTheme.of(
                                          context,
                                        ).black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Android',
                              style: BunkTheme.of(context).bodyBold.copyWith(
                                color: _selectedPlatform == 1
                                    ? BunkTheme.of(context).black
                                    : BunkTheme.of(context).grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedCrossFade(
                  firstChild: _buildPlatformGuide(
                    context,
                    icon: CupertinoIcons.share,
                    steps: [
                      'Tap the Share button at the bottom',
                      'Scroll down and select "Add to Home Screen"',
                      'Tap "Add" in the top right',
                    ],
                    isIOS: true,
                  ),
                  secondChild: _buildPlatformGuide(
                    context,
                    icon: CupertinoIcons.ellipsis_vertical,
                    steps: [
                      'Tap the Menu button (3 dots) top right',
                      'Select "Add to Home screen" or "Install app"',
                      'Follow the on-screen prompt',
                    ],
                  ),
                  crossFadeState: _selectedPlatform == 0
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeOutCubic,
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformGuide(
    BuildContext context, {
    required IconData icon,
    required List<String> steps,
    bool isIOS = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...steps.asMap().entries.map((entry) {
          int idx = entry.key;
          String step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: BunkTheme.of(context).black,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: BunkTheme.of(context).bodyBold.copyWith(
                        color: BunkTheme.of(context).background,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    step,
                    style: BunkTheme.of(context).body.copyWith(height: 1.3),
                  ),
                ),
                if (idx == 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BunkTheme.of(context).background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: BunkTheme.of(context).black,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        if (isIOS) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BunkTheme.of(context).red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BunkTheme.of(context).red.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: BunkTheme.of(context).red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Important for iOS users',
                      style: BunkTheme.of(context).bodyBold.copyWith(
                        color: BunkTheme.of(context).red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Thanks to Tim Apple, the data on the web-app will auto-magically be wiped off in case of inactivity for 6.9+ days.\n\nPlease open the app every 6 days 😭, press a random button and move on with your lonely life.\n\nThank you',
                  style: BunkTheme.of(context).caption.copyWith(
                    color: BunkTheme.of(context).red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
