import 'package:flutter/material.dart';

/// App theme inspired by Daraz's orange branding.
class AppTheme {
  AppTheme._();

  // ── Brand Colors ───────────────────────────────────────────────────────
  static const Color primaryOrange = Color(0xFFF85606);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF232340);
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // ── Light Theme ────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryOrange,
    scaffoldBackgroundColor: surfaceLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryOrange,
      unselectedLabelColor: Colors.grey,
      indicatorColor: primaryOrange,
      dividerHeight: 0.5,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
