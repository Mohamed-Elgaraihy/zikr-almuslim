import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFFF6F1E7);
  static const paperDeep = Color(0xFFEADFCB);
  static const ink = Color(0xFF1C2420);
  static const inkSoft = Color(0xFF5C675F);
  static const green = Color(0xFF0E6B4F);
  static const greenDark = Color(0xFF083C2E);
  static const greenDeep = Color(0xFF06261E);
  static const gold = Color(0xFFB08948);
  static const goldSoft = Color(0xFFF3E6C8);
  static const card = Color(0xFFFFFCF7);
  static const line = Color(0xFFE4D9C4);
  static const done = Color(0xFFE7F6EE);
  static const virtue = Color(0xFF3D6B56);
  static const alert = Color(0xFF8A4B12);
  static const alertWash = Color(0xFFFFF3E4);
}

TextStyle? _scale(TextStyle? style) {
  if (style == null) return null;
  final size = style.fontSize;
  return style.copyWith(
    fontFamily: 'Cairo',
    fontSize: size == null ? null : size * 1.16,
  );
}

ThemeData buildTheme({bool dark = false}) {
  final palette = dark ? AppPalette.dark : AppPalette.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: palette.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: dark ? palette.green : AppColors.green,
      onPrimary: dark ? AppColors.greenDeep : Colors.white,
      secondary: palette.gold,
      surface: palette.paper,
      onSurface: palette.ink,
    ),
  );
  final source = base.textTheme;
  return base.copyWith(
    textTheme: source.copyWith(
      displayLarge: _scale(source.displayLarge),
      displayMedium: _scale(source.displayMedium),
      displaySmall: _scale(source.displaySmall),
      headlineLarge: _scale(source.headlineLarge),
      headlineMedium: _scale(source.headlineMedium),
      headlineSmall: _scale(source.headlineSmall),
      titleLarge: _scale(source.titleLarge),
      titleMedium: _scale(source.titleMedium),
      titleSmall: _scale(source.titleSmall),
      bodyLarge: _scale(source.bodyLarge),
      bodyMedium: _scale(source.bodyMedium),
      bodySmall: _scale(source.bodySmall),
      labelLarge: _scale(source.labelLarge),
      labelMedium: _scale(source.labelMedium),
      labelSmall: _scale(source.labelSmall),
    ),
    extensions: [palette],
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.greenDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.card,
      indicatorColor: palette.goldSoft,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Cairo',
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 15,
          color: selected ? palette.greenDark : palette.inkSoft,
        );
      }),
    ),
    dividerColor: palette.line,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.greenDeep,
    ),
  );
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.inkSoft,
    required this.green,
    required this.greenDark,
    required this.greenDeep,
    required this.gold,
    required this.goldSoft,
    required this.card,
    required this.line,
    required this.done,
    required this.virtue,
    required this.alert,
    required this.alertWash,
  });

  final Color paper;
  final Color paperDeep;
  final Color ink;
  final Color inkSoft;
  final Color green;
  final Color greenDark;
  final Color greenDeep;
  final Color gold;
  final Color goldSoft;
  final Color card;
  final Color line;
  final Color done;
  final Color virtue;
  final Color alert;
  final Color alertWash;

  static const light = AppPalette(
    paper: AppColors.paper,
    paperDeep: AppColors.paperDeep,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    green: AppColors.green,
    greenDark: AppColors.greenDark,
    greenDeep: AppColors.greenDeep,
    gold: AppColors.gold,
    goldSoft: AppColors.goldSoft,
    card: AppColors.card,
    line: AppColors.line,
    done: AppColors.done,
    virtue: AppColors.virtue,
    alert: AppColors.alert,
    alertWash: AppColors.alertWash,
  );

  static const dark = AppPalette(
    paper: Color(0xFF10211B),
    paperDeep: Color(0xFF1A2E27),
    ink: Color(0xFFF3F7F4),
    inkSoft: Color(0xFFB7C6BE),
    green: Color(0xFF3DDC97),
    greenDark: Color(0xFFD7F5E8),
    greenDeep: Color(0xFF04140F),
    gold: Color(0xFFE2C48A),
    goldSoft: Color(0xFF3A3326),
    card: Color(0xFF1A2C25),
    line: Color(0xFF2C433A),
    done: Color(0xFF1B3A2E),
    virtue: Color(0xFF8FCBB0),
    alert: Color(0xFFE7B07A),
    alertWash: Color(0xFF3A2A1C),
  );

  @override
  AppPalette copyWith({
    Color? paper,
    Color? paperDeep,
    Color? ink,
    Color? inkSoft,
    Color? green,
    Color? greenDark,
    Color? greenDeep,
    Color? gold,
    Color? goldSoft,
    Color? card,
    Color? line,
    Color? done,
    Color? virtue,
    Color? alert,
    Color? alertWash,
  }) {
    return AppPalette(
      paper: paper ?? this.paper,
      paperDeep: paperDeep ?? this.paperDeep,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      green: green ?? this.green,
      greenDark: greenDark ?? this.greenDark,
      greenDeep: greenDeep ?? this.greenDeep,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      card: card ?? this.card,
      line: line ?? this.line,
      done: done ?? this.done,
      virtue: virtue ?? this.virtue,
      alert: alert ?? this.alert,
      alertWash: alertWash ?? this.alertWash,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      paper: mix(paper, other.paper),
      paperDeep: mix(paperDeep, other.paperDeep),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      green: mix(green, other.green),
      greenDark: mix(greenDark, other.greenDark),
      greenDeep: mix(greenDeep, other.greenDeep),
      gold: mix(gold, other.gold),
      goldSoft: mix(goldSoft, other.goldSoft),
      card: mix(card, other.card),
      line: mix(line, other.line),
      done: mix(done, other.done),
      virtue: mix(virtue, other.virtue),
      alert: mix(alert, other.alert),
      alertWash: mix(alertWash, other.alertWash),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
