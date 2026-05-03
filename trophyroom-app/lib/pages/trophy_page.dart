import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class TrophyPage extends StatefulWidget {
  const TrophyPage({super.key});

  @override
  State<TrophyPage> createState() => _TrophyPageState();
}

class _TrophyPageState extends State<TrophyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final ScrollController _scrollController = ScrollController();
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _trophies = [
    {'icon': '🏆', 'name': '血源诅咒', 'rarity': '白金', 'date': '2025-12-24', 'color': AppTheme.accent1},
    {'icon': '🏆', 'name': '艾尔登法环', 'rarity': '白金', 'date': '2026-01-15', 'color': AppTheme.gold},
    {'icon': '⭐', 'name': '黑神话悟空', 'rarity': '全成就', 'date': '2026-02-28', 'color': AppTheme.accent3},
    {'icon': '⭐', 'name': '怪物猎人崛起', 'rarity': '全成就', 'date': '2026-03-10', 'color': AppTheme.accent4},
    {'icon': '🏆', 'name': '战神诸神黄昏', 'rarity': '白金', 'date': '2026-03-22', 'color': AppTheme.accent1},
    {'icon': '🏆', 'name': '对马岛之魂', 'rarity': '白金', 'date': '2026-04-05', 'color': AppTheme.accent2},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '我的奖杯',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_trophies.length} 个 · 全平台累计',
                        style: const TextStyle(color: AppTheme.text2, fontSize: 13),
                      ),
                    ],
                  ),
                  // Search button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accent1.withOpacity(0.15),
                          AppTheme.accent2.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accent1.withOpacity(0.3),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.search, color: AppTheme.accent1, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Platform filter
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterTab('全部', 0),
                  _filterTab('🏆 白金', 1),
                  _filterTab('⭐ 全成就', 2),
                  _filterTab('🎮 进行中', 3),
                  _filterTab('📅 近期', 4),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Trophy shelf
            Expanded(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _trophies.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildShelfHeader();
                      final trophy = _trophies[index - 1];
                      return _buildTrophyCard(trophy, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.accent1.withOpacity(0.3)
                : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.accent1 : AppTheme.text2,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildShelfHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // 3D shelf graphic
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accent1, AppTheme.accent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3D 陈列室',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '滑动查看你的奖杯收藏',
                  style: TextStyle(
                    color: AppTheme.text2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ε-3D',
              style: TextStyle(
                color: AppTheme.accent1,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyCard(Map<String, dynamic> trophy, int index) {
    final cardColor = trophy['color'] as Color;
    final time = _animController.value * 2 * pi + index * 0.5;
    final floatOffset = sin(time) * 4;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Transform.translate(
        offset: Offset(0, floatOffset),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Trophy icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor.withOpacity(0.2), cardColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardColor.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    trophy['icon'] as String,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trophy['name'] as String,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trophy['rarity'] as String,
                            style: TextStyle(
                              color: cardColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trophy['date'] as String,
                          style: const TextStyle(
                            color: AppTheme.text2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.border.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.text2,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
