import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/data_service.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  int _selectedTab = 0;
  bool _loading = true;
  bool _error = false;
  Map<String, dynamic> _dealData = {};
  final DataService _data = DataService();

  final List<DealTab> _tabs = [
    DealTab(label: '🔥 热门', icon: '🔥', key: 'hot'),
    DealTab(label: '💸 史低', icon: '💸', key: 'new_low'),
    DealTab(label: 'PSN', icon: '🎮', key: 'psn'),
    DealTab(label: 'Steam', icon: '💨', key: 'steam'),
    DealTab(label: 'Switch', icon: '🕹️', key: 'switch'),
  ];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final deals = await _data.fetchDeals();
    if (mounted) {
      setState(() {
        if (deals.isNotEmpty) {
          _dealData = deals;
        } else {
          _error = true;
        }
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCurrentDeals() {
    final tabKey = _tabs[_selectedTab].key;

    if (tabKey == 'hot') {
      // Build hot list: combine all platforms, sort by discount
      final all = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final plat in ['psn', 'steam', 'switch']) {
        final items = _getPlatformDeals(plat);
        for (final g in items) {
          final name = (g['name'] as String?)?.trim().toLowerCase() ?? '';
          if (name.isEmpty || seen.contains(name)) continue;
          seen.add(name);
          final disc = _parseDiscount(g['discount'] as String? ?? '');
          g['_sort_discount'] = disc;
          all.add(g);
        }
      }
      all.sort((a, b) => (b['_sort_discount'] as num? ?? 0)
          .compareTo(a['_sort_discount'] as num? ?? 0));
      return all.take(50).toList();
    }

    if (tabKey == 'new_low') {
      final items = _getPlatformDeals('p9_new_lows');
      return items.take(50).toList();
    }

    return _getPlatformDeals(tabKey);
  }

  List<Map<String, dynamic>> _getPlatformDeals(String platform) {
    try {
      final raw = _dealData[platform];
      if (raw is List) {
        return raw.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  num _parseDiscount(String disc) {
    if (disc.isEmpty) return 0;
    disc = disc.replaceAll('%', '').replaceAll('-', '').trim();
    return num.tryParse(disc) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTabs(),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '游戏折扣',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '每日更新 · 全平台比价',
                style: TextStyle(color: AppTheme.text2, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent3.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accent3.withOpacity(0.2)),
            ),
            child: Text(
              '昨日更新',
              style: TextStyle(
                color: AppTheme.accent3,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isActive = _selectedTab == index;
          final tab = _tabs[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.card : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppTheme.accent2.withOpacity(0.3) : AppTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: isActive ? AppTheme.accent2 : AppTheme.text2,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (_tabCount(index) > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accent2.withOpacity(0.15) : AppTheme.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_tabCount(index)}',
                        style: TextStyle(
                          color: isActive ? AppTheme.accent2 : AppTheme.text2,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _tabCount(int index) {
    if (index == 0 && _dealData.isNotEmpty) return _getCurrentDeals().length;
    final tabKey = _tabs[index].key;
    if (tabKey == 'hot') return _getCurrentDeals().length;
    return _getPlatformDeals(tabKey).length;
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📡', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              '正在获取数据...',
              style: TextStyle(color: AppTheme.text2, fontSize: 14),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent2,
              ),
            ),
          ],
        ),
      );
    }

    if (_error || _dealData.isEmpty) {
      return _buildEmptyState();
    }

    final deals = _getCurrentDeals();
    if (deals.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDealsList(deals);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.card,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(child: Text('💰', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无折扣数据',
            style: TextStyle(color: AppTheme.text2, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadDeals,
            icon: const Icon(Icons.refresh, color: AppTheme.accent2, size: 18),
            label: const Text(
              '重新加载',
              style: TextStyle(color: AppTheme.accent2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsList(List<Map<String, dynamic>> deals) {
    return RefreshIndicator(
      onRefresh: _loadDeals,
      color: AppTheme.accent1,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: deals.length,
        itemBuilder: (context, index) {
          return _dealCard(deals[index], index);
        },
      ),
    );
  }

  Widget _dealCard(Map<String, dynamic> deal, int index) {
    final name = deal['name'] as String? ?? deal['title'] as String? ?? '未知游戏';
    final originalPrice = deal['original_price'] as String? ?? '';
    final price = deal['price'] as String? ?? '';
    final discount = deal['discount'] as String? ?? '';
    final image = deal['img'] as String? ?? deal['image'] as String? ?? '';
    final platform = _getPlatform(deal);

    // P9 史低额外字段
    final rating = deal['rating'] as String? ?? '';
    final deadline = deal['deadline'] as String? ?? '';
    final playerCount = deal['player_count'] as String? ?? '';

    Color platColor;
    switch (platform) {
      case 'PSN':
        platColor = AppTheme.accent1;
        break;
      case 'Steam':
        platColor = AppTheme.accent2;
        break;
      case 'Switch':
        platColor = AppTheme.accent3;
        break;
      default:
        platColor = AppTheme.accent4;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Game image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: platColor.withOpacity(0.1),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1) : '?',
                          style: TextStyle(fontSize: 20, color: platColor),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1) : '?',
                        style: TextStyle(fontSize: 20, color: platColor),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: platColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        platform,
                        style: TextStyle(color: platColor, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (discount.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: discount.contains('史低')
                              ? const Color(0xFFFF6B6B).withOpacity(0.15)
                              : AppTheme.accent3.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          discount.startsWith('-') ? discount : '-$discount',
                          style: TextStyle(
                            color: discount.contains('史低')
                                ? const Color(0xFFFF6B6B)
                                : AppTheme.accent3,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (deadline.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '⏰$deadline',
                        style: TextStyle(
                          color: AppTheme.text2.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                if (rating.isNotEmpty || playerCount.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${rating.isNotEmpty ? rating : ''}${playerCount.isNotEmpty ? " · $playerCount" : ''}',
                      style: TextStyle(
                        color: AppTheme.text2.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (price.isNotEmpty)
                Text(
                  _cleanPrice(price),
                  style: const TextStyle(
                    color: AppTheme.accent2,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (originalPrice.isNotEmpty)
                Text(
                  _cleanPrice(originalPrice),
                  style: TextStyle(
                    color: AppTheme.text2.withOpacity(0.5),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPlatform(Map<String, dynamic> deal) {
    // Check explicit platform field
    final plat = deal['platform'] as String?;
    if (plat != null && plat.isNotEmpty) return plat;

    // Check if it came from p9_new_lows
    if (deal.containsKey('deadline') || deal.containsKey('player_count') || deal.containsKey('rating')) {
      return deal['platform'] as String? ?? 'PSN';
    }

    return 'PSN';
  }

  String _cleanPrice(String p) {
    // Handle HK prices — keep prefix
    if (p.contains('HK$')) {
      return p.replaceAll(RegExp(r'\s+'), '');
    }
    // Japanese Yen or other currencies - just return as-is
    return p.replaceAll(RegExp(r'\s+'), '');
  }
}

class DealTab {
  final String label;
  final String icon;
  final String key;

  const DealTab({
    required this.label,
    required this.icon,
    required this.key,
  });
}
