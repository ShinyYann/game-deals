import 'dart:math' as math;
import 'package:flutter/material.dart';

const _rad = 12.0;

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

  static const _rainbow = [
    Color(0xFFFF006E), Color(0xFFFF7633), Color(0xFFFFD700),
    Color(0xFF00E676), Color(0xFF00B0FF), Color(0xFF7C4DFF),
  ];

  static const _aurora = [
    Color(0xFF00FF87), Color(0xFF00D4FF), Color(0xFF7B2FFF),
    Color(0xFFFF2D95), Color(0xFFFFB800), Color(0xFF00FF87),
  ];

  static const _chase8 = [
    Color(0xFFFF006E), Color(0xFFE040FB), Color(0xFF7C4DFF),
    Color(0xFF448AFF), Color(0xFF00E5FF), Color(0xFF00E676),
    Color(0xFFFFD700), Color(0xFFFF6D00),
  ];

  static const _particleColors = [
    Color(0xFFFF006E), Color(0xFFFFD700), Color(0xFF00E676),
    Color(0xFF00B0FF), Color(0xFF7C4DFF), Color(0xFFFF7633),
    Color(0xFFE040FB), Color(0xFF00E5FF),
  ];

  final int _particleCount = 60;
  final List<double> _pBaseX = [];
  final List<double> _pBaseY = [];

  _HostState() {
    final rng = math.Random(42);
    for (int i = 0; i < _particleCount; i++) {
      _pBaseX.add((rng.nextDouble() - 0.5) * 1.6);
      _pBaseY.add((rng.nextDouble() - 0.5) * 1.8);
    }
  }

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _k(String key) => (widget.intensity[key] ?? 0.7).clamp(0.0, 1.0);

  BoxDecoration _deco(Gradient? g, {BoxBorder? border}) =>
      BoxDecoration(gradient: g, border: border);

  @override
  Widget build(BuildContext context) {
    final w = widget.effects;
    if (w.isEmpty) return widget.child;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, card) {
        final t = _c.value;
        Widget r = card!;

        // ──────────────────────────────────────────
        // 🔥 余烬 — 中心扩散呼吸光
        // ──────────────────────────────────────────
        if (w.contains('ember')) {
          final k = _k('ember');
          final breathe = 0.6 + 0.4 * math.sin(t * math.pi * 1.7);
          r = _fg(r, _deco(RadialGradient(
            center: Alignment.center,
            radius: 0.25 + breathe * 0.45,
            colors: [
              _lerpList([const Color(0xFFFFEA00), const Color(0xFFFF6D00), const Color(0xFFFF1744)], t * 0.3)
                  .withAlpha((55 * k).round()),
              const Color(0xFFFF6D00).withAlpha((30 * k).round()),
              const Color(0xFFFF1744).withAlpha((12 * k).round()),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          )));
        }

        // ──────────────────────────────────────────
        // 🎯 白金脉冲 — 三层涟漪扩散
        // ──────────────────────────────────────────
        if (w.contains('pulse')) {
          final k = _k('pulse');
          for (int ring = 0; ring < 3; ring++) {
            final phase = (t * 0.6 + ring / 3) % 1.0;
            final r1 = phase * 0.55;
            final r2 = r1 + 0.15;
            r = _fg(r, _deco(RadialGradient(
              center: Alignment.center,
              radius: r2,
              colors: [
                const Color(0x00000000),
                const Color(0x00000000),
                Colors.white.withAlpha((28 * k).round()),
                Colors.white.withAlpha((16 * k).round()),
                const Color(0x00000000),
              ],
              stops: [0.0, r1 / r2, r1 / r2 + 0.03, r1 / r2 + 0.06, 1.0],
            )));
          }
        }

        // ──────────────────────────────────────────
        // 🌈 七彩粒子 — 60粒，三波不规则快运动
        // ──────────────────────────────────────────
        if (w.contains('particles')) {
          final k = _k('particles');
          final spd = 0.5 + k; // 速度随强度：50%→150%
          for (int i = 0; i < _particleCount; i++) {
            final dx = math.sin(t * 2.0 * spd + i * 0.52) * 0.11 +
                       math.cos(t * 1.0 * spd + i * 0.83) * 0.08 +
                       math.sin(t * 3.0 * spd + i * 0.27) * 0.05;
            final dy = math.cos(t * 1.8 * spd + i * 0.61) * 0.11 +
                       math.sin(t * 0.9 * spd + i * 0.74) * 0.08 +
                       math.cos(t * 2.7 * spd + i * 0.39) * 0.05;
            final breathe = 0.35 + 0.65 * math.sin(t * 2.2 * spd + i * 0.48);
            final alpha = (0.20 + breathe * 0.35) * k;
            final size = 0.012 + breathe * 0.030;
            final col = _particleColors[(i + (t * 8).floor()) % _particleColors.length];
            r = _fg(r, _deco(RadialGradient(
              center: Alignment(_pBaseX[i] + dx, _pBaseY[i] + dy),
              radius: size,
              colors: [
                col.withAlpha((alpha * 255).round().clamp(0, 255)),
                col.withAlpha(((alpha * 0.4) * 255).round().clamp(0, 255)),
                const Color(0x00000000),
              ],
              stops: const [0.0, 0.4, 1.0],
            )));
          }
        }

        // ──────────────────────────────────────────
        // ✨ 星辉扫光 — Color.lerp 连续色
        // ──────────────────────────────────────────
        if (w.contains('shimmer')) {
          final k = _k('shimmer');
          final sweep = math.sin(t * 2 * math.pi);
          r = _fg(r, _deco(LinearGradient(
            begin: Alignment(-1 + sweep * 0.6, -1),
            end: Alignment(1 - sweep * 0.6, 1),
            colors: [
              const Color(0x00000000),
              _lerpList(_rainbow, t).withAlpha((45 * k).round()),
              _lerpList(_rainbow, t + 0.17).withAlpha((35 * k).round()),
              _lerpList(_rainbow, t + 0.33).withAlpha((20 * k).round()),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          )));
        }

        // ──────────────────────────────────────────
        // 🌊 流光扫描
        // ──────────────────────────────────────────
        if (w.contains('sweep')) {
          final k = _k('sweep');
          final pos = math.sin(t * math.pi * 2);
          r = _fg(r, _deco(LinearGradient(
            begin: Alignment(-0.6 + pos * 0.8, -0.4 + pos * 0.6),
            end: Alignment(0.2 + pos * 0.8, 0.4 + pos * 0.6),
            colors: [
              const Color(0x00000000),
              _lerpList(_aurora, t).withAlpha((40 * k).round()),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.5, 1.0],
          )));
        }

        // ──────────────────────────────────────────
        // 💎 钻石棱光 — 真边框追光，四边顺时针追逐
        // ──────────────────────────────────────────
        if (w.contains('prism')) {
          final k = _k('prism');
          final n = _chase8.length;
          final base = (t * n) % n; // 连续相位，循环无跳
          // 外发光层
          r = _fg(r, _deco(null, border: Border.all(
            color: _chase8[base.floor() % n].withAlpha((30 * k).round()),
            width: 3.5,
          )));
          // 四边核心追逐
          r = _fg(r, _deco(null, border: Border(
            top:    BorderSide(color: _chase8[((base.floor())    ) % n].withAlpha((75 * k).round()), width: 2),
            right:  BorderSide(color: _chase8[((base.floor()) + 2) % n].withAlpha((65 * k).round()), width: 2),
            bottom: BorderSide(color: _chase8[((base.floor()) + 4) % n].withAlpha((55 * k).round()), width: 2),
            left:   BorderSide(color: _chase8[((base.floor()) + 6) % n].withAlpha((45 * k).round()), width: 2),
          )));
        }

        return ColoredBox(
          color: const Color(0xFF121220),
          child: ClipRRect(borderRadius: BorderRadius.circular(_rad), child: r),
        );
      },
      child: widget.child,
    );
  }

  Widget _fg(Widget child, BoxDecoration d) => Container(foregroundDecoration: d, child: child);

  Color _lerpList(List<Color> cols, double t) {
    final n = cols.length;
    final pos = (t * n) % n;
    final i = pos.floor();
    final j = (i + 1) % n;
    return Color.lerp(cols[i], cols[j], pos - i)!;
  }
}
