import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DataService {
  // 数据从 Gitee raw 获取（国内友好）
  static const String _giteeBase =
      'https://gitee.com/yann8888/game-deals/raw/main';

  static const String _githubBase =
      'https://raw.githubusercontent.com/ShinyYann/trophyroom/main';

  String get baseUrl => _giteeBase;

  /// 获取统计数据（白金/全成就/游戏库）
  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final url = '$baseUrl/docs/data/stats.json';
      final resp = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('fetchStats error: $e');
    }
    return {'platinum': '0', 'all_achievements': '0', 'games': '0'};
  }

  /// 获取折扣数据
  Future<List<Map<String, dynamic>>> fetchDeals({String platform = 'all'}) async {
    try {
      final url = '$baseUrl/docs/data/deals.json';
      final resp = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('fetchDeals error: $e');
    }
    return [];
  }
}
