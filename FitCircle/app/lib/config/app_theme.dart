// lib/config/app_theme.dart
// FitCircle — Global theme definition
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const bgPrimary    = Color(0xFF080C17);
  static const bgSecondary  = Color(0xFF0D1224);
  static const bgCard       = Color(0xFF111827);
  static const bgCardHover  = Color(0xFF161E30);

  static const purple       = Color(0xFF7C3AED);
  static const purpleLight  = Color(0xFF9B59F5);
  static const orange       = Color(0xFFF97316);
  static const orangeLight  = Color(0xFFFB923C);
  static const green        = Color(0xFF22C55E);
  static const gold         = Color(0xFFF59E0B);
  static const red          = Color(0xFFEF4444);

  static const textPrimary   = Color(0xFFF9FAFB);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted     = Color(0xFF6B7280);

  static const border       = Color(0x14FFFFFF);  // rgba(255,255,255,0.08)
  static const borderAccent = Color(0x667C3AED);  // rgba(124,58,237,0.4)

  static const gradientStart = purple;
  static const gradientEnd   = orange;

  static LinearGradient get mainGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      purple.withOpacity(0.15),
      orange.withOpacity(0.08),
    ],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.purple,
      secondary: AppColors.orange,
      surface:   AppColors.bgCard,
      error:     AppColors.red,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      bodyLarge:  GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
      bodySmall:  GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPrimary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgSecondary,
      selectedItemColor: AppColors.purple,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.purple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgCard,
      contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
