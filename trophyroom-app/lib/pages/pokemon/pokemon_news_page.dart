/// 📰 宝可梦新闻 — 从 52Pokemon API 抓取，内置浏览器打开 + 配图
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../web_view_page.dart';

const String _apiBase = 'http://8.153.97.56/api/poke';

class PokemonNewsPage extends StatefulWidget {
  const PokemonNewsPage({super.key});
  @override
  State<PokemonNewsPage> createState() => _PokemonNewsPageState();
}

class _PokemonNewsPageState extends State<PokemonNewsPage> {
  List<Map<String, dynamic>> _news = [];
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
      final res = await http.get(Uri.parse('$_apiBase/news'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _news = (data['news'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _error = null;
        });
      } else {
        setState(() => _error = '暂无新闻数据');
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
        title: const Text('📰 宝可梦新闻'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper, size: 64, color: Colors.grey[700]),
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
    if (_news.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('暂无新闻', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2196F3),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _news.length,
        itemBuilder: (_, i) => _newsCard(_news[i]),
      ),
    );
  }

  Widget _newsCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? '??').toString();
    final summary = (item['summary'] ?? '').toString();
    final date = (item['date'] ?? '').toString();
    final source = (item['source'] ?? '52Pokemon').toString();
    final imageUrl = (item['image_url'] ?? '').toString();
    final url = (item['url'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
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
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(source, style: TextStyle(color: Colors.blue[200], fontSize: 9)),
              ),
              const Spacer(),
              if (date.isNotEmpty) Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
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
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis,
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
