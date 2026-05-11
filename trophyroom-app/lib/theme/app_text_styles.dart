import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Font family constants ──
  /// Chinese display font – bold, game-style Chinese characters
  static const String _cnFont = 'ZCOOLQingKeHuangYou';
  /// Sci-fi English / numeric display font
  static const String _enFont = 'Orbitron';

  // ── 标题层级 (Orbitron for English/numbers + ZCOOL for Chinese) ──
  static const TextStyle h1 = TextStyle(
    fontFamily: _enFont,
    fontWeight: FontWeight.w700,  // Bold
    fontSize: 24,
    color: Color(0xFFF0F0F0),
    letterSpacing: 1.2,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: _enFont,
    fontWeight: FontWeight.w600,  // SemiBold
    fontSize: 20,
    color: Color(0xFFF0F0F0),
    letterSpacing: 0.8,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: _enFont,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Color(0xFFF0F0F0),
    letterSpacing: 0.5,
  );

  // ── 正文层级 (Chinese font for ALL body text) ──
  static const TextStyle body = TextStyle(
    fontFamily: _cnFont,
    fontWeight: FontWeight.w400,  // Regular
    fontSize: 14,
    color: Color(0xFFB0B0B0),
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _cnFont,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: Color(0xFF666666),
    height: 1.4,
  );

  // ── 数字/强调 (Orbitron for stats/numbers) ──
  static const TextStyle stat = TextStyle(
    fontFamily: _enFont,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: Color(0xFFF0F0F0),
  );
  static const TextStyle label = TextStyle(
    fontFamily: _cnFont,
    fontWeight: FontWeight.w300,  // Light
    fontSize: 11,
    color: Color(0xFF666666),
    letterSpacing: 0.8,
  );

  // ── ThemeData 集成 ──
  static TextTheme get textTheme => const TextTheme(
    displayLarge: h1,
    displayMedium: h2,
    displaySmall: h3,
    bodyLarge: body,
    bodyMedium: bodySmall,
    labelSmall: label,
  );
}
