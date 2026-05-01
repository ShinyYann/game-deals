import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<Map<String, dynamic>> _allDeals = [];
  List<Map<String, dynamic>> _deals = [];
  final DataService _data = DataService();
  String? _error;

  final List<Map<String, dynamic>> _platforms = [
    {'name': '全部', 'icon': '🔥', 'key': 'all'},
    {'name': 'PSN', 'icon': '🎮', 'key': 'psn'},
    {'name': 'Steam', 'icon': '💨', 'key': 'steam'},
    {'name': 'Switch', 'icon': '🕹️', 'key': 'switch'},
    {'name': 'Epic', 'icon': '🎁', 'key': 'epic'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deals = await _data.fetchDeals();
      if (mounted) {
        setState(() {
          _allDeals = deals;
          _loading = false;
          _filterDeals();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _filterDeals() {
    final key = _platforms[_selectedPlatform]['key'] as String;
    if (key == 'all') {
      _deals = List.from(_allDeals);
    } else {
      _deals = _allDeals.where((d) {
        final p = (d['platform'] as String?)?.toLowerCase() ?? '';
        return p.contains(key);
      }).toList();
    }
  }

  void _showDetail(Map<String, dynamic> deal) {
    final name = deal['title'] ?? deal['name'] ?? '未知游戏';
    final desc = deal['description'] ?? deal['desc'] ?? '';
    final price = deal['price'] ?? '';
    final discount = deal['discount'] ?? '';
    final platform = deal['platform'] ?? '';
    final medal = deal['medal'] ?? '';
    final url = deal['url'] ?? '';
    final tags = (deal['tags'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.text3.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(name,
                    style: const TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                if (medal.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent3.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(medal, style: const TextStyle(color: AppTheme.accent3, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              if (platform.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: platform.toLowerCase().contains('steam')
                      ? AppTheme.accent2.withOpacity(0.15)
                      : platform.toLowerCase().contains('psn')
                        ? AppTheme.accent1.withOpacity(0.15)
                        : AppTheme.accent4.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(platform,
                    style: TextStyle(
                      color: platform.toLowerCase().contains('steam')
                        ? AppTheme.accent2
                        : platform.toLowerCase().contains('psn')
                          ? AppTheme.accent1
                          : AppTheme.accent4,
                      fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              if (discount.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent3.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(discount,
                    style: const TextStyle(color: AppTheme.accent3, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              if (price.isNotEmpty)
                Text(price,
                  style: const TextStyle(color: AppTheme.accent2, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 4,
                children: tags.take(6).map<Widget>((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(t.toString(), style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
                )).toList(),
              ),
            ],
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(desc,
                  style: const TextStyle(color: AppTheme.text2, fontSize: 13, height: 1.5),
                  maxLines: 5, overflow: TextOverflow.ellipsis),
              ),
            ],
            const SizedBox(height: 20),
            if (url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('去商店看看', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent2,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('游戏折扣', style: TextStyle(color: AppTheme.text, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('每日更新 · 全平台比价', style: TextStyle(color: AppTheme.text2, fontSize: 13)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accent3.withOpacity(0.2)),
                  ),
                  child: Text('${_allDeals.length} 款折扣',
                    style: const TextStyle(color: AppTheme.accent3, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  onTap: () => setState(() {
                    _selectedPlatform = index;
                    _filterDeals();
                  }),
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
                        Text(plat['icon'] as String, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(plat['name'] as String,
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
          Expanded(
            child: _loading
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('📡', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('正在获取数据...', style: TextStyle(color: AppTheme.text2, fontSize: 14)),
                    SizedBox(height: 12),
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent2)),
                  ]),
                )
              : _error != null
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('⚠️', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('加载失败', style: TextStyle(color: AppTheme.text2, fontSize: 16)),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(_error!, textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.text3, fontSize: 12)),
                      ),
                      SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _loadDeals,
                        icon: Icon(Icons.refresh, color: AppTheme.accent2, size: 18),
                        label: Text('重新加载', style: TextStyle(color: AppTheme.accent2)),
                      ),
                    ]),
                  )
                : _deals.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.card,
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Center(child: Text('💰', style: TextStyle(fontSize: 36))),
                        ),
                        SizedBox(height: 16),
                        Text('暂无折扣数据', style: TextStyle(color: AppTheme.text2, fontSize: 16)),
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadDeals,
                          icon: Icon(Icons.refresh, color: AppTheme.accent2, size: 18),
                          label: Text('重新加载', style: TextStyle(color: AppTheme.accent2)),
                        ),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDeals,
                      color: AppTheme.accent1,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _deals.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _deals.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text('已展示全部 ${_deals.length} 款折扣',
                                  style: TextStyle(color: AppTheme.text3, fontSize: 12)),
                              ),
                            );
                          }
                          return _dealCard(_deals[index], index);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _dealCard(Map<String, dynamic> deal, int index) {
    final name = deal['title'] ?? deal['name'] ?? '未知游戏';
    final price = deal['price'] ?? '';
    final discount = deal['discount'] ?? '';
    final platform = deal['platform'] ?? '';
    final medal = deal['medal'] ?? '';
    final tags = (deal['tags'] as List?) ?? [];

    final priceStr = price.toString().replaceAll('¥', '').trim();
    final discountStr = discount.toString().replaceAll('%', '').trim();

    Color platColor;
    final platLower = platform.toLowerCase();
    if (platLower.contains('steam')) {
      platColor = AppTheme.accent2;
    } else if (platLower.contains('psn') || platLower.contains('playstation')) {
      platColor = AppTheme.accent1;
    } else if (platLower.contains('switch') || platLower.contains('nintendo')) {
      platColor = AppTheme.accent3;
    } else {
      platColor = AppTheme.accent4;
    }

    return GestureDetector(
      onTap: () => _showDetail(deal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 56, height: 56,
                color: platColor.withOpacity(0.1),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : '?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: platColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                          style: const TextStyle(color: AppTheme.text, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (medal.isNotEmpty)
                        Text(medal, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: platColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(platform,
                        style: TextStyle(color: platColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    if (discountStr.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent3.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('-$discountStr',
                          style: const TextStyle(color: AppTheme.accent3, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(tags.first.toString(),
                          style: TextStyle(color: AppTheme.text3, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (priceStr.isNotEmpty)
              Text(priceStr,
                style: const TextStyle(color: AppTheme.accent2, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
