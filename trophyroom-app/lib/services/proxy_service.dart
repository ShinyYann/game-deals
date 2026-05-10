/// 代理域名管理服务
/// 从服务器获取、添加、删除需要走代理的域名列表
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ProxyService {
  static const String _api = 'http://8.153.97.56/api/proxy/domains';
  static const String _cacheKey = 'proxy_domains_cache';
  static const String _cacheTimeKey = 'proxy_domains_cache_time';
  static const Duration _cacheTtl = Duration(hours: 1);

  /// 获取代理域名列表（带本地缓存）
  /// 优先返回缓存，缓存过期则拉取服务器
  static Future<List<String>> fetchDomains({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 检查缓存
    if (!force) {
      final cachedJson = prefs.getString(_cacheKey);
      final cachedTime = prefs.getInt(_cacheTimeKey);
      if (cachedJson != null && cachedTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
        if (age < _cacheTtl.inMilliseconds) {
          final list = _decodeDomains(cachedJson);
          if (list.isNotEmpty) return list;
        }
      }
    }

    // 拉取服务器
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(_api));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      if (resp.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        final domains = (data['domains'] as List)
            .map((e) => e.toString())
            .toList();

        // 写入缓存
        await prefs.setString(_cacheKey, json.encode(domains));
        await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);

        return domains;
      }
    } catch (_) {}

    // 如果拉取失败，尝试用过期缓存
    final fallback = prefs.getString(_cacheKey);
    if (fallback != null) {
      return _decodeDomains(fallback);
    }

    // 兜底：内置域名
    return ['filejin.ru', 'xn--wcv59z.com'];
  }

  /// 添加代理域名
  static Future<bool> addDomain(String token, String domain) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.postUrl(Uri.parse(_api));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization', 'Bearer $token');
      req.write(json.encode({'domain': domain}));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      final data = json.decode(body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && data['ok'] == true) {
        // 刷新缓存
        final domains = (data['domains'] as List)
            .map((e) => e.toString())
            .toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, json.encode(domains));
        await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 删除代理域名
  static Future<bool> removeDomain(String token, String domain) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final uri = Uri.parse(_api).replace(queryParameters: {'domain': domain});
      final req = await client.deleteUrl(uri);
      req.headers.set('Authorization', 'Bearer $token');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      final data = json.decode(body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && data['ok'] == true) {
        // 刷新缓存
        final domains = (data['domains'] as List)
            .map((e) => e.toString())
            .toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, json.encode(domains));
        await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// JSON 字符串解码为 List<String>
  static List<String> _decodeDomains(String jsonStr) {
    try {
      final list = json.decode(jsonStr) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
