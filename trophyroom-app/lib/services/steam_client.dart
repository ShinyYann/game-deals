/// Steam 数据客户端 — 通过服务器代理访问 Steam Web API
///
/// 所有请求走服务器中转，国内用户无感访问 Steam
import 'dart:convert';
import 'package:http/http.dart' as http;

class SteamClient {
  static const String _server = 'http://8.153.97.56';

  final String steamId;

  SteamClient(this.steamId);

  /// 获取 Steam 个人资料（昵称、头像、等级等）
  Future<Map<String, dynamic>> fetchProfile() async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/profile?steamid=$steamId'),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam profile fetch failed: ${resp.statusCode}');
  }

  /// 获取 Steam 游戏库（含游玩时长）
  Future<Map<String, dynamic>> fetchGames() async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/games?steamid=$steamId'),
    ).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam games fetch failed: ${resp.statusCode}');
  }

  /// 获取某个游戏的成就列表
  Future<Map<String, dynamic>> fetchAchievements(String appId) async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/achievements?steamid=$steamId&appid=$appId'),
    ).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam achievements fetch failed: ${resp.statusCode}');
  }

  /// 获取某个游戏的社区攻略数
  Future<Map<String, dynamic>> fetchTips(String appId) async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/tips?appid=$appId'),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {'app_id': appId, 'guide_count': 0};
  }

  /// 设置服务器 Steam API Key（一次性操作）
  static Future<Map<String, dynamic>> setApiKey(String key) async {
    final resp = await http.post(
      Uri.parse('$_server/api/steam/key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': key}),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to set Steam API key: ${resp.statusCode}');
  }
}
