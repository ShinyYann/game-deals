import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/data_service.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  int _selectedPlatform = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _deals = [];
  final DataService _data = DataService();

  final List<Map<String, dynamic>> _platforms = [
    {'name': '🔥 热门', 'icon': '🔥'},  
    {'name': 'PSN', 'icon': '🎮'},
    {'name': 'Steam', 'icon': '💨'},
    {'name': 'Switch', 'icon': '🕹️'},
    {'name': 'Epic', 'icon': '🎁'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() => _loading = true);
    final deals = await _data.fetchDeals();
    if (mounted) {
      setState(() {
        _deals = deals;
        _loading = false;
      });
    }
  }

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
          ),
          const SizedBox(height: 16),
          // Platform tabs
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _platforms.length,
              itemBuilder: (context, index) {
                final isActive = _selectedPlatform == index;
                final plat = _platforms[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedPlatform = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.accent2.withOpacity(0.3)
                            : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          plat['icon'] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          plat['name'] as String,
                          style: TextStyle(
                            color: isActive ? AppTheme.accent2 : AppTheme.text2,
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Deals list
          Expanded(
            child: _loading
                ? const Center(
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
                  )
                : _deals.isEmpty
                    ? _buildEmptyState()
                    : _buildDealsList(),
          ),
        ],
      ),
    );
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

  Widget _buildDealsList() {
    return RefreshIndicator(
      onRefresh: _loadDeals,
      color: AppTheme.accent1,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _deals.length,
        itemBuilder: (context, index) {
          final deal = _deals[index];
          return _dealCard(deal, index);
        },
      ),
    );
  }

  Widget _dealCard(Map<String, dynamic> deal, int index) {
    final name = deal['name'] ?? deal['title'] ?? '未知游戏';
    final originalPrice = deal['original_price'] ?? deal['price'] ?? '--';
    final discountPrice = deal['discount_price'] ?? deal['sale_price'] ?? '';
    final discount = deal['discount'] ?? '';
    final platform = deal['platform'] ?? '';
    final image = deal['image'] ?? deal['img'] ?? '';

    Color platColor;
    switch (platform) {
      case 'PSN':
      case 'psn':
        platColor = AppTheme.accent1;
        break;
      case 'Steam':
      case 'steam':
        platColor = AppTheme.accent2;
        break;
      case 'Switch':
      case 'switch':
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
              child: Center(
                child: Text(name.substring(0, 1), style: TextStyle(fontSize: 20, color: platColor)),
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
                    if (discount != '')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent3.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${discount}',
                          style: const TextStyle(color: AppTheme.accent3, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (discountPrice != '')
                Text(
                  '¥${discountPrice}',
                  style: const TextStyle(
                    color: AppTheme.accent2,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (originalPrice != '')
                Text(
                  '¥${originalPrice}',
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
}
