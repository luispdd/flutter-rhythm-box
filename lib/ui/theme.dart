import 'package:flutter/material.dart';

// ─── Warm Amber Palette ───
const Color kBgDark = Color(0xFF0C0A09);
const Color kSurface = Color(0xFF1C1917);
const Color kAmber = Color(0xFFF59E0B);
const Color kAmberDark = Color(0xFFD97706);
const Color kAmberLight = Color(0xFFFBBF24);
const Color kTextPrimary = Color(0xFFFAFAF9);

/// Builds the complete app theme used by [MaterialApp].
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBgDark,
    colorScheme: const ColorScheme.dark(
      primary: kAmber,
      onPrimary: Colors.white,
      secondary: kAmberDark,
      surface: kSurface,
      onSurface: kTextPrimary,
      outline: Color(0xFF292524),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: kTextPrimary,
        letterSpacing: 0.3,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kAmber,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
      thumbColor: Colors.white,
      overlayColor: kAmber.withValues(alpha: 0.20),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
