import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF12121f);
  static const Color card = Color(0xFF1a1a2e);
  static const Color border = Color(0xFF2a2a3e);
  static const Color text = Color(0xFFe8e8f0);
  static const Color text2 = Color(0xFF999);
  static const Color accent1 = Color(0xFFa855f7);
  static const Color accent2 = Color(0xFF34d399);
  static const Color accent3 = Color(0xFFf97316);
  static const Color accent4 = Color(0xFF5dade2);
  static const Color gold = Color(0xFFfbbf24);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent1,
        secondary: accent2,
        surface: surface,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: text, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text2),
      ),
    );
  }
}
