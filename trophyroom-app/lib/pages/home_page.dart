import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final List<_Particle> _particles = [];
  int _particleCount = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _initParticles();
  }

  void _initParticles() {
    final rng = Random();
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 2 + 1,
        speed: rng.nextDouble() * 0.003 + 0.001,
        opacity: rng.nextDouble() * 0.4 + 0.1,
        hue: rng.nextDouble() * 60 + 260,
      ));
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Particle background
          Positioned.fill(
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                glowAnimation: _glowAnimation,
              ),
            ),
          ),
          // Gradient overlays
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            height: 400,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.8 + _glowAnimation.value * 0.2,
                      colors: [
                        AppTheme.accent1.withOpacity(0.08 + _glowAnimation.value * 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo area
                _buildHeader(),
                const Spacer(flex: 1),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildStats(),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Trophy icon
        Container(
          width: 80,
          height: 80,
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
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text('🏆', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.accent1, AppTheme.accent2, AppTheme.accent3, AppTheme.accent4],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'TrophyRoom',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '奖杯屋',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.text2,
            fontWeight: FontWeight.w500,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accent1.withOpacity(0.1),
                AppTheme.accent2.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accent1.withOpacity(0.2),
            ),
          ),
          child: Text(
            '你的游戏人生，这里全记得',
            style: TextStyle(
              color: AppTheme.text2,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷入口',
            style: TextStyle(
              color: AppTheme.text2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionCard('🎲', '盲盒', '今天玩什么', AppTheme.accent3),
              const SizedBox(width: 12),
              _actionCard('🧠', '参谋', '值得买吗', AppTheme.accent4),
              const SizedBox(width: 12),
              _actionCard('📊', '时间线', '游戏人生', AppTheme.accent2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String emoji, String title, String subtitle, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.text2,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.card,
              AppTheme.card.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('🏆', '0', '白金'),
            _divider(),
            _statItem('⭐', '0', '全成就'),
            _divider(),
            _statItem('🎮', '0', '游戏库'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String icon, String count, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: AppTheme.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.text2,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.border,
    );
  }
}

class _Particle {
  final double x, y, size, speed, opacity, hue;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.hue,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Animation<double> glowAnimation;
  
  _ParticlePainter({
    required this.particles,
    required this.glowAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      // Calculate animated position
      double y = (p.y + now * p.speed) % 1.0;
      double x = p.x + sin(now * 0.5 + i) * 0.02;
      if (x > 1) x -= 1;
      if (x < 0) x += 1;

      final px = x * size.width;
      final py = y * size.height;

      final paint = Paint()
        ..color = HSLColor.fromAHSL(p.opacity, p.hue, 0.7, 0.6).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
