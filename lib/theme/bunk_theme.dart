import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class BunkThemeData {
  final Color black;
  final Color white;
  final Color background;
  final Color accent;
  final Color grey;
  final Color lightGrey;
  final Color red;
  final Color green;
  final Color yellow;
  final bool isDark;

  const BunkThemeData({
    required this.black,
    required this.white,
    required this.background,
    required this.accent,
    required this.grey,
    required this.lightGrey,
    required this.red,
    required this.green,
    required this.yellow,
    this.isDark = false,
  });

  Brightness get brightness => isDark ? Brightness.dark : Brightness.light;

  TextStyle get logoStyle => GoogleFonts.teko(
    fontWeight: FontWeight.w700,
    fontSize: 96,
    height: 1.0,
    color: black,
  );

  TextStyle get display => GoogleFonts.teko(
    fontWeight: FontWeight.w700,
    fontSize: 48,
    height: 1.1,
    color: black,
  );

  TextStyle get h1 =>
      GoogleFonts.teko(fontWeight: FontWeight.w700, fontSize: 32, color: black);

  TextStyle get h2 =>
      GoogleFonts.teko(fontWeight: FontWeight.w600, fontSize: 24, color: black);

  TextStyle get bodyBold => GoogleFonts.inter(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: black,
  );

  TextStyle get body => GoogleFonts.inter(
    fontWeight: FontWeight.normal,
    fontSize: 16,
    color: black,
  );

  TextStyle get caption => GoogleFonts.inter(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: grey,
  );

  TextStyle get button => GoogleFonts.bangers(
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: white,
    letterSpacing: 1.2,
  );

  // Themes
  static const BunkThemeData light = BunkThemeData(
    black: Color(0xFF1C1C1E), // True text color
    white: CupertinoColors.white, // Button text / contrast
    background: Color(0xFFF2F2F7),
    accent: Color(0xFFB5E054),
    grey: Color(0xFF8E8E93),
    lightGrey: CupertinoColors.white, // Card surface
    red: Color(0xFFFF3B30),
    green: Color(0xFF34C759),
    yellow: Color(0xFFFFCC00),
    isDark: false,
  );

  static const BunkThemeData dark = BunkThemeData(
    black: Color(0xFFF2F2F7), // True text color
    white: CupertinoColors.black, // Button text / contrast
    background: Color(0xFF121212),
    accent: Color(0xFFB5E054),
    grey: Color(0xFF8E8E93),
    lightGrey: Color(0xFF1C1C1E), // Card surface
    red: Color(0xFFFF453A),
    green: Color(0xFF30D158),
    yellow: Color(0xFFFFD60A),
    isDark: true,
  );

  static const BunkThemeData gruvboxDark = BunkThemeData(
    black: Color(0xFFEBDBB2), // fg
    white: Color(0xFF282828), // bg contrast
    background: Color(0xFF282828), // bg0
    accent: Color(0xFFB8BB26), // green accent
    grey: Color(0xFF928374), // gray
    lightGrey: Color(0xFF3C3836), // bg1 (surface)
    red: Color(0xFFFB4934), // bright red
    green: Color(0xFFB8BB26), // bright green
    yellow: Color(0xFFFABD2F), // bright yellow
    isDark: true,
  );

  static const BunkThemeData gruvboxLight = BunkThemeData(
    black: Color(0xFF3C3836), // fg0
    white: Color(0xFFFBF1C7), // bg contrast
    background: Color(0xFFFBF1C7), // bg0_h
    accent: Color(0xFF79740E), // green accent
    grey: Color(0xFF7C6F64), // gray
    lightGrey: Color(0xFFF2E5BC), // bg1 (surface)
    red: Color(0xFF9D0006), // neutral red
    green: Color(0xFF79740E), // neutral green
    yellow: Color(0xFFB57614), // neutral yellow
    isDark: false,
  );

  static const BunkThemeData oneDark = BunkThemeData(
    black: Color(0xFFABB2BF), // fg
    white: Color(0xFF282C34), // bg contrast
    background: Color(0xFF282C34), // bg
    accent: Color(0xFF61AFEF), // blue accent
    grey: Color(0xFF5C6370), // comment grey
    lightGrey: Color(0xFF21252B), // dark surface
    red: Color(0xFFE06C75),
    green: Color(0xFF98C379),
    yellow: Color(0xFFE5C07B),
    isDark: true,
  );

  static const BunkThemeData oneLight = BunkThemeData(
    black: Color(0xFF383A42), // fg
    white: Color(0xFFFAFAFA), // bg contrast
    background: Color(0xFFFAFAFA), // bg
    accent: Color(0xFF4078F2), // blue accent
    grey: Color(0xFFA0A1A7),
    lightGrey: Color(0xFFEAEAEB), // surface
    red: Color(0xFFE45649),
    green: Color(0xFF50A14F),
    yellow: Color(0xFFC18401),
    isDark: false,
  );

  static const BunkThemeData tokyoNight = BunkThemeData(
    black: Color(0xFFC0CAF5), // fg
    white: Color(0xFF1A1B26), // bg contrast
    background: Color(0xFF1A1B26), // bg
    accent: Color(0xFF7AA2F7), // blue accent
    grey: Color(0xFF565F89),
    lightGrey: Color(0xFF16161E), // dark surface
    red: Color(0xFFF7768E),
    green: Color(0xFF9ECE6A),
    yellow: Color(0xFFE0AF68),
    isDark: true,
  );

  static const BunkThemeData tokyoNightLight = BunkThemeData(
    black: Color(0xFF3760BF), // fg
    white: Color(0xFFE1E2E7), // bg contrast
    background: Color(0xFFE1E2E7), // bg
    accent: Color(0xFF2E7DE9), // blue accent
    grey: Color(0xFF8C90A7),
    lightGrey: Color(0xFFD5D6DB), // surface
    red: Color(0xFFF7768E),
    green: Color.fromARGB(255, 85, 149, 18),
    yellow: Color.fromARGB(255, 178, 119, 31),
    isDark: false,
  );

  static const BunkThemeData dracula = BunkThemeData(
    black: Color(0xFFF8F8F2), // fg
    white: Color(0xFF282A36), // bg contrast
    background: Color(0xFF282A36), // bg
    accent: Color(0xFFBD93F9), // purple accent
    grey: Color(0xFF6272A4), // comment grey
    lightGrey: Color(0xFF21222C), // dark surface
    red: Color(0xFFFF5555),
    green: Color(0xFF50FA7B),
    yellow: Color(0xFFF1FA8C),
    isDark: true,
  );

  static const BunkThemeData draculaLight = BunkThemeData(
    black: Color(0xFF282A36), // fg
    white: Color(0xFFF8F8F2), // bg contrast
    background: Color(0xFFF8F8F2), // bg
    accent: Color(0xFF9447E6), // purple accent
    grey: Color(0xFF6272A4),
    lightGrey: Color(0xFFE9E9E4), // surface
    red: Color(0xFFFF5555),
    green: Color(0xFF42B95C),
    yellow: Color.fromARGB(255, 157, 163, 63),
    isDark: false,
  );

  static BunkThemeData fromName(String name) {
    switch (name) {
      case 'Light':
        return light;
      case 'Dark':
        return dark;
      case 'Gruvbox Dark':
        return gruvboxDark;
      case 'Gruvbox Light':
        return gruvboxLight;
      case 'One Dark':
        return oneDark;
      case 'One Light':
        return oneLight;
      case 'Tokyo Night':
        return tokyoNight;
      case 'Tokyo Night Light':
        return tokyoNightLight;
      case 'Dracula':
        return dracula;
      case 'Dracula Light':
        return draculaLight;
      default:
        return light;
    }
  }

  static const List<String> allThemes = [
    'Light',
    'Dark',
    'Gruvbox Light',
    'Gruvbox Dark',
    'One Light',
    'One Dark',
    'Tokyo Night Light',
    'Tokyo Night',
    'Dracula Light',
    'Dracula',
  ];
}

class BunkTheme extends InheritedWidget {
  final BunkThemeData data;

  const BunkTheme({super.key, required this.data, required super.child});

  static BunkThemeData of(BuildContext context) {
    final BunkTheme? inheritedTheme = context
        .dependOnInheritedWidgetOfExactType<BunkTheme>();
    return inheritedTheme?.data ?? BunkThemeData.light;
  }

  @override
  bool updateShouldNotify(BunkTheme oldWidget) {
    return data != oldWidget.data;
  }
}
