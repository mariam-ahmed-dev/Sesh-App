import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildSeshTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.egyptianBlue,
    brightness: brightness,
    surface: dark ? AppColors.obsidian : AppColors.sand,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme.copyWith(
      primary: AppColors.egyptianBlue,
      secondary: AppColors.gold,
      surface: dark ? AppColors.obsidian : AppColors.sand,
    ),
    scaffoldBackgroundColor: dark ? AppColors.obsidian : AppColors.sand,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.obsidian : AppColors.sand,
      foregroundColor: dark ? AppColors.limestone : AppColors.ink,
      elevation: 0,
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: dark ? AppColors.limestone : AppColors.ink,
      displayColor: dark ? AppColors.limestone : AppColors.ink,
      fontFamily: 'Georgia',
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.nileMidnight : Colors.white.withValues(alpha: .7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
