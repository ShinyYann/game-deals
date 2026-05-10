/// 🎉 宝可梦活动 — 从 52Pokemon API 抓取，内置浏览器 + 配图
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../web_view_page.dart';

const String _apiBase = 'http://8.153.97.56/api/poke';

class PokemonEventsPage extends StatefulWidget {
  const PokemonEventsPage({super.key});
  @override
  State<PokemonEventsPage> createState() => _PokemonEventsPageState();
}

class _PokemonEventsPageState extends State<PokemonEventsPage> {
  List<Map<String, dynamic>> _events = [];
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
      final res = await http.get(Uri.parse('$_apiBase/events'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _events = (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _error = null;
        });
      } else {
        setState(() => _error = '暂无活动数据');
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
        title: const Text('🎉 近期活动'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event, size: 64, color: Colors.grey[700]),
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
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('暂无活动信息', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF9C27B0),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _events.length,
        itemBuilder: (_, i) => _eventCard(_events[i]),
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? '??').toString();
    final desc = (item['description'] ?? '').toString();
    final dateRange = (item['date_range'] ?? '').toString();
    final imageUrl = (item['image_url'] ?? '').toString();
    final url = (item['url'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: url.isNotEmpty ? () => _openInApp(url, title) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('活动', style: TextStyle(color: Colors.purple, fontSize: 9)),
              ),
              if (dateRange.isNotEmpty) ...[
                const Spacer(),
                Text(dateRange, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              ],
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
