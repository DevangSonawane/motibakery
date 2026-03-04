import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFD94F1E);
  static const primaryLight = Color(0xFFF28B5B);
  static const primaryPale = Color(0xFFFFF0EB);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFAFAFA);
  static const surfaceGray = Color(0xFFF4F4F4);
  static const textPrimary = Color(0xFF1C1C1C);
  static const textSecondary = Color(0xFF4A4A4A);
  static const textHint = Color(0xFF9E9E9E);
  static const borderLight = Color(0xFFE8E8E8);
  static const borderFocus = Color(0xFFD94F1E);
  static const statusProgress = Color(0xFF1565C0);
  static const statusProgressBg = Color(0xFFE3F2FD);
  static const statusPrepared = Color(0xFF2E7D32);
  static const statusPreparedBg = Color(0xFFE8F5E9);
  static const error = Color(0xFFC62828);
  static const warning = Color(0xFFE65100);
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.interTextTheme();
  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: AppColors.textPrimary,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: AppColors.textPrimary,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.55,
      color: AppColors.textSecondary,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: AppColors.textHint,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1,
      color: AppColors.textPrimary,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1,
      color: AppColors.textPrimary,
    ),
  );

  final scheme = const ColorScheme.light().copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.primaryLight,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black12,
      titleTextStyle: textTheme.displayMedium,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 12,
      ),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 2,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: textTheme.labelLarge,
        foregroundColor: AppColors.primary,
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
      labelStyle: textTheme.labelMedium ?? const TextStyle(),
      secondaryLabelStyle:
          (textTheme.labelMedium ?? const TextStyle()).copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),
  );
}
