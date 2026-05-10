/// 🎁 宝可梦赠送 — 从 52Pokemon API 抓取，内置浏览器 + 配图
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../web_view_page.dart';

const String _apiBase = 'http://8.153.97.56/api/poke';

class PokemonGiftsPage extends StatefulWidget {
  const PokemonGiftsPage({super.key});
  @override
  State<PokemonGiftsPage> createState() => _PokemonGiftsPageState();
}

class _PokemonGiftsPageState extends State<PokemonGiftsPage> {
  List<Map<String, dynamic>> _gifts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_apiBase/gifts'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _gifts = (data['gifts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _error = null;
        });
      } else {
        setState(() => _error = '暂无赠送数据');
      }
    } catch (e) {
      setState(() => _error = '加载失败');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openInApp(String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewPage(url: url, restorePosition: null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('🎁 活动赠送'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('暂无赠送信息', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFFF9800),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _gifts.length,
        itemBuilder: (_, i) => _giftCard(_gifts[i]),
      ),
    );
  }

  Widget _giftCard(Map<String, dynamic> item) {
    final pokemon = (item['pokemon'] ?? '??').toString();
    final game = (item['game'] ?? '').toString();
    final desc = (item['description'] ?? '').toString();
    final dateRange = (item['date_range'] ?? '').toString();
    final imageUrl = (item['image_url'] ?? '').toString();
    final code = (item['code'] ?? '').toString();
    final url = (item['url'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: url.isNotEmpty ? () => _openInApp(url, pokemon) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('赠送', style: TextStyle(color: Colors.orange, fontSize: 9)),
              ),
              if (game.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(game, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
              const Spacer(),
              if (dateRange.isNotEmpty) Text(dateRange, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pokemon, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      if (code.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.vpn_key, size: 12, color: Colors.green[300]),
                              const SizedBox(width: 6),
                              Text('兑换码: $code', style: TextStyle(color: Colors.green[300], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl, width: 64, height: 64, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
