import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Steam 成就图标 — 盾牌形状
/// - 普通：Steam 蓝 #66C0F4 底色 + 白色星号
/// - 全成就：金色底色 + 金色星光版
class SteamAchievementIcon extends StatelessWidget {
  final bool isPerfect;
  final double size;

  const SteamAchievementIcon({
    super.key,
    this.isPerfect = false,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SteamShieldPainter(isPerfect: isPerfect),
    );
  }
}

class _SteamShieldPainter extends CustomPainter {
  final bool isPerfect;

  _SteamShieldPainter({required this.isPerfect});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    Color shieldColor;
    Color accentColor;
    Color starColor;

    if (isPerfect) {
      shieldColor = const Color(0xFFFFD700);
      accentColor = const Color(0xFFFF8C00);
      starColor = const Color(0xFFFFFFFF);
    } else {
      shieldColor = const Color(0xFF66C0F4);
      accentColor = const Color(0xFF4A8BB3);
      starColor = const Color(0xFFFFFFFF);
    }

    // Shield path (trapezoid with rounded corners + flat bottom)
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shieldColor, accentColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path();
    final topInset = w * 0.15;
    final bottomInset = w * 0.35;
    final cornerRadius = w * 0.15;

    // Start at top-left (rounded)
    path.moveTo(topInset, cornerRadius);
    // Top-left corner
    path.quadraticBezierTo(topInset, 0, w * 0.3, 0);
    // Top flat
    path.lineTo(w * 0.7, 0);
    // Top-right corner
    path.quadraticBezierTo(w - topInset, 0, w - topInset, cornerRadius);
    // Right side going down
    path.lineTo(w * 0.85, h * 0.7);
    // Bottom-right rounded corner
    path.quadraticBezierTo(w, h * 0.75, w * 0.85, h * 0.85);
    // Bottom flat narrowing
    path.lineTo(bottomInset, h);
    // Bottom-left rounded corner
    path.quadraticBezierTo(0, h * 0.85, w * 0.15, h * 0.7);
    path.close();
    canvas.drawPath(path, paint);

    // Shield border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);

    // Highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.25), Colors.transparent],
        stops: [0.0, 1.0],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, highlightPaint);

    // Center star
    _drawStar(canvas, cx, cy, w * 0.2, starColor);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Color color) {
    final paint = Paint()..color = color;

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * (3.14159 / 180);
      final innerAngle = (i * 72 + 36 - 90) * (3.14159 / 180);
      final ox = cx + r * math.cos(outerAngle);
      final oy = cy + r * math.sin(outerAngle);
      final ix = cx + r * 0.4 * math.cos(innerAngle);
      final iy = cy + r * 0.4 * math.sin(innerAngle);
      if (i == 0) path.moveTo(ox, oy);
      else path.lineTo(ox, oy);
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
