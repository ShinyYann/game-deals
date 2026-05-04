import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_view_page.dart';

class BookmarkListPage extends StatefulWidget {
  const BookmarkListPage({super.key});

  @override
  State<BookmarkListPage> createState() => _BookmarkListPageState();
}

class _BookmarkListPageState extends State<BookmarkListPage> {
  List<Map<String, dynamic>> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_bookmarks') ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    // Sort by most recent first
    list.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    setState(() => _bookmarks = list);
  }

  Future<void> _deleteBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarks.removeAt(index);
    await prefs.setString('saved_bookmarks', jsonEncode(_bookmarks));
    setState(() {});
  }

  String _formatTime(int? ts) {
    if (ts == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('📑 攻略收藏夹', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: _bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📭', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('还没有收藏',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('在奖杯心得中点击链接，浏览时点右上角收藏',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final b = _bookmarks[i];
                final url = b['url']?.toString() ?? '';
                final title = b['title']?.toString() ?? url;
                final scrollY = b['scrollY'];
                final ts = b['timestamp'] as int?;
                final domain = Uri.tryParse(url)?.host ?? '';

                return Card(
                  color: const Color(0xFF1E1E2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WebViewPage(
                            url: url,
                            restorePosition: scrollY?.toString(),
                          ),
                        ),
                      ).then((_) => _loadBookmarks());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.language, size: 13, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(domain,
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    const SizedBox(width: 12),
                                    if (ts != null)
                                      Text(_formatTime(ts),
                                          style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                                    if (scrollY != null && scrollY > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.cyan[800]!.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('续读',
                                              style: TextStyle(
                                                  color: Colors.cyan[300],
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Delete button via long press hint
                          GestureDetector(
                            onTap: () => _deleteBookmark(i),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.close, size: 16, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
