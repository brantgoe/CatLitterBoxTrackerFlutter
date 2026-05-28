import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF101418);
  static const surface = Color(0xFF1B2027);
  static const surfaceHigh = Color(0xFF252C36);
  static const textPrimary = Color(0xFFF2F4F7);
  static const textSecondary = Color(0xFFB6BEC9);

  static const statusOk = Color(0xFF35C759);
  static const statusWarn = Color(0xFFFFB020);
  static const statusOverdue = Color(0xFFFF3B30);

  static const accent = Color(0xFF4F8DF7);
  static const accentPressed = Color(0xFF3B6FCC);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    error: AppColors.statusOverdue,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    cardColor: AppColors.surface,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
