import 'package:flutter/material.dart';

/// Font families declared in pubspec.yaml.
class AppFonts {
  static const display = 'Bricolage'; // big numbers and titles
  static const body = 'Instrument'; // everything else
  static const mono = 'PlexMono'; // amounts, dates, labels (passbook print)
}

/// Design tokens. Paper and ink, with the ₱1000-note blue as the only accent.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.hatch,
    required this.accent,
    required this.accentSoft,
    required this.warn,
    required this.danger,
  });

  final Color paper;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color hatch;
  final Color accent;
  final Color accentSoft;
  final Color warn;
  final Color danger;

  static const light = AppColors(
    paper: Color(0xFFF0F2EE),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF161B26),
    muted: Color(0xFF6A7180),
    line: Color(0xFFE0E3DD),
    hatch: Color(0xFFD3D8D0),
    accent: Color(0xFF2D52A0),
    accentSoft: Color(0xFFE3E9F6),
    warn: Color(0xFFB7800A),
    danger: Color(0xFFC0402E),
  );

  static const dark = AppColors(
    paper: Color(0xFF101318),
    surface: Color(0xFF181C23),
    ink: Color(0xFFE7E9ED),
    muted: Color(0xFF949AA6),
    line: Color(0xFF272C35),
    hatch: Color(0xFF353B46),
    accent: Color(0xFF8EA9EC),
    accentSoft: Color(0xFF1E2840),
    warn: Color(0xFFE2AE3C),
    danger: Color(0xFFF07763),
  );

  @override
  AppColors copyWith({
    Color? paper,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? line,
    Color? hatch,
    Color? accent,
    Color? accentSoft,
    Color? warn,
    Color? danger,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      hatch: hatch ?? this.hatch,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      hatch: Color.lerp(hatch, other.hatch, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Text style helpers so screens don't repeat font settings.
class AppText {
  static TextStyle display(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: size >= 28 ? -0.8 : -0.2,
        height: 1.1,
      );

  static TextStyle mono(double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
      TextStyle(fontFamily: AppFonts.mono, fontSize: size, fontWeight: weight, color: color);

  /// Small uppercase label, e.g. "LEFT TO SPEND".
  static TextStyle eyebrow(Color color) => TextStyle(
        fontFamily: AppFonts.mono,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
        color: color,
      );
}

ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;

  final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness).copyWith(
    primary: c.ink,
    onPrimary: c.paper,
    secondary: c.accent,
    onSecondary: c.surface,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.accent,
    secondaryContainer: c.accentSoft,
    onSecondaryContainer: c.ink,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.muted,
    surfaceContainerHighest: c.paper,
    outline: c.line,
    outlineVariant: c.line,
    error: c.danger,
  );

  final rounded12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.paper,
    extensions: [c],
    textTheme: _baseText(brightness, c).merge(TextTheme(
      headlineSmall: AppText.display(26, weight: FontWeight.w600, color: c.ink),
      titleLarge: AppText.display(21, weight: FontWeight.w600, color: c.ink),
      titleMedium: AppText.display(17, weight: FontWeight.w600, color: c.ink),
      bodyLarge: TextStyle(fontSize: 15.5, color: c.ink, height: 1.35),
      bodyMedium: TextStyle(fontSize: 14.5, color: c.ink, height: 1.35),
      bodySmall: TextStyle(fontSize: 12.5, color: c.muted, height: 1.35),
      labelLarge: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
    )),
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 20,
      titleTextStyle: AppText.display(26, weight: FontWeight.w600, color: c.ink),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.line),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: c.muted),
      floatingLabelStyle: TextStyle(color: c.ink, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: c.muted),
      prefixStyle: AppText.mono(15, color: c.ink),
      border: inputBorder(c.line),
      enabledBorder: inputBorder(c.line),
      focusedBorder: inputBorder(c.accent, 1.6),
      errorBorder: inputBorder(c.danger),
      focusedErrorBorder: inputBorder(c.danger, 1.6),
      errorStyle: TextStyle(color: c.danger, fontWeight: FontWeight.w500),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.paper,
        minimumSize: const Size(0, 48),
        shape: rounded12,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        backgroundColor: c.surface,
        side: BorderSide(color: c.line),
        minimumSize: const Size(0, 48),
        shape: rounded12,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: c.surface,
        foregroundColor: c.muted,
        selectedBackgroundColor: c.ink,
        selectedForegroundColor: c.paper,
        side: BorderSide(color: c.line),
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.ink,
      side: BorderSide(color: c.line),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(fontFamily: AppFonts.body, color: c.ink, fontWeight: FontWeight.w500),
      secondaryLabelStyle: TextStyle(fontFamily: AppFonts.body, color: c.paper, fontWeight: FontWeight.w600),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.ink,
      foregroundColor: c.paper,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accentSoft,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? c.ink : c.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? c.accent : c.muted, size: 22);
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: c.hatch,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: AppText.display(20, weight: FontWeight.w600, color: c.ink),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(fontFamily: AppFonts.body, color: c.paper, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.paper,
    ),
    badgeTheme: BadgeThemeData(backgroundColor: c.accent, textColor: c.surface),
  );
}

/// Every default text style uses Instrument Sans. Titles above switch to
/// Bricolage on purpose, so they are merged on top of this base.
TextTheme _baseText(Brightness brightness, AppColors c) {
  final typography = Typography.material2021();
  final base = brightness == Brightness.light ? typography.black : typography.white;
  return base.apply(fontFamily: AppFonts.body, bodyColor: c.ink, displayColor: c.ink);
}
