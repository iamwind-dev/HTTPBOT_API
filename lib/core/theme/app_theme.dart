import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_theme_colors.dart';
import '../layout/app_responsive.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme =>
      _buildTheme(const AppThemeColors.light(), Brightness.light);

  static ThemeData get darkTheme =>
      _buildTheme(const AppThemeColors.dark(), Brightness.dark);

  static ThemeData _buildTheme(AppThemeColors colors, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          secondary: colors.secondary,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          onPrimary: colors.textOnPrimary,
          outline: colors.border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.divider,
      iconTheme: IconThemeData(color: colors.iconPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.large),
          ),
          side: BorderSide(color: colors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        constraints: BoxConstraints(maxWidth: AppResponsive.maxSheetWidth),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceMuted,
        hintStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.medium),
          ),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.medium),
          ),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.medium),
          ),
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        bodySmall: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: colors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          color: colors.textOnPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        labelSmall: TextStyle(
          color: colors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
