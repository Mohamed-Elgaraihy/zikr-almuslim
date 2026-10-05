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

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.greenDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.goldSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Cairo',
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          color: selected ? AppColors.greenDark : AppColors.inkSoft,
        );
      }),
    ),
    dividerColor: AppColors.line,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.greenDeep,
    ),
  );
}
