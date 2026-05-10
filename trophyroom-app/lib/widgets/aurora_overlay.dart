import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ⭐⭐⭐ 动态极光/星云叠加层
/// 平滑呼吸式渐变，不做旋转（旋转看起来像斜线 bug）
/// 颜色根据平台匹配：汇总=紫+蓝 / PSN=紫 / Steam=蓝 / Switch=红+蓝
class AuroraOverlay extends StatefulWidget {
  final List<Color> colors;
  final double speed;
  final bool static;

  const AuroraOverlay({
    super.key,
    required this.colors,
    this.speed = 0.2,
    this.static = false,
  });

  factory AuroraOverlay.psn({bool static = false}) {
    return AuroraOverlay(
      colors: const [Color(0xFF9B59B6), Color(0xFF6C3A9E), Color(0xFFD4A5FF)],
      speed: 0.15,
      static: static,
    );
  }

  factory AuroraOverlay.steam({bool static = false}) {
    return AuroraOverlay(
      colors: const [Color(0xFF3A7BD5), Color(0xFF1A5276), Color(0xFF8EC8F2)],
      speed: 0.15,
      static: static,
    );
  }

  factory AuroraOverlay.switchPlatform({bool static = false}) {
    return AuroraOverlay(
      colors: const [Color(0xFFE60012), Color(0xFF003399), Color(0xFF00A0E9)],
      speed: 0.2,
      static: static,
    );
  }

  factory AuroraOverlay.mixed({bool static = false}) {
    return AuroraOverlay(
      colors: const [Color(0xFF9B59B6), Color(0xFF536DFE), Color(0xFF7C4DFF), Color(0xFF8EC8F2)],
      speed: 0.12,
      static: static,
    );
  }

  @override
  State<AuroraOverlay> createState() => _AuroraOverlayState();
}

class _AuroraOverlayState extends State<AuroraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _pulse = _ctrl.drive(
      Tween<double>(begin: 0.0, end: 1.0),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.static) {
      return _buildGradient(null);
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          return _buildGradient(_pulse.value);
        },
      ),
    );
  }

  Widget _buildGradient(double? pulse) {
    final c = widget.colors;
    final p = pulse ?? 0.5;

    // 呼吸效果：color1 和 color2 的 opacity 缓慢切换
    final color1 = c[0].withOpacity(0.10 + 0.04 * math.sin(p * math.pi));
    final color2 = (c.length > 1 ? c[1] : c[0]).withOpacity(0.06 + 0.03 * math.sin((p + 0.5) * math.pi));
    final color3 = (c.length > 2 ? c[2] : Colors.transparent).withOpacity(0.03 * math.sin((p + 0.25) * math.pi));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2, color3, Colors.transparent],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }
}
