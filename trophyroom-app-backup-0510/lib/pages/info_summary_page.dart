import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 信息汇总页 — PSN 头像兑换码 / 福利等
class InfoSummaryPage extends StatefulWidget {
  const InfoSummaryPage({super.key});

  @override
  State<InfoSummaryPage> createState() => _InfoSummaryPageState();
}

class _InfoSummaryPageState extends State<InfoSummaryPage> {
  List<Map<String, dynamic>> _allItems = [];
  bool _loading = true;
  String? _error;
  int _expandedIndex = -1; // 展开的卡片 index

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final resp = await http.get(
        Uri.parse('http://8.153.97.56/api/info/summary'),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        setState(() {
          _allItems = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _error = '服务器错误: ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purple));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () {
                  setState(() { _loading = true; _error = null; });
                  _fetch();
                },
                child: const Text('重试')),
          ],
        ),
      );
    }

    // Group by type
    final avatarItems = _allItems.where((i) => i['type'] == 'avatar').toList();
    final codeItems = _allItems.where((i) => i['type'] == 'code').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (avatarItems.isNotEmpty)
          _buildSection('🎭 PSN 头像', 'psnine 机因自动抓取', avatarItems),
        const SizedBox(height: 16),
        if (codeItems.isNotEmpty)
          _buildSection('🎮 福利兑换码', '金钥匙 / 兑换码等', codeItems),
        if (avatarItems.isEmpty && codeItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('暂无信息', style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, String subtitle, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
        ...items.asMap().entries.map((e) => _buildCard(e.value, e.key)),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final codes = List<String>.from(item['codes'] ?? []);
    final snippet = item['snippet']?.toString() ?? '';
    final link = item['link']?.toString() ?? '';
    final time = item['time']?.toString() ?? '';
    final images = List<String>.from(item['images'] ?? []);

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[800]!, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片行（如果有配图）
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(images[i],
                        fit: BoxFit.cover,
                        width: 120,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120, color: Colors.grey[850],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        )),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 码
                if (codes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: codes.map((code) {
                      return GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已复制: $code', style: const TextStyle(fontSize: 12)),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green[800],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[900]!.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[700]!.withOpacity(0.5)),
                          ),
                          child: Text(code,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Color(0xFF7CFF7C),
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                // 摘要（可折叠）
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _expandedIndex = _expandedIndex == index ? -1 : index;
                    }),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(snippet,
                              maxLines: _expandedIndex == index ? 20 : 2,
                              overflow: _expandedIndex == index ? TextOverflow.visible : TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4)),
                        ),
                        if (snippet.length > 60)
                          Icon(
                            _expandedIndex == index ? Icons.expand_less : Icons.expand_more,
                            size: 16, color: Colors.grey[600],
                          ),
                      ],
                    ),
                  ),
                ],
                // 底部：时间 + 链接
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (time.isNotEmpty)
                      Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(link);
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('查看原帖', style: TextStyle(fontSize: 10, color: Colors.blue[400])),
                          const SizedBox(width: 2),
                          Icon(Icons.open_in_new, size: 10, color: Colors.blue[400]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
