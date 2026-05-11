import 'dart:math' as math;
import 'package:flutter/material.dart';

const _rad = 12.0;

/// 全成就特效包裹器 — 激活的特效叠加在内容卡片上
class EffectCardWrapper extends StatelessWidget {
  final Set<String> effects;
  final Map<String, double> intensity;
  final Widget child;

  const EffectCardWrapper({
    super.key,
    required this.effects,
    this.intensity = const {},
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return child;
    return _Host(effects: effects, intensity: intensity, child: child);
  }
}

// ── 颜色常量 ──
const _rainbow = [
  Color(0xFFFF006E), Color(0xFFFF7633), Color(0xFFFFD700),
  Color(0xFF00E676), Color(0xFF00B0FF), Color(0xFF7C4DFF),
];
const _aurora = [
  Color(0xFF00FF87), Color(0xFF00D4FF), Color(0xFF7B2FFF),
  Color(0xFFFF2D95), Color(0xFFFFB800), Color(0xFF00FF87),
];
const _fireColors = [
  Color(0xFFFF4500), Color(0xFFFF6A00), Color(0xFFFF8C00),
  Color(0xFFFFD700), Color(0xFFFFF44F),
];
const _prismColors = [Color(0xFFFF006E), Color(0xFFFF8C00), Color(0xFFFFD700),
  Color(0xFF00E676), Color(0xFF00B0FF), Color(0xFF7C4DFF), Color(0xFFE040FB)];

final _rng = math.Random(42);
final _pX = List.generate(200, (_) => (_rng.nextDouble() - 0.5) * 2.0);
final _pY = List.generate(200, (_) => (_rng.nextDouble() - 0.5) * 2.0);
final _pOff = List.generate(200, (_) => _rng.nextDouble() * 100.0);

/// ────────────────────────────────────────────────────────────────
class _Host extends StatefulWidget {
  final Set<String> effects;
  final Map<String, double> intensity;
  final Widget child;
  const _Host({required this.effects, required this.intensity, required this.child});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _k(String key) => (widget.intensity[key] ?? 0.7).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final effects = widget.effects;
    if (effects.isEmpty) return widget.child;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, card) {
        final t = _c.value;
        final hasBorders = effects.contains('border_chase') || effects.contains('border_pulse');
        final hasGradients = effects.contains('shimmer') || effects.contains('sweep') ||
            effects.contains('hologram') || effects.contains('frost');
        final hasParticles = effects.contains('meteor') ||
            effects.contains('aurora') || effects.contains('sparks') ||
            effects.contains('lava') || effects.contains('stardust') ||
            effects.contains('scan_pulse');

        // If nothing to overlay, just return the card
        if (!hasBorders && !hasGradients && !hasParticles) return card!;

        // ── Stack 架构 ──
        // Layer 0: Card（未定位，提供固有尺寸）
        // Layer 1+: Positioned.fill 叠加层
        final layers = <Widget>[card!];

        // ── 边框层 ──
        if (effects.contains('border_chase')) {
          final k = _k('border_chase');
          final n = _prismColors.length;
          final phase = (t * n) % n;
          layers.add(Positioned.fill(child: IgnorePointer(child: Container(
            decoration: BoxDecoration(border: Border.all(
              color: _prismColors[phase.floor() % n].withAlpha((35 * k).round()), width: 4,
            )),
          ))));
          layers.add(Positioned.fill(child: IgnorePointer(child: Container(
            decoration: BoxDecoration(border: Border(
              top: BorderSide(color: _prismColors[((phase.floor())    ) % n].withAlpha((110 * k).round()), width: 2.5),
              right: BorderSide(color: _prismColors[((phase.floor()) + 2) % n].withAlpha((95 * k).round()), width: 2.5),
              bottom: BorderSide(color: _prismColors[((phase.floor()) + 4) % n].withAlpha((80 * k).round()), width: 2.5),
              left: BorderSide(color: _prismColors[((phase.floor()) + 6) % n].withAlpha((65 * k).round()), width: 2.5),
            )),
          ))));
        }

        if (effects.contains('border_pulse')) {
          final k = _k('border_pulse');
          final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
          final alpha = (25 + 75 * pulse * k).round().clamp(0, 255);
          layers.add(Positioned.fill(child: IgnorePointer(child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent.withAlpha(alpha), width: 1.5 + pulse * 3),
              boxShadow: [BoxShadow(
                color: Colors.cyanAccent.withAlpha((12 * k).round()),
                blurRadius: 4 + pulse * 16,
                spreadRadius: 1 + pulse * 4,
              )],
            ),
          ))));
        }

        // ── Shader 渐变叠层（foregroundDecoration 只在内容上渲染，不影响边框） ──
        List<BoxDecoration> gradDecorations = [];

        if (effects.contains('shimmer')) {
          final k = _k('shimmer');
          final sweep = math.sin(t * 2 * math.pi);
          gradDecorations.add(BoxDecoration(gradient: LinearGradient(
            begin: Alignment(-1 + sweep * 0.6, -1),
            end: Alignment(1 - sweep * 0.6, 1),
            colors: [
              Colors.transparent,
              _lerpList(_rainbow, t).withAlpha((45 * k).round()),
              _lerpList(_rainbow, t + 0.17).withAlpha((35 * k).round()),
              _lerpList(_rainbow, t + 0.33).withAlpha((20 * k).round()),
              Colors.transparent,
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          )));
        }

        if (effects.contains('sweep')) {
          final k = _k('sweep');
          final pos = math.sin(t * math.pi * 2);
          gradDecorations.add(BoxDecoration(gradient: LinearGradient(
            begin: Alignment(-0.6 + pos * 0.8, -0.4 + pos * 0.6),
            end: Alignment(0.2 + pos * 0.8, 0.4 + pos * 0.6),
            colors: [Colors.transparent, _lerpList(_aurora, t).withAlpha((40 * k).round()), Colors.transparent],
            stops: [0.0, 0.5, 1.0],
          )));
        }

        if (effects.contains('hologram')) {
          final k = _k('hologram');
          final angle = t * 2 * math.pi;
          gradDecorations.add(BoxDecoration(gradient: SweepGradient(
            center: Alignment(math.cos(angle) * 0.4, math.sin(angle) * 0.4),
            startAngle: angle, endAngle: angle + math.pi * 2,
            colors: [
              _prismColors[0].withAlpha((20 * k).round()),
              _prismColors[2].withAlpha((35 * k).round()),
              _prismColors[4].withAlpha((20 * k).round()),
              _prismColors[6].withAlpha((35 * k).round()),
              _prismColors[1].withAlpha((20 * k).round()),
              _prismColors[3].withAlpha((35 * k).round()),
              _prismColors[0].withAlpha((20 * k).round()),
            ],
          )));
          gradDecorations.add(BoxDecoration(gradient: SweepGradient(
            center: Alignment(-math.cos(angle) * 0.3, -math.sin(angle) * 0.3),
            startAngle: -angle, endAngle: -angle + math.pi,
            colors: [Colors.transparent, Colors.white.withAlpha((10 * k).round()), Colors.transparent],
            stops: [0.0, 0.5, 1.0],
          )));
        }

        if (effects.contains('frost')) {
          final k = _k('frost');
          final phase = t * 0.4;
          final hx = 0.3 * math.cos(phase * 2 * math.pi);
          final hy = 0.3 * math.sin(phase * 2 * math.pi);
          gradDecorations.add(BoxDecoration(gradient: RadialGradient(
            center: Alignment(hx, hy),
            radius: 0.7 + 0.3 * math.sin(phase * 1.3),
            colors: [
              Colors.white.withAlpha((10 * k).round()),
              const Color(0xFFB0C4DE).withAlpha((6 * k).round()),
              Colors.transparent, Colors.transparent,
            ],
            stops: [0.0, 0.3, 0.5, 1.0],
          )));
        }

        // 合并所有渐变字段到一个叠层（减少 Positioned.fill 数量）
        if (gradDecorations.isNotEmpty) {
          Widget overlay = Container();
          for (final d in gradDecorations) {
            overlay = Container(foregroundDecoration: d, child: overlay);
          }
          layers.add(Positioned.fill(child: IgnorePointer(child: overlay)));
        }

        // ── 粒子层 ──
        if (hasParticles) {
          layers.add(Positioned.fill(
            child: IgnorePointer(
              child: _ParticleOverlay(effects: effects, intensity: widget.intensity, time: t),
            ),
          ));
        }

        return Stack(children: layers);
      },
      child: widget.child,
    );
  }

  Color _lerpList(List<Color> cols, double t) {
    final n = cols.length;
    final pos = (t * n) % n;
    final i = pos.floor();
    final j = (i + 1) % n;
    return Color.lerp(cols[i], cols[j], pos - i)!;
  }
}

/// ════════════════════════════════════════════════════════════════
/// 粒子层
/// ════════════════════════════════════════════════════════════════
class _ParticleOverlay extends StatelessWidget {
  final Set<String> effects;
  final Map<String, double> intensity;
  final double time;
  const _ParticleOverlay({required this.effects, required this.intensity, required this.time});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParticlePainter(effects: effects, intensity: intensity, time: time),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Set<String> effects;
  final Map<String, double> intensity;
  final double time;
  _ParticlePainter({required this.effects, required this.intensity, required this.time});

  double get t => time;
  double _k(String key) => (intensity[key] ?? 0.7).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;

    if (effects.contains('meteor')) _drawMeteor(canvas, w, h);
    if (effects.contains('aurora')) _drawAurora(canvas, w, h);
    if (effects.contains('sparks')) _drawSparks(canvas, w, h);
    if (effects.contains('lava')) _drawLava(canvas, w, h);
    if (effects.contains('stardust')) _drawStardust(canvas, w, h);
    if (effects.contains('scan_pulse')) _drawScanPulse(canvas, w, h);
  }

  void _drawMeteor(Canvas c, double w, double h) {
    final k = _k('meteor');
    if (k <= 0) return;
    // 流星群：首尾相连的连续光带，淡入淡出
    // 每隔 1.0 秒产生一条连续光带，光带总长 = w * 0.6
    final chainId = (t / 1.0).floor();
    final chainT = (t / 1.0) % 1.0;  // 0→1 一条光带生命周期
    if (chainT < 0.05 || chainT > 0.95) return; // 头尾留白

    // 光带由 60 个点组成，点间距均匀，跨越 w * 0.6 宽度
    final numPoints = 60;
    final baseX = w * (0.2 + (chainId * 7 % 37) / 37.0 * 0.2); // 不同波次的x起始偏移
    final baseY = h * (0.1 + (chainId * 13 % 53) / 53.0 * 0.6);
    // 光带走正弦路径
    final freq = 6.0 + (chainId % 5) * 0.5; // 每波频率不同
    final amp = h * 0.04;
    final chordLen = w * 0.55;

    // 淡入淡出区间（前10%淡入，后10%淡出）
    final fadeIn = 0.10;
    final fadeOut = 0.15;

    for (int i = 0; i < numPoints; i++) {
      final pos = i / numPoints;
      // 淡入淡出
      double alpha;
      if (pos < fadeIn) {
        alpha = pos / fadeIn;          // 0→1
      } else if (pos > 1.0 - fadeOut) {
        alpha = (1.0 - pos) / fadeOut; // 1→0
      } else {
        alpha = 1.0;
      }
      // 点沿光带位置
      final px = baseX + chordLen * pos;
      final py = baseY + math.sin(pos * freq * math.pi + chainT * math.pi * 2) * amp;
      // 点大小：中间大两端小
      final sz = (0.8 + alpha * 1.2) * k * (0.5 + 0.5 * (1.0 - (pos - 0.5).abs() * 2));
      // 颜色：从尾到头渐变为亮白（淡蓝/淡紫/白）
      final hue = 220 + pos * 40; // 淡蓝→淡紫
      final col = HSLColor.fromAHSL((alpha * 0.9 * k), hue, 0.6, 0.7 + 0.3 * pos)
          .toColor();
      c.drawCircle(Offset(px, py), sz.clamp(0.3, 2.5), Paint()..color = col);

      // 点之间连线 → 形成连续光带
      if (i > 0) {
        final prevPos = (i - 1) / numPoints;
        final prevAlpha = prevPos < fadeIn ? prevPos / fadeIn :
            (prevPos > 1.0 - fadeOut ? (1.0 - prevPos) / fadeOut : 1.0);
        final prevX = baseX + chordLen * prevPos;
        final prevY = baseY + math.sin(prevPos * freq * math.pi + chainT * math.pi * 2) * amp;
        final lineA = ((prevAlpha + alpha) / 2 * 0.5 * k * 255).round().clamp(0, 255);
        c.drawLine(Offset(prevX, prevY), Offset(px, py), Paint()
          ..color = Colors.white.withAlpha(lineA)
          ..strokeWidth = sz.clamp(0.5, 3.0));
      }

      // 头部光晕（光带最前端）
      if (i == numPoints - 1 && alpha > 0.3) {
        final glowR = sz * 5;
        final glow = Paint()..shader = RadialGradient(
          colors: [
            Colors.white.withAlpha((40 * k * alpha).round()),
            Colors.white.withAlpha((10 * k * alpha).round()),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(px, py), radius: glowR));
        c.drawCircle(Offset(px, py), glowR, glow);
      }

      // 尾部星点拖尾（光带最后端）
      if (i < 3 && alpha > 0.1) {
        final tS = sz * (1.0 - i / 3.0) * 0.5;
        c.drawCircle(Offset(px, py), tS.clamp(0.2, 1.0), Paint()
          ..color = Colors.white.withAlpha((alpha * 60 * k * (1.0 - i / 3.0)).round().clamp(0, 255)));
      }
    }
  }

  void _drawAurora(Canvas c, double w, double h) {
    final k = _k('aurora');
    if (k <= 0) return;
    for (int b = 0; b < 4; b++) {
      final phase = t * 0.5 + b * 0.25;
      final cy = h * (0.2 + 0.6 * (0.3 + 0.4 * math.sin(phase)));
      final amp = h * 0.08;
      final period = 0.02 + b * 0.005;
      final col = _aurora[(b + (t * 2).floor()) % _aurora.length];
      final path = Path();
      for (double x = 0; x <= w; x += 4) {
        final y = cy + math.sin(x * period + phase * 4) * amp;
        if (x == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      c.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 + math.sin(phase * 3) * 6
        ..shader = LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight,
          colors: [Colors.transparent, col.withAlpha((50 * k).round()), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, cy - amp, w, amp * 2)));
    }
  }

  void _drawSparks(Canvas c, double w, double h) {
    final k = _k('sparks');
    if (k <= 0) return;
    final count = (30 * k).round().clamp(15, 50);
    for (int i = 0; i < count; i++) {
      final seed = i * 13;
      // 每个火星随机速度、随机出生 x 位置
      final speed = 0.3 + (seed % 100) / 100.0 * 0.5;
      final phase = ((t * 0.6 + i * 0.08 / count) % 1.0);
      final fade = math.sin(phase * math.pi);
      // 🔀 完全随机出生 x 位置（卡片底部任意水平位置）
      final spawnX = w * (0.03 + (seed * 7 % 97) / 97.0 * 0.94);
      // 随机偏移量
      final drift = ((seed * 11) % 50) / 50.0 - 0.5;
      final x = spawnX + drift * w * 0.06;
      // 从底部上升到顶部上方
      final y = h * (1.0 - phase * 0.95);
      // 水平晃动每个火星不同
      final wobble = math.sin(t * 2.5 + i * 0.5) * w * (0.01 + (seed % 30) / 300.0);
      final sz = (0.5 + fade * 1.8) * k;
      final a = (fade * 0.9 * k * 255).round().clamp(0, 255);
      final color = _fireColors[i % _fireColors.length].withAlpha(a);
      c.drawCircle(Offset((x + wobble).clamp(0.0, w), y), sz.clamp(0.3, 2.5), Paint()..color = color);
      if (phase > 0.05 && phase < 0.85) {
        c.drawCircle(Offset((x + wobble * 0.5).clamp(0.0, w), (y + sz * 1.5).clamp(0.0, h)),
            sz * 0.4, Paint()..color = color.withAlpha((a * 0.25).round()));
      }
    }
  }

  void _drawLava(Canvas c, double w, double h) {
    final k = _k('lava');
    if (k <= 0) return;
    for (int i = 0; i < 6; i++) {
      final phase = t * 0.3 + i / 6;
      final cx = w * (0.2 + 0.6 * (0.5 + 0.4 * math.sin(phase * 0.7 + i * 1.1)));
      final cy = h * (0.2 + 0.6 * (0.5 + 0.4 * math.cos(phase * 0.5 + i * 0.9)));
      final rx = w * 0.12 * (0.6 + 0.4 * math.sin(phase * 1.3 + i * 0.7));
      final ry = h * 0.12 * (0.6 + 0.4 * math.cos(phase * 1.1 + i * 0.5));
      final rot = math.sin(phase * 0.8) * 0.3;
      final ci = (i + (t * 1.5).floor()) % _fireColors.length;
      final alpha = (30 + 25 * math.sin(phase * 2 + i) + 20 * k).round().clamp(0, 120);
      final path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: (rx + ry) / 2));
      final matrix = Matrix4.identity()
        ..translate(cx, cy)..rotateZ(rot)..scale(rx / ((rx + ry) / 2), ry / ((rx + ry) / 2))..translate(-cx, -cy);
      path.transform(matrix.storage);
      c.drawPath(path, Paint()..color = _fireColors[ci].withAlpha(alpha));
    }
  }

  void _drawStardust(Canvas c, double w, double h) {
    final k = _k('stardust');
    if (k <= 0) return;
    // 40颗星，在框内随机分布，每颗都有淡入淡出
    for (int i = 0; i < 40; i++) {
      final seed = i * 7;
      // 漂移路径
      final driftX = math.sin(t * 0.3 + seed * 0.1) * w * 0.1;
      final driftY = math.cos(t * 0.2 + seed * 0.13) * h * 0.1;
      // 位置：均匀分布在整个卡片内，pad 10% 边距
      final baseX = w * (0.08 + (seed * 23 % 149) / 149.0 * 0.84);
      final baseY = h * (0.08 + (seed * 31 % 131) / 131.0 * 0.84);
      final x = baseX + driftX;
      final y = baseY + driftY;

      // 跳过出界的星星
      if (x < -20 || x > w + 20 || y < -20 || y > h + 20) continue;

      // 每颗星有独立的明灭周期（淡入淡出）
      final twinkleBase = (math.sin(t * 1.5 + seed * 0.7) + 1) / 2;
      // 每颗星随机亮一段时间再暗一段时间（2-5秒周期）
      final darkPhase = (t * 0.3 + seed * 0.037) % 1.0;
      final darkRatio = 0.15 + (seed * 11 % 37) / 37.0 * 0.4; // 暗的比例 15%-55%
      double brightness;
      if (darkPhase < darkRatio) {
        // 暗
        brightness = (darkPhase / darkRatio) * 0.15; // 淡入淡出到微光
      } else {
        brightness = (darkPhase - darkRatio) / (1.0 - darkRatio); // 0→1
        brightness = math.sin(brightness * math.pi); // 正弦缓入缓出
      }
      // 加上高频闪烁
      final sparkle = (math.sin(t * 8 + seed * 1.3) + 1) / 2 * 0.3;
      final totalBright = (brightness * 0.7 + sparkle * 0.3).clamp(0.0, 1.0);

      if (totalBright < 0.08) continue;
      final sz = (0.3 + totalBright * 1.6) * k;
      final a = (totalBright * 0.9 * k * 255).round().clamp(0, 255);
      final color = _prismColors[(i + (t * 0.5).floor()) % _prismColors.length].withAlpha(a);
      c.drawCircle(Offset(x, y), sz.clamp(0.3, 2.8), Paint()..color = color);

      // 十字星芒：较亮时显示
      if (totalBright > 0.5 && sz > 1.0) {
        final gp = Paint()
          ..color = color.withAlpha((a * 0.2).round().clamp(0, 255))
          ..strokeWidth = 0.7;
        c.drawLine(Offset(x - sz * 2.5, y), Offset(x + sz * 2.5, y), gp);
        c.drawLine(Offset(x, y - sz * 2.5), Offset(x, y + sz * 2.5), gp);
      }
    }
  }

  void _drawScanPulse(Canvas c, double w, double h) {
    final k = _k('scan_pulse');
    if (k <= 0) return;
    final cx = w / 2, cy = h / 2;
    final maxR = math.min(w, h) * 0.48;
    final angle = t * 2 * math.pi;
    c.drawLine(Offset(cx, cy), Offset(cx + math.cos(angle) * maxR, cy + math.sin(angle) * maxR), Paint()
      ..color = Colors.cyanAccent.withAlpha((60 * k).round())..strokeWidth = 2.0 * k);
    for (int ring = 0; ring < 3; ring++) {
      final phase = ((t * 0.5 + ring / 3) % 1.0);
      final r = maxR * phase;
      c.drawCircle(Offset(cx, cy), r, Paint()
        ..color = Colors.cyanAccent.withAlpha(((1.0 - phase) * 40 * k).round().clamp(0, 255))
        ..style = PaintingStyle.stroke..strokeWidth = 1.5 * k);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.time != time;
}
