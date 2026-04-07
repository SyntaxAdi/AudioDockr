import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgBase = Color(0xFF0A0A0F);
const Color bgSurface = Color(0xFF0F0F1A);
const Color bgCard = Color(0xFF13131F);
const Color bgDivider = Color(0xFF1E1E2E);
const Color accentPrimary = Color(0xFFF5E642);
const Color accentCyan = Color(0xFF00E5FF);
const Color accentRed = Color(0xFFFF003C);
const Color textPrimary = Color(0xFFE8E8E8);
const Color textSecondary = Color(0xFF8A8A9A);

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bgBase,
  primaryColor: accentPrimary,
  colorScheme: const ColorScheme.dark(
    primary: accentPrimary,
    secondary: accentCyan,
    error: accentRed,
    surface: bgSurface,
    onPrimary: bgBase,
    onSurface: textPrimary,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.rajdhani(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: 0.05 * 32,
    ),
    titleLarge: GoogleFonts.rajdhani(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: GoogleFonts.ibmPlexSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.ibmPlexSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    labelSmall: GoogleFonts.rajdhani(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      letterSpacing: 0.12 * 11,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: bgBase,
    selectedItemColor: accentPrimary,
    unselectedItemColor: textSecondary,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: false,
    selectedLabelStyle: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.15 * 10,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: bgSurface,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: bgDivider, width: 1),
      borderRadius: BorderRadius.zero,
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: accentPrimary, width: 1),
      borderRadius: BorderRadius.zero,
    ),
    hintStyle: TextStyle(fontSize: 15, color: textSecondary),
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accentPrimary,
      foregroundColor: bgBase,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      minimumSize: const Size(0, 48),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.1 * 15),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: accentPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side: const BorderSide(color: accentPrimary, width: 1),
      minimumSize: const Size(0, 48),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
);
