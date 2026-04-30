import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _subOpacity;
  late Animation<double> _particleOpacity;
  final List<_SplashDot> _dots = [];
  bool _explode = false;

  @override
  void initState() {
    super.initState();

    // Init dots
    final rng = Random();
    for (int i = 0; i < 80; i++) {
      _dots.add(_SplashDot(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 3 + 1,
        speed: rng.nextDouble() * 0.6 + 0.3,
        angle: rng.nextDouble() * 2 * pi,
        hue: rng.nextDouble() * 60 + 260,
        delay: rng.nextDouble() * 0.5,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _subOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _particleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Trigger explode at 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _explode = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A12),
                  Color(0xFF0f0d1a),
                  Color(0xFF120a20),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Particles
                CustomPaint(
                  size: Size.infinite,
                  painter: _SplashParticlePainter(
                    dots: _dots,
                    progress: _controller.value,
                    explode: _explode,
                    opacity: _particleOpacity.value,
                  ),
                ),
                // Center glow
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accent1.withOpacity(0.06 * _logoOpacity.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Logo
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.accent1, AppTheme.accent2],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent1.withOpacity(0.3),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🏆',
                                style: TextStyle(fontSize: 46),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _subOpacity.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppTheme.accent1,
                              AppTheme.accent2,
                              AppTheme.accent3,
                              AppTheme.accent4,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'TrophyRoom',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: _subOpacity.value * 0.7,
                        child: Text(
                          '奖 杯 屋',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.text2,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SplashDot {
  final double x, y, size, speed, angle, hue, delay;
  _SplashDot({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.hue,
    required this.delay,
  });
}

class _SplashParticlePainter extends CustomPainter {
  final List<_SplashDot> dots;
  final double progress;
  final bool explode;
  final double opacity;

  _SplashParticlePainter({
    required this.dots,
    required this.progress,
    required this.explode,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      double px, py;
      if (explode && progress > 0.5) {
        final t = (progress - 0.5) / 0.5;
        final dist = t * d.speed * 200;
        px = size.width / 2 + cos(d.angle) * dist;
        py = size.height / 2 + sin(d.angle) * dist;
      } else {
        final t = progress * 0.5;
        px = size.width / 2 + cos(d.angle) * t * d.speed * 50;
        py = size.height / 2 + sin(d.angle) * t * d.speed * 50;
      }

      final fadeOut = explode ? (1 - (progress - 0.5) / 0.5).clamp(0.0, 1.0) : 1.0;
      final paint = Paint()
        ..color = HSLColor.fromAHSL(
          d.delay < progress ? opacity * fadeOut * 0.5 : 0,
          d.hue,
          0.7,
          0.6,
        ).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), d.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
