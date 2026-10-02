import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/bunk_theme.dart';
import '../../../widgets/bunk_button.dart';

class AlmostTherePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const AlmostTherePage({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<AlmostTherePage> createState() => _AlmostTherePageState();
}

class _AlmostTherePageState extends State<AlmostTherePage>
    with TickerProviderStateMixin {
  // Step completion tracking
  bool _step1Done = false; // Bunk a class
  bool _step2Done = false; // Safety indicator
  bool _step3Done = false; // Tab discovery
  bool _step4Done = false; // Stats card

  // Step 1 state
  bool _mockBunked = false;

  // Step 2 state
  bool _safetyTapped = false;

  // Step 3 state
  final Set<int> _tappedTabs = {};

  // Pulse animation for hints
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _allDone => _step1Done && _step2Done && _step3Done && _step4Done;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onBunkTap() {
    if (_step1Done) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _mockBunked = true;
      _step1Done = true;
    });
  }

  void _onSafetyTap() {
    if (_step2Done) return;
    HapticFeedback.lightImpact();
    setState(() {
      _safetyTapped = !_safetyTapped;
      _step2Done = true;
    });
  }

  void _onTabTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _tappedTabs.add(index);
      if (_tappedTabs.length == 4) {
        _step3Done = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2 OF 3', style: BunkTheme.of(context).bodyBold),
              GestureDetector(
                onTap: widget.onSkip,
                child: Text('SKIP', style: BunkTheme.of(context).bodyBold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressLine(context, true),
              _buildProgressLine(context, true),
              _buildProgressLine(context, false),
            ],
          ),
          const SizedBox(height: 32),
          Text('HOW IT\nWORKS', style: BunkTheme.of(context).display),
          const SizedBox(height: 8),
          Text(
            'Try each interaction to learn the basics.',
            style: BunkTheme.of(context).caption.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Tutorial Steps
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStep1BunkClass(context),
                  const SizedBox(height: 16),
                  _buildStep2SafetyCheck(context),
                  const SizedBox(height: 16),
                  _buildStep3NavigateTabs(context),
                  const SizedBox(height: 16),
                  _buildStep4StatsCard(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Continue Button
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _allDone ? 1.0 : 0.4,
            child: BunkButton(
              text: _allDone ? 'CONTINUE' : 'COMPLETE ALL STEPS',
              onPressed: _allDone ? widget.onNext : () {},
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: Bunk a Class ──────────────────────────────────

  Widget _buildStep1BunkClass(BuildContext context) {
    return _buildStepCard(
      context,
      stepNumber: 1,
      title: 'BUNK A CLASS',
      subtitle: 'Tap the button to mark a class as bunked',
      isDone: _step1Done,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BunkTheme.of(context).background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maths',
                    style: BunkTheme.of(
                      context,
                    ).bodyBold.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '9:00 AM',
                    style: BunkTheme.of(context).caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            // Percentage indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _mockBunked
                  ? Row(
                      key: const ValueKey('bunked-pct'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '74%',
                          style: BunkTheme.of(context).bodyBold.copyWith(
                            color: BunkTheme.of(context).black,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    )
                  : Row(
                      key: const ValueKey('unbunked-pct'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('76%', style: BunkTheme.of(context).bodyBold),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            CupertinoIcons.arrow_right,
                            size: 12,
                            color: BunkTheme.of(context).grey,
                          ),
                        ),
                        Text(
                          '74%',
                          style: BunkTheme.of(
                            context,
                          ).bodyBold.copyWith(color: BunkTheme.of(context).red),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
            ),
            // Bunk button
            GestureDetector(
              onTap: _onBunkTap,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _mockBunked
                    ? Text(
                        'BUNKED!',
                        key: const ValueKey('bunked'),
                        style: BunkTheme.of(context).button.copyWith(
                          fontSize: 22,
                          color: BunkTheme.of(context).black,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _step1Done
                                ? 1.0
                                : 0.9 + (_pulseAnimation.value * 0.1),
                            child: child,
                          );
                        },
                        child: Container(
                          key: const ValueKey('bunk'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: BunkTheme.of(context).black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'BUNK',
                            style: BunkTheme.of(context).bodyBold.copyWith(
                              color: BunkTheme.of(context).white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 2: Safety Check ──────────────────────────────────

  Widget _buildStep2SafetyCheck(BuildContext context) {
    final showSafe = !_safetyTapped;
    return _buildStepCard(
      context,
      stepNumber: 2,
      title: 'CHECK YOUR SAFETY',
      subtitle: 'Tap the card to see if you can bunk today',
      isDone: _step2Done,
      child: GestureDetector(
        onTap: _onSafetyTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BunkTheme.of(context).background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAN I BUNK TODAY?',
                style: BunkTheme.of(context).caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      showSafe ? 'YES' : 'NO',
                      key: ValueKey(showSafe),
                      style: BunkTheme.of(context).h1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: showSafe
                          ? BunkTheme.of(context).accent
                          : BunkTheme.of(context).red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  showSafe
                      ? "You're safe to take the day off."
                      : "Don't even think about it.",
                  key: ValueKey(showSafe),
                  style: BunkTheme.of(context).caption.copyWith(fontSize: 12),
                ),
              ),
              if (!_step2Done)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.hand_draw,
                          size: 14,
                          color: BunkTheme.of(context).grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to try',
                          style: BunkTheme.of(context).caption.copyWith(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 3: Navigate Tabs ─────────────────────────────────

  Widget _buildStep3NavigateTabs(BuildContext context) {
    final tabData = [
      (
        icon: CupertinoIcons.home,
        label: 'HOME',
        desc:
            'Your daily command center — see if you can bunk today, check your classes, and mark attendance with one tap.',
        feature: 'Quick bunk check + today\'s schedule',
      ),
      (
        icon: CupertinoIcons.calendar,
        label: 'CALENDAR',
        desc:
            'Browse any day of your semester. See your full timetable, mark bunks for past and future dates.',
        feature: 'Day-by-day attendance tracking',
      ),
      (
        icon: CupertinoIcons.chart_bar_alt_fill,
        label: 'STATS',
        desc:
            'Track your attendance percentage across all subjects. Filter by week, month, or overall to spot trends.',
        feature: 'Subject-wise breakdown + safe bunk count',
      ),
      (
        icon: CupertinoIcons.settings,
        label: 'SETTINGS',
        desc:
            'Edit your profile, change themes, set your desired attendance %, manage holidays, and view your timetable.',
        feature: 'Themes, holidays & preferences',
      ),
    ];

    return _buildStepCard(
      context,
      stepNumber: 3,
      title: 'EXPLORE THE APP',
      subtitle: 'Tap each tab to discover what it does',
      isDone: _step3Done,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (i) {
              final tapped = _tappedTabs.contains(i);
              return GestureDetector(
                onTap: () => _onTabTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: tapped
                        ? BunkTheme.of(context).black
                        : BunkTheme.of(context).background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        tabData[i].icon,
                        size: 24,
                        color: tapped
                            ? BunkTheme.of(context).white
                            : BunkTheme.of(context).grey,
                      ),
                      if (tapped) ...[
                        const SizedBox(height: 6),
                        Text(
                          tabData[i].label,
                          style: BunkTheme.of(context).caption.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: BunkTheme.of(context).white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Descriptive card for last tapped tab
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: const Alignment(0.0, -1.0),
                child: child,
              ),
            ),
            child: _tappedTabs.isNotEmpty
                ? Container(
                    key: ValueKey(_tappedTabs.last),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BunkTheme.of(context).background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              tabData[_tappedTabs.last].icon,
                              size: 16,
                              color: BunkTheme.of(context).black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tabData[_tappedTabs.last].label,
                              style: BunkTheme.of(
                                context,
                              ).bodyBold.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tabData[_tappedTabs.last].desc,
                          style: BunkTheme.of(
                            context,
                          ).caption.copyWith(fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: BunkTheme.of(
                              context,
                            ).accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tabData[_tappedTabs.last].feature,
                            style: BunkTheme.of(context).caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: BunkTheme.of(context).black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.hand_draw,
                          size: 14,
                          color: BunkTheme.of(context).grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap each icon to learn more',
                          key: const ValueKey('hint'),
                          style: BunkTheme.of(context).caption.copyWith(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_tappedTabs.isNotEmpty && _tappedTabs.length < 4)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_tappedTabs.length}/4 discovered',
                style: BunkTheme.of(context).caption.copyWith(
                  fontSize: 10,
                  color: BunkTheme.of(context).accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── STEP 4: Stats Card ────────────────────────────────────

  Widget _buildStep4StatsCard(BuildContext context) {
    const mockName = 'Maths';
    const mockTotal = 40;
    const mockSkipped = 9;
    const mockAttended = mockTotal - mockSkipped;
    const mockPercentage = mockAttended / mockTotal; // 77.5%
    const mockDesired = 0.75;

    // Calculate mock skip balance and recovery
    final allowedMisses = (mockTotal * (1 - mockDesired)).floor();
    final skipBalanceRaw = allowedMisses - mockSkipped;
    final skipBalance = skipBalanceRaw < 0
        ? 0
        : (skipBalanceRaw > 999 ? 999 : skipBalanceRaw);
    final classesToAttendRaw =
        ((mockSkipped - mockTotal * (1 - mockDesired)) / (1 - mockDesired))
            .ceil();
    final classesToAttend = classesToAttendRaw < 0
        ? 0
        : (classesToAttendRaw > 999 ? 999 : classesToAttendRaw);

    Color progressColor;
    if (mockPercentage < mockDesired) {
      progressColor = BunkTheme.of(context).red;
    } else if (mockPercentage >= mockDesired + 0.05) {
      progressColor = BunkTheme.of(context).green;
    } else {
      progressColor = BunkTheme.of(context).yellow;
    }

    return _buildStepCard(
      context,
      stepNumber: 4,
      title: 'VIEW SUBJECT DETAILS',
      subtitle: 'Tap the card to see detailed stats',
      isDone: _step4Done,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showMockSubjectDetails(
            context,
            mockName,
            mockPercentage,
            mockTotal,
            mockAttended,
            mockSkipped,
            progressColor,
            skipBalance,
            classesToAttend,
          );
          setState(() => _step4Done = true);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BunkTheme.of(context).background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mockName,
                    style: BunkTheme.of(
                      context,
                    ).bodyBold.copyWith(fontSize: 16),
                  ),
                  Text(
                    '${(mockPercentage * 100).toStringAsFixed(1)}%',
                    style: BunkTheme.of(
                      context,
                    ).bodyBold.copyWith(fontSize: 16, color: progressColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: mockPercentage),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: BunkTheme.of(context).lightGrey,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: val,
                      child: Container(
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMockPill(context, 'Skip balance: $skipBalance'),
                    const SizedBox(width: 6),
                    _buildMockPill(
                      context,
                      'Missed $mockSkipped of $mockTotal',
                    ),
                  ],
                ),
              ),
              if (!_step4Done)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.hand_draw,
                          size: 14,
                          color: BunkTheme.of(context).grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to see full details',
                          style: BunkTheme.of(context).caption.copyWith(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockPill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BunkTheme.of(context).white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BunkTheme.of(context).lightGrey),
      ),
      child: Text(
        text,
        style: BunkTheme.of(context).caption.copyWith(fontSize: 11),
      ),
    );
  }

  void _showMockSubjectDetails(
    BuildContext context,
    String name,
    double percentage,
    int total,
    int attended,
    int skipped,
    Color progressColor,
    int skipBalance,
    int classesToAttend,
  ) {
    final mockMissedDates = [
      DateTime(2025, 7, 28),
      DateTime(2025, 7, 21),
      DateTime(2025, 7, 14),
      DateTime(2025, 7, 9),
      DateTime(2025, 7, 3),
    ];

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    String formatDate(DateTime d) {
      return '${weekdayNames[d.weekday - 1]}, ${monthNames[d.month - 1]} ${d.day}, ${d.year}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: BunkTheme.of(context).white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      style: BunkTheme.of(
                        context,
                      ).bodyBold.copyWith(fontSize: 24),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BunkTheme.of(
                        context,
                      ).accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SAMPLE DATA',
                      style: BunkTheme.of(context).caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: BunkTheme.of(context).black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: BunkTheme.of(context).bodyBold.copyWith(
                      fontSize: 36,
                      color: progressColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'Attendance',
                      style: BunkTheme.of(
                        context,
                      ).body.copyWith(color: BunkTheme.of(context).grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildMockDetailRow(context, 'Total Classes', '$total'),
              _buildMockDetailRow(context, 'Attended', '$attended'),
              _buildMockDetailRow(
                context,
                'Missed',
                '$skipped',
                textColor: BunkTheme.of(context).red,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildMockInfoCard(
                context,
                'Skip Balance',
                '$skipBalance classes',
                Icons.event_available,
              ),
              const SizedBox(height: 12),
              if (classesToAttend > 0)
                _buildMockInfoCard(
                  context,
                  'To reach 75%',
                  'Attend $classesToAttend classes in a row',
                  Icons.trending_up,
                ),
              const SizedBox(height: 24),
              Text(
                'Missed Dates',
                style: BunkTheme.of(context).bodyBold.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: mockMissedDates.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_busy,
                            color: BunkTheme.of(context).red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatDate(mockMissedDates[index]),
                            style: BunkTheme.of(context).body,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMockDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: BunkTheme.of(
              context,
            ).body.copyWith(color: BunkTheme.of(context).grey, fontSize: 16),
          ),
          Text(
            value,
            style: BunkTheme.of(
              context,
            ).bodyBold.copyWith(fontSize: 16, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMockInfoCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BunkTheme.of(context).background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BunkTheme.of(context).lightGrey),
      ),
      child: Row(
        children: [
          Icon(icon, color: BunkTheme.of(context).black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BunkTheme.of(context).body.copyWith(
                    color: BunkTheme.of(context).grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: BunkTheme.of(context).bodyBold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Step Card ──────────────────────────────────────

  Widget _buildStepCard(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BunkTheme.of(context).white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? BunkTheme.of(context).accent
              : BunkTheme.of(context).lightGrey,
          width: isDone ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? BunkTheme.of(context).accent
                      : BunkTheme.of(context).background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isDone
                        ? Icon(
                            CupertinoIcons.checkmark_alt,
                            key: const ValueKey('check'),
                            size: 16,
                            color: BunkTheme.of(context).white,
                          )
                        : Text(
                            '$stepNumber',
                            key: const ValueKey('num'),
                            style: BunkTheme.of(
                              context,
                            ).bodyBold.copyWith(fontSize: 13),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BunkTheme.of(
                        context,
                      ).bodyBold.copyWith(fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: BunkTheme.of(
                        context,
                      ).caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
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
