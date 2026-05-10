import 'dart:math' as math;
import 'package:flutter/material.dart';

/// PSN Trophy Icon — 高级感奖杯图标
/// 白金：六边形 #A6B9CB + 蓝色渐变星 + 高光
/// 金：圆形 #F5C444 + 渐变高光 + 皇冠
/// 银：圆形 #B4BBC2 冷银
/// 铜：圆形 #CD7F32 经典铜
/// 未获得：灰度 + 0.3 opacity
class TrophyIcon extends StatelessWidget {
  final String type; // platinum | gold | silver | bronze
  final bool earned;
  final double size;

  const TrophyIcon({
    super.key,
    required this.type,
    this.earned = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isPlatinum = type == 'platinum';
    final isGold = type == 'gold';
    final isSilver = type == 'silver';
    final isBronze = type == 'bronze';

    Color baseColor;
    Color highlightColor;
    Color starColor;

    if (isPlatinum) {
      baseColor = const Color(0xFFA6B9CB);
      highlightColor = const Color(0xFF87CEEB);
      starColor = const Color(0xFF4A90D9);
    } else if (isGold) {
      baseColor = const Color(0xFFF5C444);
      highlightColor = const Color(0xFFFFE082);
      starColor = const Color(0xFFFFD700);
    } else if (isSilver) {
      baseColor = const Color(0xFFB4BBC2);
      highlightColor = const Color(0xFFD0D5DB);
      starColor = const Color(0xFF9CA4AC);
    } else { // bronze
      baseColor = const Color(0xFFCD7F32);
      highlightColor = const Color(0xFFE8A45C);
      starColor = const Color(0xFFD48A3A);
    }

    final opacity = earned ? 1.0 : 0.3;
    final colors = earned
        ? [baseColor, baseColor.withOpacity(0.7)]
        : [Colors.grey, Colors.grey.withOpacity(0.5)];

    return Opacity(
      opacity: opacity,
      child: isPlatinum
          ? _buildHexagon(size, colors, highlightColor, starColor, earned)
          : _buildCircle(size, baseColor, highlightColor, starColor, earned, isGold),
    );
  }

  Widget _buildHexagon(double size, List<Color> colors, Color highlightColor, Color starColor, bool earned) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexagonPainter(colors: colors, highlightColor: highlightColor, earned: earned),
    );
  }

  Widget _buildCircle(double size, Color baseColor, Color highlightColor, Color starColor, bool earned, bool isGold) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CircleTrophyPainter(
        baseColor: baseColor,
        highlightColor: highlightColor,
        starColor: starColor,
        earned: earned,
        isGold: isGold,
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final List<Color> colors;
  final Color highlightColor;
  final bool earned;

  _HexagonPainter({required this.colors, required this.highlightColor, required this.earned});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 1;
    final paint = Paint()
      ..shader = LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)
          .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..style = PaintingStyle.fill;

    // Hexagon path
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * (3.14159 / 180);
      final x = cx + radius * 0.85 * math.cos(angle);
      final y = cy + radius * 0.85 * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Highlight shine
    final shinePaint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withOpacity(0.3),
        Colors.transparent,
      ], stops: [0.0, 1.0])
      .createShader(Rect.fromCircle(center: Offset(cx - radius * 0.3, cy - radius * 0.3), radius: radius));
    canvas.drawPath(path, shinePaint);

    // Star in center
    _drawStar(canvas, cx, cy, radius * 0.3);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r) {
    final starPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A90D9), Color(0xFF357ABD), Color(0xFF63B3ED)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

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
    canvas.drawPath(path, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleTrophyPainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final Color starColor;
  final bool earned;
  final bool isGold;

  _CircleTrophyPainter({
    required this.baseColor,
    required this.highlightColor,
    required this.starColor,
    required this.earned,
    required this.isGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 1;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [baseColor, baseColor.withOpacity(0.7), baseColor.withOpacity(0.5)],
        stops: [0.0, 0.7, 1.0],
        center: const Alignment(0.3, -0.3),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), radius, paint);

    // Highlight gradient
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.35), Colors.transparent],
        stops: [0.0, 1.0],
        center: const Alignment(-0.4, -0.4),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, highlightPaint);

    // Inner ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), radius * 0.7, ringPaint);

    // Trophy / crown shape
    _drawTrophy(canvas, cx, cy, radius * 0.35, isGold);
  }

  void _drawTrophy(Canvas canvas, double cx, double cy, double r, bool isGold) {
    if (isGold) {
      // Crown for gold trophy
      final crownPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.fill;

      final path = Path();
      final topY = cy - r;
      final bottomY = cy + r * 0.6;
      path.moveTo(cx - r * 0.8, bottomY);
      path.lineTo(cx - r * 0.6, topY + r * 0.3);
      path.lineTo(cx - r * 0.25, topY + r * 0.7);
      path.lineTo(cx, topY);
      path.lineTo(cx + r * 0.25, topY + r * 0.7);
      path.lineTo(cx + r * 0.6, topY + r * 0.3);
      path.lineTo(cx + r * 0.8, bottomY);
      path.close();
      canvas.drawPath(path, crownPaint);

      final outlinePaint = Paint()
        ..color = const Color(0xFF333333).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawPath(path, outlinePaint);
    } else {
      _drawStar(canvas, cx, cy, r);
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r) {
    final starPaint = Paint()..color = Colors.white.withOpacity(0.7);

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
    canvas.drawPath(path, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
