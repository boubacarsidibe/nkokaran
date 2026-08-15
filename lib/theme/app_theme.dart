import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette lifted 1:1 from the web app's CSS custom properties.
class AppColors {
  static const bg = Color(0xFFF1E7D2);
  static const ink = Color(0xFF241C13);
  static const indigo = Color(0xFF2C3A63);
  static const indigoDark = Color(0xFF1E2A48);
  static const clay = Color(0xFF9C4222);
  static const gold = Color(0xFFC79A3E);
  static const green = Color(0xFF4F7A4A);
  static const red = Color(0xFFB23A2E);
  static const card = Color(0xFFFFFBF1);
  static const line = Color(0xFFDDD0AF);
  static const lockedNode = Color(0xFFE4D8BA);
  static const lockedIcon = Color(0xFFA99B78);
  static const correctBg = Color(0xFFE4EEDE);
  static const wrongBg = Color(0xFFF6DEDA);
  static const selectedBg = Color(0xFFEFE6CF);
}

class AppText {
  static TextStyle fraunces({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.ink,
    double? letterSpacing,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.ink,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle nko({
    double fontSize = 40,
    Color color = AppColors.ink,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      GoogleFonts.notoSansNKo(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      surface: AppColors.bg,
    ),
    splashFactory: NoSplash.splashFactory,
  );
}
