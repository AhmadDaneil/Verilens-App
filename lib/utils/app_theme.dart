import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {

  // ── Shared shape helpers ─────────────────────────────────────────────
  static RoundedRectangleBorder _cardShape(Color dividerColor) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dividerColor, width: 1),
      );

  // ── Light theme (unchanged) ──────────────────────────────────────────
  static ThemeData get lightTheme => _build(brightness: Brightness.light);

  // ── Dark theme ───────────────────────────────────────────────────────
  static ThemeData get darkTheme => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    // ── Semantic colours that flip between modes ─────────────────────
    final background  = isDark ? const Color(0xFF111318) : AppColors.background;
    final surface     = isDark ? const Color(0xFF1E2128) : AppColors.surface;
    final surfaceVar  = isDark ? const Color(0xFF272B34) : const Color(0xFFF1F3F4);
    final divider     = isDark ? const Color(0xFF3C4043) : AppColors.divider;
    final textPrimary = isDark ? const Color(0xFFE8EAED) : AppColors.textPrimary;
    final textSecond  = isDark ? const Color(0xFF9AA0A6) : AppColors.textSecond;
    final textHint    = isDark ? const Color(0xFF5F6368) : AppColors.textHint;
    final primaryLight= isDark ? const Color(0xFF1A3A6B) : AppColors.primaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        background: background,
        surface: surface,
        primary: AppColors.primary,
        error: AppColors.fake,
      ),

      scaffoldBackgroundColor: background,

      // Typography
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,  color: textPrimary),
          displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary),
          titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600,   color: textPrimary),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: textPrimary),
          bodyLarge:   TextStyle(fontSize: 15, color: textPrimary, height: 1.5),
          bodyMedium:  TextStyle(fontSize: 14, color: textSecond,  height: 1.5),
          bodySmall:   TextStyle(fontSize: 12, color: textSecond),
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Card
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: _cardShape(divider),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fake),
        ),
        labelStyle: TextStyle(color: textSecond),
        hintStyle: TextStyle(color: textHint),
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryLight,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return GoogleFonts.inter(fontSize: 12, color: textSecond);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return IconThemeData(color: textSecond);
        }),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: divider, thickness: 1),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceVar,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textPrimary),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold,  color: textPrimary),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textSecond),
      ),
    );
  }
}