import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/data_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _cardController;
  final List<_Particle> _particles = [];
  final DataService _data = DataService();
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _initParticles();
    _loadStats();
  }

  void _initParticles() {
    final rng = Random();
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 2.5 + 0.5,
        speed: rng.nextDouble() * 0.004 + 0.001,
        hue: rng.nextDouble() * 60 + 260,
        driftX: rng.nextDouble() * 0.5 - 0.25,
      ));
    }
  }

  Future<void> _loadStats() async {
    final data = await _data.fetchStats();
    if (mounted) setState(() => _stats = data);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _cardController.dispose();
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
                glowController: _glowController,
              ),
            ),
          ),
          // Glow overlay
          Positioned(
            top: -80,
            left: -80,
            right: -80,
            height: 300,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.7 + _glowController.value * 0.3,
                      colors: [
                        AppTheme.accent1.withOpacity(0.06 + _glowController.value * 0.04),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildStatsCards(),
                  const SizedBox(height: 28),
                  _buildQuickGrid(),
                  const SizedBox(height: 24),
                  _buildWhatsNew(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar + greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '欢迎回来',
                    style: TextStyle(
                      color: AppTheme.text2,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Yann 👑',
                    style: TextStyle(
                      color: AppTheme.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              // Online users bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent2,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent2.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '在线 · 1',
                      style: TextStyle(
                        color: AppTheme.accent2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Hero banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent1.withOpacity(0.15),
                  AppTheme.accent2.withOpacity(0.05),
                  AppTheme.accent4.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accent1.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.accent1, AppTheme.accent2],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: const Text(
                            'TrophyRoom',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '你的游戏人生，这里全记得',
                          style: TextStyle(
                            color: AppTheme.text2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _badge('PSN', AppTheme.accent1),
                    const SizedBox(width: 8),
                    _badge('Steam', AppTheme.accent2),
                    const SizedBox(width: 8),
                    _badge('Switch', AppTheme.accent3),
                    const SizedBox(width: 8),
                    _badge('攻略', AppTheme.accent4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard('🏆', _stats?['platinum'] ?? '0', '白金', AppTheme.accent1),
          const SizedBox(width: 10),
          _statCard('⭐', _stats?['all_achievements'] ?? '0', '全成就', AppTheme.gold),
          const SizedBox(width: 10),
          _statCard('🎮', _stats?['games'] ?? '0', '游戏库', AppTheme.accent2),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String count, String label, Color accent) {
    final index = ['🏆', '⭐', '🎮'].indexOf(emoji);
    final delay = Duration(milliseconds: 200 * index);

    return Expanded(
      child: AnimatedBuilder(
        animation: _cardController,
        builder: (context, child) {
          final elapsed = _cardController.value * 1200 - delay.inMilliseconds;
          final cardProgress = (elapsed / 800).clamp(0.0, 1.0);
          final t = Curves.easeOutBack.transform(cardProgress);

          return Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: Opacity(
              opacity: t,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 6),
                    Text(
                      count,
                      style: TextStyle(
                        color: accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.text2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickGrid() {
    final items = [
      _GridItem('🎲', '游戏盲盒', '今天玩什么', AppTheme.accent3),
      _GridItem('🧠', '游戏参谋', '值得买吗', AppTheme.accent4),
      _GridItem('📊', '时间线', '游戏人生', AppTheme.accent2),
      _GridItem('📖', '口袋百科', '随时可查', AppTheme.accent1),
      _GridItem('✅', '必玩清单', '通关计划', AppTheme.gold),
      _GridItem('🌟', '成就墙', '全收集', AppTheme.accent1),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '快捷功能',
                  style: TextStyle(
                    color: AppTheme.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '查看更多 →',
                  style: TextStyle(
                    color: AppTheme.accent1.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppTheme.text2,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNew() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '最新动态',
              style: TextStyle(
                color: AppTheme.text2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accent3.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🔔', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flutter APK 正式启动',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '今晚全力开发中',
                        style: TextStyle(
                          color: AppTheme.text2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '刚刚',
                  style: TextStyle(
                    color: AppTheme.text2.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x, y, size, speed, hue, driftX;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.hue,
    required this.driftX,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Animation<double> glowController;

  _ParticlePainter({
    required this.particles,
    required this.glowController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      double y = (p.y + now * p.speed) % 1.0;
      double x = (p.x + sin(now * 0.3 + i) * 0.015 + p.driftX * now * p.speed * 0.1) % 1.0;
      if (x < 0) x += 1;

      final px = x * size.width;
      final py = y * size.height;

      final paint = Paint()
        ..color = HSLColor.fromAHSL(0.3, p.hue, 0.6, 0.5).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GridItem {
  final String emoji, title, subtitle;
  final Color accent;
  _GridItem(this.emoji, this.title, this.subtitle, this.accent);
}
