import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final List<Map<String, dynamic>> _games = [
    {'name': '宝可梦殿堂', 'emoji': '🐉', 'desc': '图鉴 · 队伍 · 闪符', 'color': AppTheme.accent1},
    {'name': '黑神话悟空', 'emoji': '🌿', 'desc': '精魄 · 葫芦 · 结局', 'color': AppTheme.accent3},
    {'name': '艾尔登法环', 'emoji': '🗡️', 'desc': '追忆 · 流派 · 收集', 'color': AppTheme.gold},
    {'name': '怪物猎人荒野', 'emoji': '🐾', 'desc': '金冠 · 武器 · 名片', 'color': AppTheme.accent4},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '专属攻略站',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              game['color'] as Color,
                              (game['color'] as Color).withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            game['emoji'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game['name'] as String,
                              style: const TextStyle(
                                color: AppTheme.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
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
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.text2,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
