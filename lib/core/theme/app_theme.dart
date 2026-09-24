import 'package:flutter/material.dart';
import '../../modules/business_type.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData getTheme({
    required BusinessType businessType,
    required bool isDark,
  }) {
    final primary = businessType.primaryColor;
    final secondary = businessType.secondaryColor;

    final baseBackground = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final baseSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final baseCard = isDark ? AppColors.cardDark : AppColors.cardLight;
    final baseBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: baseSurface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: baseBackground,
      canvasColor: baseBackground,
      dividerColor: baseBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: baseSurface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: baseCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderLG,
          side: BorderSide(color: baseBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.borderMD,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: baseBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.borderMD,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppTokens.borderMD,
          borderSide: BorderSide(color: baseBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderMD,
          borderSide: BorderSide(color: baseBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderMD,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(color: textSecondary.withAlpha(180), fontSize: 14),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: baseSurface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: baseSurface,
        selectedIconTheme: IconThemeData(color: primary),
        selectedLabelTextStyle: TextStyle(color: primary, fontWeight: FontWeight.w600),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        unselectedLabelTextStyle: TextStyle(color: textSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: baseSurface,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderXL),
        elevation: 12,
      ),
    );
  }
}
