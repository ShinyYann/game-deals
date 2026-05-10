import 'dart:convert';
import 'package:http/http.dart' as http;

/// Steam 视频服务 — 搜游戏 → 拿 HLS 预告片链接
class SteamVideoService {
  static const _searchUrl = 'https://store.steampowered.com/search/?term=';
  static const _detailUrl = 'https://store.steampowered.com/api/appdetails?appids=';

  /// 根据游戏名搜索 Steam App ID
  static Future<int?> searchGame(String gameName) async {
    try {
      final uri = Uri.parse('$_searchUrl${Uri.encodeComponent(gameName)}');
      final resp = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'});
      if (resp.statusCode != 200) return null;
      final re = RegExp(r'data-ds-appid="(\d+)"');
      final match = re.firstMatch(resp.body);
      return match != null ? int.tryParse(match.group(1)!) : null;
    } catch (_) {
      return null;
    }
  }

  /// 获取游戏的 HLS 预告片链接
  static Future<String?> getTrailerUrl(int appId) async {
    try {
      final uri = Uri.parse('$_detailUrl$appId');
      final resp = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'});
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body);
      final movies = data['$appId']?['data']?['movies'] as List<dynamic>?;
      if (movies == null || movies.isEmpty) return null;
      // 优先选 highlight 预告片
      final movie = movies.firstWhere(
        (m) => m['highlight'] == true,
        orElse: () => movies.first,
      );
      return movie['hls_h264'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 一步到位：游戏名 → HLS 链接
  static Future<String?> findTrailer(String gameName) async {
    final appId = await searchGame(gameName);
    if (appId == null) return null;
    return getTrailerUrl(appId);
  }
}
