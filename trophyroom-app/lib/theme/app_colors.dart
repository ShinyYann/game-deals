import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── 主色调 ──
  static const Color primary = Color(0xFFA855F7);       // 紫色（白金）
  static const Color primaryLight = Color(0xFFD4A5FF);
  static const Color primaryDark = Color(0xFF7C3AED);

  // ── 平台色 ──
  static const Color psn = Color(0xFF9B59B6);
  static const Color steam = Color(0xFF66C0F4);
  static const Color nintendo = Color(0xFFE60012);

  // ── 基础色 ──
  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF2A2A3E);
  static const Color surfaceCard = Color(0x1AFFFFFF);

  // ── 文本色 ──
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF666666);
  static const Color textAccent = Color(0xFFFFD700);

  // ── 语义色 ──
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ── 阴影色（带色相，不纯黑） ──
  static Color shadow(Color accent) => accent.withAlpha(30);
  static Color shadowStrong(Color accent) => accent.withAlpha(50);
}
