import 'dart:math' as math;
import 'package:flutter/material.dart';

/// PSN 风格奖杯图标
/// 用 Canvas 手绘，模拟 PS App 的奖杯样式
class TrophyIcon extends StatelessWidget {
  final String type; // platinum | gold | silver | bronze
  final double size;
  final double opacity; // 0-1, for unearned trophies

  const TrophyIcon({super.key, required this.type, this.size = 28, this.opacity = 1.0});

  /// Creates a widget with custom color overlay (for Image.network errorBuilder compatibility)
  Widget builder(Color? color, BlendMode? blendMode) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color ?? Colors.transparent, blendMode ?? BlendMode.srcIn),
      child: TrophyIcon(type: type, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _TrophyPainter(type: type),
        ),
      ),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  final String type;

  _TrophyPainter({required this.type});

  Color get _baseColor {
    switch (type) {
      case 'platinum': return const Color(0xFF94A3B8);
      case 'gold':     return const Color(0xFFFBBF24);
      case 'silver':   return const Color(0xFF9CA3AF);
      case 'bronze':   return const Color(0xFFD97706);
      default:         return Colors.grey;
    }
  }

  Color get _lightColor {
    switch (type) {
      case 'platinum': return const Color(0xFFCBD5E1);
      case 'gold':     return const Color(0xFFFDE68A);
      case 'silver':   return const Color(0xFFD1D5DB);
      case 'bronze':   return const Color(0xFFFCD34D);
      default:         return Colors.grey[300]!;
    }
  }

  Color get _darkColor {
    switch (type) {
      case 'platinum': return const Color(0xFF475569);
      case 'gold':     return const Color(0xFF92400E);
      case 'silver':   return const Color(0xFF6B7280);
      case 'bronze':   return const Color(0xFF78350F);
      default:         return Colors.grey[700]!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = size.width / 2 - 1.5;
    final paint = Paint()..style = PaintingStyle.fill;
    final double borderW = math.max(1.5, size.width * 0.08);

    // ── 1. 背景圆形/六边形 ──
    if (type == 'platinum') {
      _drawPlatinumBg(canvas, rect, r, center, borderW);
    } else {
      _drawDefaultBg(canvas, center, r, borderW);
    }

    // ── 2. 内部标记 ──
    // 所有类型：在中心画一个奖杯/星形
    _drawInnerMark(canvas, center, r * 0.5, type);
  }

  void _drawPlatinumBg(Canvas canvas, Rect rect, double r, Offset center, double borderW) {
    // 白金：六边形
    final path = Path();
    final hexR = r;
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + hexR * math.cos(angle);
      final y = center.dy + hexR * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();

    // 外边框 - 渐变
    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [_lightColor, _baseColor, _darkColor, _baseColor, _lightColor],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawPath(path, borderPaint..style = PaintingStyle.stroke..strokeWidth = borderW);

    // 内部 - 深色半透明
    final innerPaint = Paint()..color = _darkColor.withOpacity(0.3);
    canvas.drawPath(path, innerPaint..style = PaintingStyle.fill);
  }

  void _drawDefaultBg(Canvas canvas, Offset center, double r, double borderW) {
    // 金/银/铜：圆形外框 + 内部渐变
    final borderPaint = Paint()
      ..shader = RadialGradient(
        colors: [_lightColor, _baseColor, _darkColor],
        radius: 1.0,
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, borderPaint..style = PaintingStyle.fill);

    // 高光
    final highlight = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.3), Colors.transparent],
        radius: 0.6,
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r * 0.65, highlight..style = PaintingStyle.fill);
  }

  void _drawInnerMark(Canvas canvas, Offset center, double size, String type) {
    if (type == 'platinum') {
      // 白金：星星
      _drawStar(canvas, center, size);
    } else {
      // 金/银/铜：简约皇冠/奖杯
      _drawCrown(canvas, center, size);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size) {
    final starPath = Path();
    const spikes = 5;
    final outerR = size;
    final innerR = size * 0.45;

    for (int i = 0; i < spikes * 2; i++) {
      final angle = (math.pi / spikes) * i - math.pi / 2;
      final radius = i.isEven ? outerR : innerR;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) starPath.moveTo(x, y);
      else starPath.lineTo(x, y);
    }
    starPath.close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFE2E8F0), const Color(0xFF94A3B8)],
      ).createShader(Rect.fromCircle(center: center, radius: size));
    canvas.drawPath(starPath, paint);
  }

  void _drawCrown(Canvas canvas, Offset center, double size) {
    // 简约三尖皇冠
    final crownPath = Path();
    final w = size;
    final h = size * 1.1;
    final left = center.dx - w;
    final right = center.dx + w;
    final top = center.dy - h;
    final bottom = center.dy + h;

    crownPath.moveTo(left, bottom);
    crownPath.lineTo(left, top + h * 0.3);
    crownPath.lineTo(center.dx - w * 0.3, center.dy - h * 0.3);
    crownPath.lineTo(center.dx, top);
    crownPath.lineTo(center.dx + w * 0.3, center.dy - h * 0.3);
    crownPath.lineTo(right, top + h * 0.3);
    crownPath.lineTo(right, bottom);
    crownPath.close();

    final paint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawPath(crownPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter oldDelegate) =>
      oldDelegate.type != type;
}
