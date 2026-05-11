/// 🎊 全成就/白金庆祝弹窗 — 专业特效版
/// ✨ 彩带 + 闪烁繁星 + 闪光粒子 + 毛玻璃卡片 + 排名显示
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 检查并触发庆祝弹窗（只弹一次）
Future<bool> shouldShowCelebration(String gameKey) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'celebration_shown_$gameKey';
  if (prefs.getBool(key) == true) return false;
  await prefs.setBool(key, true);
  return true;
}

/// 🎊 撒花庆祝弹窗
class CelebrationOverlay extends StatefulWidget {
  final String gameName;
  final String platform; // 'psn' | 'steam'
  final String? coverUrl;
  final int trophyCount;
  final String? completedDate;
  final int? rank; // 第几个白金/全成就
  final int? totalCompleted; // 该平台已完成总数

  const CelebrationOverlay({
    super.key,
    required this.gameName,
    required this.platform,
    this.coverUrl,
    this.trophyCount = 0,
    this.completedDate,
    this.rank,
    this.totalCompleted,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  late List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    // 生成粒子
    _particles = List.generate(120, (i) => _Particle(type: i % 5));
    _sparkles = List.generate(30, (_) => _Sparkle());

    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPsn = widget.platform == 'psn';
    final accentColor = isPsn ? const Color(0xFFB8D8D8) : const Color(0xFF66C0F4);

    return Stack(children: [
      // 模糊背景
      Positioned.fill(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withAlpha(160)),
          ),
        ),
      ),
      // 背景闪光层
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _SparklePainter(_sparkles, _controller.value),
          ),
        ),
      ),
      // 前景粒子层（彩带 + 纸屑）
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(_particles, _controller.value),
          ),
        ),
      ),
      // 卡片
      Center(
        child: _CelebrationCard(
          gameName: widget.gameName,
          platform: widget.platform,
          coverUrl: widget.coverUrl,
          trophyCount: widget.trophyCount,
          completedDate: widget.completedDate,
          rank: widget.rank,
          totalCompleted: widget.totalCompleted,
          accentColor: accentColor,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    ]);
  }
}

/// 🃏 庆祝卡片（带 spring 入场 + 发光边框动画）
class _CelebrationCard extends StatefulWidget {
  final String gameName;
  final String platform;
  final String? coverUrl;
  final int trophyCount;
  final String? completedDate;
  final int? rank;
  final int? totalCompleted;
  final Color accentColor;
  final VoidCallback onDismiss;

  const _CelebrationCard({
    required this.gameName,
    required this.platform,
    this.coverUrl,
    required this.trophyCount,
    this.completedDate,
    this.rank,
    this.totalCompleted,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _scaleAnim = CurvedAnimation(
      parent: _cardCtrl,
      curve: const Interval(0, 0.5, curve: Curves.elasticOut),
    );
    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPsn = widget.platform == 'psn';
    final icon = isPsn ? Icons.emoji_events : Icons.star;
    final label = isPsn ? '白金达成' : '全成就';

    return AnimatedBuilder(
      animation: _cardCtrl,
      builder: (ctx, _) {
        final scale = _scaleAnim.value.clamp(0.01, 1.0);
        final glow = _glowAnim.value;
        final glowOpacity = (math.sin(glow * math.pi * 3) * 0.3 + 0.7).clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.accentColor.withAlpha(30),
                  const Color(0xFF16162A).withAlpha(240),
                  widget.accentColor.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.accentColor.withAlpha((180 * glowOpacity).round()),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withAlpha((60 * glowOpacity).round()),
                  blurRadius: 40 * glowOpacity,
                  spreadRadius: 8 * glowOpacity,
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // ── 排名徽章 ──
              if (widget.rank != null && widget.totalCompleted != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor.withAlpha(60),
                        widget.accentColor.withAlpha(20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.accentColor.withAlpha(100),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: widget.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        isPsn ? '第 ${widget.rank! >= 0 ? widget.rank! + 1 : 1} 个白金' : '第 ${widget.rank! >= 0 ? widget.rank! + 1 : 1} 个全成就',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已${isPsn ? "白金" : "全成就"} ${widget.totalCompleted} 款游戏',
                  style: TextStyle(fontSize: 11, color: widget.accentColor.withAlpha(160)),
                ),
                const SizedBox(height: 12),
              ],

              // ── 封面（全宽自适应，封面不再被方形框裁切） ──
              if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: widget.platform == 'steam' ? 16 / 9 : 3 / 4,
                      child: Image.network(
                        widget.coverUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) =>
                          progress == null ? child : Container(color: const Color(0xFF2A2A3E)),
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2A2A3E)),
                      ),
                    ),
                  ),
                ),

              // ── 发光图标 ──
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [widget.accentColor, widget.accentColor.withAlpha(120)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withAlpha((100 * glowOpacity).round()),
                      blurRadius: 20 * glowOpacity,
                      spreadRadius: 4 * glowOpacity,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),

              // ── 恭喜文字 ──
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [widget.accentColor, Colors.white, widget.accentColor],
                ).createShader(bounds),
                child: Text(
                  '🎉 恭喜完成！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                    shadows: [
                      Shadow(color: widget.accentColor.withAlpha(100), blurRadius: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── 游戏名 ──
              Text(
                widget.gameName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // ── 标签 + 数量 ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$label  ·  ${widget.trophyCount} 个${isPsn ? "奖杯" : "成就"}',
                  style: TextStyle(fontSize: 12, color: widget.accentColor.withAlpha(200)),
                ),
              ),

              if (widget.completedDate != null && widget.completedDate!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '达成: ${widget.completedDate}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],

              const SizedBox(height: 18),
              // ── 关闭按钮 ──
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onDismiss,
                  style: TextButton.styleFrom(
                    backgroundColor: widget.accentColor.withAlpha(35),
                    foregroundColor: widget.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('太棒了 ✨', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  粒子/特效 系统
// ════════════════════════════════════════════════════════════════

/// 粒子类型
enum _ParticleType { ribbon, star, confetti, circle, burst }

/// 单个粒子
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double sway;      // 横向摇摆幅度
  final double swayFreq;  // 摇摆频率
  final double rotation;
  final double rotSpeed;
  final Color color;
  final double opacity;
  final _ParticleType type;
  final double delay;     // 延迟时间

  _Particle({required int type}) :
    x = math.Random().nextDouble(),
    y = -0.05 - math.Random().nextDouble() * 0.25,
    size = type == 0 ? 2 + math.Random().nextDouble() * 4         // ribbon: short
                    : type == 1 ? 8 + math.Random().nextDouble() * 12 // star: bigger
                    : type == 2 ? 5 + math.Random().nextDouble() * 7  // confetti
                    : type == 3 ? 6 + math.Random().nextDouble() * 10 // circle
                    : 3 + math.Random().nextDouble() * 6,             // burst
    speed = 0.003 + math.Random().nextDouble() * 0.012,
    sway = (math.Random().nextDouble() - 0.5) * 0.05,
    swayFreq = 5 + math.Random().nextDouble() * 10,
    rotation = math.Random().nextDouble() * 6.28,
    rotSpeed = (math.Random().nextDouble() - 0.5) * 0.15,
    delay = math.Random().nextDouble() * 0.4,
    this.type = _ParticleType.values[type % _ParticleType.values.length],
    color = _randomColor(),
    opacity = 0.7 + math.Random().nextDouble() * 0.3;

  static Color _randomColor() {
    const colors = [
      Color(0xFFFF4757), Color(0xFFFF6B81), Color(0xFFFFD93D), Color(0xFFFFF3B0),
      Color(0xFF6BCB77), Color(0xFF00D2D3), Color(0xFF54A0FF), Color(0xFF5F27CD),
      Color(0xFFFF6BDF), Color(0xFF845EC2), Color(0xFF00C9A7), Color(0xFFFF9671),
      Color(0xFFDDA0DD), Color(0xFF7BED9F), Color(0xFF70A1FF), Color(0xFFF1C40F),
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}

/// ✨ 闪烁星星（背景层）
class _Sparkle {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble() * 0.9 + 0.05;
  final double size = 2 + math.Random().nextDouble() * 5;
  final double phase = math.Random().nextDouble() * 6.28;
  final double freq = 1 + math.Random().nextDouble() * 3;
  final Color color = _Sparkle._color();
  final double delay = math.Random().nextDouble() * 2;

  static Color _color() {
    const colors = [
      Color(0xFFFFFDE7), Color(0xFFE0F7FA), Color(0xFFFCE4EC),
      Color(0xFFFFF176), Color(0xFFB2EBF2), Color(0xFFFFF8E1),
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}

/// 💫 闪光星星绘制器（背景层）
class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double time;

  _SparklePainter(this.sparkles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final t = time + s.delay;
      final alpha = ((math.sin(t * s.freq * math.pi * 2 + s.phase) + 1) / 2).clamp(0.0, 0.9);
      if (alpha < 0.05) continue;

      final cx = s.x * size.width;
      final cy = s.y * size.height;
      final r = s.size * size.width / 400;

      final paint = Paint()
        ..color = s.color.withAlpha((255 * alpha).round())
        ..style = PaintingStyle.fill;

      // 4 角星
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final rad = i.isEven ? r : r * 0.3;
        if (i == 0) {
          path.moveTo(cx + rad * math.cos(angle), cy + rad * math.sin(angle));
        } else {
          path.lineTo(cx + rad * math.cos(angle), cy + rad * math.sin(angle));
        }
      }
      path.close();
      canvas.drawPath(path, paint);

      // 外发光
      if (alpha > 0.5) {
        final glowPaint = Paint()
          ..color = s.color.withAlpha((60 * alpha).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(cx, cy), r * 1.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.time != time;
}

/// 🎊 粒子绘制器（前景层）
class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final effectiveProgress = ((progress - p.delay) / 0.95).clamp(0.0, 1.2);
      if (effectiveProgress <= 0) continue;

      final py = p.y + effectiveProgress * p.speed * size.height / 700;
      if (py < -0.05 || py > 1.1) continue;

      final px = p.x + math.sin(effectiveProgress * p.swayFreq + p.x * 10) * p.sway;
      final rot = p.rotation + effectiveProgress * p.rotSpeed;

      canvas.save();
      canvas.translate(px * size.width, py * size.height);
      canvas.rotate(rot);

      final fadeOut = py > 0.9 ? (1.1 - py) * 10 : 1.0;

      switch (p.type) {
        case _ParticleType.ribbon:
          _drawRibbon(canvas, p, effectiveProgress, fadeOut);
          break;
        case _ParticleType.star:
          _drawStar(canvas, p, fadeOut);
          break;
        case _ParticleType.confetti:
          _drawConfetti(canvas, p, fadeOut);
          break;
        case _ParticleType.circle:
          _drawCircle(canvas, p, fadeOut);
          break;
        case _ParticleType.burst:
          _drawBurst(canvas, p, fadeOut);
          break;
      }
      canvas.restore();
    }
  }

  /// 🎀 彩带（长条矩形 + 渐变）
  void _drawRibbon(Canvas canvas, _Particle p, double t, double fade) {
    final paint = Paint()
      ..color = p.color.withAlpha((255 * p.opacity * fade).round())
      ..style = PaintingStyle.fill;

    final len = 16 + 12 * math.sin(t * 8);
    final skew = 3 * math.sin(t * 12 + p.x);
    final path = Path()
      ..moveTo(-len / 2, -2)
      ..lineTo(len / 2, -2 + skew)
      ..lineTo(len / 2, 2 + skew)
      ..lineTo(-len / 2, 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// ⭐ 星星
  void _drawStar(Canvas canvas, _Particle p, double fade) {
    final r = p.size;
    final paint = Paint()
      ..color = p.color.withAlpha((255 * p.opacity * fade).round())
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final rad = i.isEven ? r : r * 0.4;
      if (i == 0) path.moveTo(rad * math.cos(angle), rad * math.sin(angle));
      else path.lineTo(rad * math.cos(angle), rad * math.sin(angle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 🟨 方纸屑
  void _drawConfetti(Canvas canvas, _Particle p, double fade) {
    final paint = Paint()
      ..color = p.color.withAlpha((255 * p.opacity * fade).round())
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.7), paint);
  }

  /// ⭕ 圆纸屑
  void _drawCircle(Canvas canvas, _Particle p, double fade) {
    final paint = Paint()
      ..color = p.color.withAlpha((200 * p.opacity * fade).round())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, p.size / 2, paint);
  }

  /// 💥 爆散粒子（小点）
  void _drawBurst(Canvas canvas, _Particle p, double fade) {
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + p.rotation;
      final dist = p.size * 0.6 * math.sin(progress * 5 + i);
      final paint = Paint()
        ..color = p.color.withAlpha((150 * p.opacity * fade).round())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(dist * math.cos(angle), dist * math.sin(angle)),
        p.size / 4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
