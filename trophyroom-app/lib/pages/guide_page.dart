import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final List<Map<String, dynamic>> _games = [
    {
      'name': '宝可梦殿堂',
      'emoji': '🐉',
      'desc': '图鉴 · 队伍 · 闪符 · 配队推荐 · 闪值排行',
      'color': AppTheme.accent1,
      'count': '9 代',
    },
    {
      'name': '黑神话悟空',
      'emoji': '🌿',
      'desc': '精魄 · 葫芦 · 结局分支 · 隐藏地图',
      'color': AppTheme.accent3,
      'count': '全部收集',
    },
    {
      'name': '艾尔登法环',
      'emoji': '🗡️',
      'desc': '追忆 · 流派 · 全收集 · 地图标记',
      'color': AppTheme.gold,
      'count': 'DLC 已收录',
    },
    {
      'name': '怪物猎人荒野',
      'emoji': '🐾',
      'desc': '金冠 · 武器数据 · 名片 · 技能表',
      'color': AppTheme.accent4,
      'count': '随时更新',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      '专属攻略站',
                      style: TextStyle(
                        color: AppTheme.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '📖',
                      style: TextStyle(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '宝可梦 · 黑神话 · 老头环 · 怪猎',
                  style: TextStyle(color: AppTheme.text2, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                return _buildGameCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(int index) {
    final game = _games[index];
    final color = game['color'] as Color;
    final delay = Duration(milliseconds: 150 * index);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + 150 * index),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(24 * (1 - value), 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Game icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        game['emoji'] as String,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              game['name'] as String,
                              style: const TextStyle(
                                color: AppTheme.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                game['count'] as String,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game['desc'] as String,
                          style: const TextStyle(
                            color: AppTheme.text2,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: color,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
