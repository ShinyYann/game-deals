import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String title;
  final String url;
  final double scrollPosition;
  final DateTime addedAt;

  Bookmark({
    required this.title,
    required this.url,
    this.scrollPosition = 0,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'scrollPosition': scrollPosition,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
    scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0,
    addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class BookmarkService {
  static const _key = 'bookmarks';

  static Future<List<Bookmark>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => Bookmark.fromJson(e)).toList();
  }

  static Future<void> save(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(bookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<bool> isBookmarked(String url) async {
    final bookmarks = await load();
    return bookmarks.any((b) => b.url == url);
  }

  static Future<void> add(Bookmark bookmark) async {
    final bookmarks = await load();
    // 去重
    bookmarks.removeWhere((b) => b.url == bookmark.url);
    bookmarks.insert(0, bookmark);
    await save(bookmarks);
  }

  static Future<void> remove(String url) async {
    final bookmarks = await load();
    bookmarks.removeWhere((b) => b.url == url);
    await save(bookmarks);
  }

  /// 保存滚动位置
  static Future<void> saveScrollPosition(String url, double position) async {
    final bookmarks = await load();
    final idx = bookmarks.indexWhere((b) => b.url == url);
    if (idx >= 0) {
      bookmarks[idx] = Bookmark(
        title: bookmarks[idx].title,
        url: bookmarks[idx].url,
        scrollPosition: position,
        addedAt: bookmarks[idx].addedAt,
      );
      await save(bookmarks);
    }
  }

  /// 获取滚动位置
  static Future<double> getScrollPosition(String url) async {
    final bookmarks = await load();
    final idx = bookmarks.indexWhere((b) => b.url == url);
    if (idx >= 0) return bookmarks[idx].scrollPosition;
    return 0;
  }
}
