import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core colors
  static const primaryBlue = Color(0xFFDCEFFF);
  static const primaryAction = Color(0xFF1E40AF);
  static const secondary = Color(0xFF7C3AED);
  static const accent = Color(0xFF059669);
  static const error = Color(0xFFDC2626);

  static const darkText = Color(0xFF1E293B);
  static const lightText = Color(0xFF64748B);

  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const surfaceHover = Color(0xFFF1F5F9);

  // Radii
  static const radiusS = 6.0;
  static const radiusM = 10.0;
  static const radiusL = 14.0;

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.light(
          primary: primaryAction,
          secondary: secondary,
          tertiary: accent,
          surface: surface,
          surfaceContainerHighest: surfaceMuted,
          onSurface: darkText,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          error: error,
          onError: Colors.white,
          outline: const Color(0xFFCBD5E1),
          outlineVariant: const Color(0xFFE2E8F0),
        ).copyWith(
          surfaceContainerLow: const Color(0xFFFBFCFE),
          surfaceContainer: surfaceMuted,
          surfaceContainerHigh: surfaceHover,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: primaryBlue,

      // Typography (clean inheritance)
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),

      // AppBar (safe + elegant)
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),

      // Cards (no forced margins)
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      // ✅ Material 3 Filled Buttons (correct replacement)
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(primaryAction),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
          ),
          textStyle: MaterialStateProperty.all(
            GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(darkText),
          side: MaterialStateProperty.all(
            const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(primaryAction),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusM),
            ),
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryAction, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: TextStyle(color: lightText),
      ),

      // Checkbox (fixed visibility)
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? primaryAction
              : Colors.white,
        ),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? accent
              : const Color(0xFF94A3B8),
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? accent.withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryAction,
        unselectedItemColor: lightText,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
