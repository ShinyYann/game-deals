import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import 'web_view_page.dart';

/// 攻略 Hub — 某个游戏的攻略列表（含白金攻略筛选）
class GuideHubPage extends StatefulWidget {
  final String gameName;
  final Map<String, dynamic> rawData;

  const GuideHubPage({
    super.key,
    required this.gameName,
    required this.rawData,
  });

  @override
  State<GuideHubPage> createState() => _GuideHubPageState();
}

class _GuideHubPageState extends State<GuideHubPage> {
  List<Map<String, dynamic>> _allGuides = [];
  List<Map<String, dynamic>> _platinumGuides = [];
  Map<String, dynamic>? _gameInfo;
  bool _loading = true;
  bool _showPlatinumOnly = false;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    try {
      _gameInfo = widget.rawData['info'] as Map<String, dynamic>?;
      _allGuides = List<Map<String, dynamic>>.from(widget.rawData['guides'] ?? []);
      _platinumGuides = _allGuides.where((g) {
        final cat = g['guide_category']?.toString() ?? '';
        if (cat == 'platinum') return true;
        final title = g['title']?.toString() ?? '';
        return ['白金', '全成就', '白金攻略', '全收集'].any((kw) => title.contains(kw));
      }).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _displayedGuides =>
      _showPlatinumOnly ? _platinumGuides : _allGuides;

  @override
  Widget build(BuildContext context) {
    final info = _gameInfo;
    final nameCn = info?['name_cn']?.toString() ?? widget.gameName;
    final difficulty = info?['difficulty'] as double?;
    final timeHours = info?['time_hours'] as double?;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        title: Text(nameCn),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const PhosphorIcon(
            PhosphorIconsFill.caretLeft,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA855F7)),
            )
          : Column(
              children: [
                // 游戏信息卡片
                if (info != null)
                  _buildInfoCard(nameCn, difficulty, timeHours),
                const SizedBox(height: 8),
                // 白金攻略筛选 chips
                _buildFilterChips(),
                const SizedBox(height: 8),
                // 攻略列表
                Expanded(child: _buildGuideList()),
              ],
            ),
    );
  }

  // ──────────────────── 筛选 Chips ────────────────────
  Widget _buildFilterChips() {
    if (_allGuides.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 📋 全部攻略 chip
          _filterChip(
            label: '📋 全部攻略 (${_allGuides.length})',
            selected: !_showPlatinumOnly,
            onTap: () => setState(() => _showPlatinumOnly = false),
          ),
          const SizedBox(width: 8),
          // 🏆 白金攻略 chip
          _filterChip(
            label: '🏆 白金攻略 (${_platinumGuides.length})',
            selected: _showPlatinumOnly,
            onTap: () => setState(() => _showPlatinumOnly = true),
            platinum: true,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool platinum = false,
  }) {
    final bgColor = selected
        ? (platinum ? const Color(0xFFB8860B) : const Color(0xFFA855F7))
        : const Color(0xFF2A2A3E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor.withAlpha(selected ? 200 : 180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? bgColor
                : Colors.white.withAlpha(30),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  // ──────────────────── 游戏信息卡片 ────────────────────
  Widget _buildInfoCard(String nameCn, double? difficulty, double? timeHours) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(12), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoStat(
            icon: PhosphorIconsFill.gameController,
            label: '游戏',
            value: nameCn,
            color: const Color(0xFF4ECDC4),
          ),
          if (difficulty != null)
            _infoStat(
              icon: PhosphorIconsFill.gauge,
              label: '难度',
              value: '${difficulty.toStringAsFixed(1)} / 10',
              color: const Color(0xFFFFA726),
            ),
          if (timeHours != null)
            _infoStat(
              icon: PhosphorIconsFill.clock,
              label: '时长',
              value: '${timeHours.toStringAsFixed(0)}h',
              color: const Color(0xFF66C0F4),
            ),
        ],
      ),
    );
  }

  Widget _infoStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        PhosphorIcon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ──────────────────── 攻略列表 ────────────────────
  Widget _buildGuideList() {
    final items = _displayedGuides;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.smileySad,
              color: Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _showPlatinumOnly ? '暂无白金攻略' : '暂无攻略数据',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final title = item['title']?.toString() ?? '未命名';
        final url = item['url']?.toString() ?? '';
        final source = item['source']?.toString() ?? '';
        final guideCategory = item['guide_category']?.toString() ?? '';
        // Fallback: detect platinum from title
        final isPlatinum = guideCategory == 'platinum' ||
            ['白金', '全成就', '白金攻略', '全收集']
                .any((kw) => title.contains(kw));

        return _buildGuideCard(title, url, source, isPlatinum);
      },
    );
  }

  Widget _buildGuideCard(String title, String url, String source, bool isPlatinum) {
    final sourceColor = _sourceColor(source);

    return GestureDetector(
      onTap: () async {
        if (url.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WebViewPage(url: url)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
        ),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPlatinum
                    ? const Color(0xFFB8860B).withAlpha(25)
                    : const Color(0xFF4ECDC4).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PhosphorIcon(
                isPlatinum
                    ? PhosphorIconsFill.trophy
                    : PhosphorIconsFill.article,
                color: isPlatinum ? const Color(0xFFB8860B) : const Color(0xFF4ECDC4),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // 标题 + 来源 + 白金徽章
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (isPlatinum) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '白金攻略',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (source.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: sourceColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            source,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: sourceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 箭头
            PhosphorIcon(
              PhosphorIconsFill.caretRight,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _sourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'gamersky':
        return const Color(0xFF66C0F4);
      case '3dm':
        return const Color(0xFFFF6B6B);
      case 'psnine':
        return const Color(0xFF4ECDC4);
      case 'bilibili':
        return const Color(0xFFFB7299);
      default:
        return const Color(0xFFA855F7);
    }
  }
}
