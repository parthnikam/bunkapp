import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding/onboarding_wrapper.dart';
import 'state.dart';
import 'theme/bunk_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment("SUPABASE_URL");
  const publishableKey = String.fromEnvironment("SUPABASE_PUBLISHABLE_KEY");

  if (supabaseUrl.isNotEmpty && publishableKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: publishableKey);
  }
  runApp(const ProviderScope(child: BunkApp()));
}

class BunkApp extends ConsumerWidget {
  const BunkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeThemeName = ref.watch(
      settingsProvider.select((s) => s.activeTheme),
    );
    final themeData = BunkThemeData.fromName(activeThemeName);

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          themeData.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness:
          themeData.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: themeData.background,
      systemNavigationBarIconBrightness:
          themeData.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return BunkTheme(
      data: themeData,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: CupertinoApp(
          debugShowCheckedModeBanner: false,
          title: 'Bunk',
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          theme: CupertinoThemeData(
            brightness: themeData.brightness,
            primaryColor: themeData.black,
            primaryContrastingColor: themeData.white,
            scaffoldBackgroundColor: themeData.background,
            barBackgroundColor: themeData.background,
            textTheme: CupertinoTextThemeData(
              textStyle: TextStyle(fontFamily: 'Inter', color: themeData.black),
              actionTextStyle: TextStyle(
                fontFamily: 'Inter',
                color: themeData.black,
              ),
              navActionTextStyle: TextStyle(
                fontFamily: 'Inter',
                color: themeData.black,
              ),
              navTitleTextStyle: TextStyle(
                fontFamily: 'Inter',
                color: themeData.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          home: const AppRoot(),
        ),
      ),
    );
  }
}

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  @override
  Widget build(BuildContext context) {
    final init = ref.watch(appInitProvider);

    return init.when(
      data: (_) {
        final isFirstLaunch = ref.watch(
          settingsProvider.select((s) => s.isFirstLaunch),
        );
        if (isFirstLaunch) {
          return const OnboardingWrapper();
        }
        return const MainLayout();
      },
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) =>
          CupertinoPageScaffold(child: Center(child: Text('Error: $err'))),
    );
  }
}

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(uiProvider.select((s) => s.currentTab));

    final screens = [
      const HomeScreen(),
      const CalendarScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return CupertinoPageScaffold(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          IndexedStack(index: currentTab, children: screens),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: BunkTheme.of(context).white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: BunkTheme.of(context).lightGrey,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BunkTheme.of(
                          context,
                        ).black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: currentTab * 68.0 + 8.0,
                        child: Container(
                          width: 52.0,
                          height: 52.0,
                          decoration: BoxDecoration(
                            color: BunkTheme.of(context).black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavItem(
                            context,
                            0,
                            CupertinoIcons.home,
                            currentTab,
                            ref,
                          ),
                          _buildNavItem(
                            context,
                            1,
                            CupertinoIcons.calendar,
                            currentTab,
                            ref,
                          ),
                          _buildNavItem(
                            context,
                            2,
                            CupertinoIcons.chart_bar_alt_fill,
                            currentTab,
                            ref,
                          ),
                          _buildNavItem(
                            context,
                            3,
                            CupertinoIcons.settings,
                            currentTab,
                            ref,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    int currentTab,
    WidgetRef ref,
  ) {
    final isSelected = currentTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(uiProvider.notifier).setTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68.0,
        height: 52.0,
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: isSelected
                  ? BunkTheme.of(context).white
                  : BunkTheme.of(context).grey,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, color, child) {
              return Icon(icon, color: color, size: 28);
            },
          ),
        ),
      ),
    );
  }
}
