import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF121212);
  static const surface = Color(0xFF1C1C1C);
  static const surfaceHigh = Color(0xFF262626);
  static const divider = Color(0xFF2E2E2E);
  static const accent = Color(0xFFFFC93C);
  static const text = Color(0xFFF2F2F2);
  static const textDim = Color(0xFF9A9A9A);
  static const expense = Color(0xFFF2F2F2);
  static const income = Color(0xFF4CC38A);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.text),
    ),
    dividerColor: AppColors.divider,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      labelStyle: TextStyle(color: AppColors.textDim),
      hintStyle: TextStyle(color: AppColors.textDim),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    ),
  );
}
