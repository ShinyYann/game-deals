import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 粒子引擎 — 支持浮游粒子、爆发、雨滴、星辉等多种模式
/// 使用 Ticker 驱动，无循环跳变，时间持续递增
class ParticleEngine extends StatefulWidget {
  final ParticleConfig config;

  const ParticleEngine({super.key, required this.config});

  @override
  State<ParticleEngine> createState() => _ParticleEngineState();
}

class _ParticleEngineState extends State<ParticleEngine>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final _rng = math.Random(42);
  late List<_Particle> _particles;
  late ParticleConfig _config;
  double _totalTime = 0;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _particles = _spawnParticles(_config.count);
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    _totalTime += dt;
    // 只触发重绘，不触发 setState（性能更好）
    setState(() {}); // CustomPaint 需要 build 刷新
  }

  @override
  void didUpdateWidget(ParticleEngine old) {
    super.didUpdateWidget(old);
    if (old.config != widget.config) {
      setState(() => _config = widget.config);
    }
  }

  List<_Particle> _spawnParticles(int count) {
    return List.generate(count, (_) {
      final mode = _config.mode;
      double x, y, vx, vy;
      switch (mode) {
        case ParticleMode.burst:
          final angle = _rng.nextDouble() * 2 * math.pi;
          final speed = _rng.nextDouble() * 0.6 + 0.2;
          x = 0.5; y = 0.5;
          vx = math.cos(angle) * speed;
          vy = math.sin(angle) * speed;
          break;
        case ParticleMode.rain:
          x = _rng.nextDouble();
          y = -_rng.nextDouble() * 0.3;
          vx = (_rng.nextDouble() - 0.5) * 0.1;
          vy = _rng.nextDouble() * 0.4 + 0.3;
          break;
        case ParticleMode.rise:
          x = _rng.nextDouble();
          y = _rng.nextDouble();
          vx = (_rng.nextDouble() - 0.5) * 0.08;
          vy = -(_rng.nextDouble() * 0.25 + 0.1);
          break;
        case ParticleMode.orbit:
          final angle = _rng.nextDouble() * 2 * math.pi;
          final radius = _rng.nextDouble() * 0.3 + 0.05;
          x = 0.5 + math.cos(angle) * radius;
          y = 0.5 + math.sin(angle) * radius;
          vx = -math.sin(angle) * 0.15;
          vy = math.cos(angle) * 0.15;
          break;
        case ParticleMode.shimmer:
          x = _rng.nextDouble();
          y = _rng.nextDouble();
          vx = 0; vy = 0;
          break;
        default:
          x = _rng.nextDouble();
          y = _rng.nextDouble();
          vx = (_rng.nextDouble() - 0.5) * 0.15;
          vy = (_rng.nextDouble() - 0.5) * 0.15;
          break;
      }
      return _Particle(
        x: x, y: y, vx: vx, vy: vy,
        radius: _rng.nextDouble() * (_config.maxRadius - 0.5) + 0.5,
        life: _rng.nextDouble(),
        alpha: _rng.nextDouble() * 0.3 + 0.15,
        colorIdx: _rng.nextInt(_config.colors.length),
        sparkTimer: _rng.nextDouble() * 2 * math.pi,
        tailLength: _rng.nextInt(_config.tailLength + 1).toDouble(),
      );
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ParticlePainter(
          particles: _particles,
          config: _config,
          time: _totalTime,
        ),
      ),
    );
  }

  void burstAt({double x = 0.5, double y = 0.5, int count = 30}) {
    for (int i = 0; i < count && i < _particles.length; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = _rng.nextDouble() * 0.8 + 0.3;
      _particles[i].x = x;
      _particles[i].y = y;
      _particles[i].vx = math.cos(angle) * speed;
      _particles[i].vy = math.sin(angle) * speed;
      _particles[i].life = 1.0;
      _particles[i].alpha = 0.9;
    }
  }
}

// ═══════════════════════════════════════════════
// 粒子数据 + 渲染
// ═══════════════════════════════════════════════

class _Particle {
  double x, y, vx, vy, life, alpha, sparkTimer;
  final double radius;
  final int colorIdx;
  double tailLength;

  _Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius, required this.life,
    required this.alpha, this.sparkTimer = 0,
    required this.colorIdx, this.tailLength = 0,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final ParticleConfig config;
  final double time;

  _ParticlePainter({required this.particles, required this.config, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // 运动更新
      p.x += p.vx * 0.016;
      p.y += p.vy * 0.016;
      if (p.tailLength > 0) p.tailLength *= 0.97;
      p.life -= 0.0002;

      switch (config.mode) {
        case ParticleMode.burst:
          p.vx *= 0.985;
          p.vy *= 0.985;
          p.alpha -= 0.002;
          if (p.life <= 0 || p.alpha <= 0) _respawnBurst(p);
          break;
        case ParticleMode.rain:
          p.vy += 0.0002;
          if (p.y > 1.1) {
            p.y = -0.05 - (particles.indexOf(p) % 10) * 0.03;
            p.x = (p.x + 0.15) % 1.0;
          }
          break;
        case ParticleMode.rise:
          p.alpha -= 0.0003;
          if (p.y < -0.1 || p.alpha <= 0) {
            p.y = 1.05;
            p.x = (p.x + 0.1) % 1.0;
            p.alpha = 0.6;
          }
          break;
        case ParticleMode.orbit:
          final angle = math.atan2(p.y - 0.5, p.x - 0.5);
          final speed = 0.015;
          p.vx += -math.sin(angle) * speed * 0.01;
          p.vy += math.cos(angle) * speed * 0.01;
          break;
        case ParticleMode.shimmer:
          p.sparkTimer += 0.05;
          break;
        default: // float
          p.vx += (_rngFloat(p) - 0.5) * 0.001;
          p.vy += (_rngFloat(p) - 0.5) * 0.001;
          p.vx = p.vx.clamp(-0.2, 0.2);
          p.vy = p.vy.clamp(-0.2, 0.2);
          break;
      }

      // Wrap
      if (p.x < -0.05) p.x += 1.1;
      if (p.x > 1.05) p.x -= 1.1;
      if (p.y < -0.05) p.y += 1.1;
      if (p.y > 1.05) p.y -= 1.1;

      // Render
      final px = p.x * size.width;
      final py = p.y * size.height;
      final color = config.colors[p.colorIdx % config.colors.length];

      if (config.mode == ParticleMode.shimmer) {
        final spark = (math.sin(p.sparkTimer + time) + 1) / 2;
        // 柔和光点 — 亮度压低，避免亮片感
        final dotAlpha = spark * p.alpha * 0.08 + 0.01;
        if (dotAlpha > 0.02) {
          _drawGlowDot(canvas, px, py, p.radius * 0.6, color.withOpacity(dotAlpha));
        }
      } else {
        final alpha = p.alpha.clamp(0.0, 1.0);
        if (p.tailLength > 0.2) {
          final tx = px - p.vx * p.tailLength * size.width * 0.5;
          final ty = py - p.vy * p.tailLength * size.height * 0.5;
          canvas.drawLine(Offset(px, py), Offset(tx, ty),
            Paint()
              ..color = color.withOpacity(alpha * 0.3)
              ..strokeWidth = p.radius * 0.8
              ..strokeCap = StrokeCap.round,
          );
        }
        _drawGlowDot(canvas, px, py, p.radius, color.withOpacity(alpha));
      }
    }
  }

  void _drawGlowDot(Canvas canvas, double x, double y, double r, Color color) {
    final glowPaint = Paint()
      ..color = color.withOpacity(color.opacity * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(x, y), r * 2.0, glowPaint);
    final corePaint = Paint()..color = color.withOpacity(color.opacity * 0.6);
    canvas.drawCircle(Offset(x, y), r, corePaint);
  }

  void _drawSpark(Canvas canvas, double x, double y, double size, Color color, double spark) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size * 0.15
      ..strokeCap = StrokeCap.round;
    final s = size * spark;
    canvas.drawLine(Offset(x - s, y), Offset(x + s, y), paint);
    canvas.drawLine(Offset(x, y - s), Offset(x, y + s), paint);
    final d = s * 0.5;
    paint.color = color.withOpacity(color.opacity * 0.5);
    canvas.drawLine(Offset(x - d, y - d), Offset(x + d, y + d), paint);
    canvas.drawLine(Offset(x + d, y - d), Offset(x - d, y + d), paint);
  }

  void _respawnBurst(_Particle p) {
    final rng = math.Random(p.colorIdx * 42 + (p.x * 1000).toInt());
    p.x = 0.5; p.y = 0.5;
    final angle = rng.nextDouble() * 2 * math.pi;
    final speed = rng.nextDouble() * 0.6 + 0.2;
    p.vx = math.cos(angle) * speed;
    p.vy = math.sin(angle) * speed;
    p.life = 1.0;
    p.alpha = 0.7 + rng.nextDouble() * 0.3;
    p.tailLength = 2 + rng.nextDouble() * 4;
  }

  double _rngFloat(_Particle p) =>
      math.sin(p.x * 17 + p.y * 31 + p.vx * 13) * 0.5 + 0.5;

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.time != time || old.config != config;
}

// ═══════════════════════════════════════════════
// 配置
// ═══════════════════════════════════════════════

class ParticleConfig {
  final List<Color> colors;
  final ParticleMode mode;
  final int count;
  final double maxRadius;
  final bool autoBurst;
  final double burstInterval;
  final int tailLength;

  const ParticleConfig({
    this.colors = const [Color(0xFF9B59B6), Color(0xFF3A7BD5), Color(0xFFE8D5FF)],
    this.mode = ParticleMode.float,
    this.count = 60,
    this.maxRadius = 4.0,
    this.autoBurst = false,
    this.burstInterval = 5.0,
    this.tailLength = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is ParticleConfig &&
      other.mode == mode &&
      other.count == count &&
      other.maxRadius == maxRadius;
  @override
  int get hashCode => Object.hash(mode, count, maxRadius);
}

enum ParticleMode { float, burst, rain, rise, orbit, shimmer }
