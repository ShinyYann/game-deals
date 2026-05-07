import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// 小黑盒 PSN 公开 API 客户端
/// 所有接口公开，无需登录
/// 内置请求冷却，模拟正常浏览行为
class XhhPsnClient {
  static const _apiBase = 'https://api.xiaoheihe.cn';
  static const _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Referer': 'https://web.xiaoheihe.cn/',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'zh-CN,zh;q=0.9',
  };

  // 上次请求时间，用于冷却
  static DateTime _lastRequest = DateTime.now().subtract(const Duration(seconds: 5));
  static final _random = Random();

  static Future<void> _cooldown() async {
    final elapsed = DateTime.now().difference(_lastRequest).inMilliseconds;
    // 随机 200-600ms 冷却
    final delay = 200 + _random.nextInt(400);
    if (elapsed < delay) {
      await Future.delayed(Duration(milliseconds: delay - elapsed));
    }
    _lastRequest = DateTime.now();
  }

  final String playerId;

  XhhPsnClient(this.playerId);

  // ── 玩家总览 ──
  Future<Map<String, dynamic>> fetchOverview() async {
    await _cooldown();
    final resp = await http
        .get(Uri.parse('$_apiBase/game/psn/get_player_overview/?player_id=$playerId'),
            headers: _headers)
        .timeout(const Duration(seconds: 8));
    final data = json.decode(resp.body);
    if (data['status'] != 'ok') throw Exception(data['msg'] ?? 'overview failed');
    final r = data['result'] as Map<String, dynamic>;
    return r;
  }

  // ── 游戏列表（含游玩时间） ──
  Future<List<Map<String, dynamic>>> fetchGames() async {
    await _cooldown();
    final resp = await http
        .get(Uri.parse('$_apiBase/game/psn/get_player_games/?player_id=$playerId'),
            headers: _headers)
        .timeout(const Duration(seconds: 8));
    final data = json.decode(resp.body);
    if (data['status'] != 'ok') throw Exception(data['msg'] ?? 'games failed');
    final r = data['result'] as Map<String, dynamic>;
    return (r['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // ── 单游戏奖杯 ──
  Future<Map<String, dynamic>> fetchGameTrophies(String psnCid) async {
    await _cooldown();
    final resp = await http
        .get(Uri.parse('$_apiBase/game/psn/get_player_game_trophies/'
            '?player_id=$playerId&psn_cid=$psnCid'),
            headers: _headers)
        .timeout(const Duration(seconds: 8));
    final data = json.decode(resp.body);
    if (data['status'] != 'ok') throw Exception(data['msg'] ?? 'trophies failed');
    return data['result'] as Map<String, dynamic>;
  }

  // ── 安全取整：小黑盒 API 返回值可能是 String 或 int ──
  static int _safeInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString()) ?? fallback;
  }

  // ── 统一：获取全部数据 ──
  Future<Map<String, dynamic>> fetchAll() async {
    final overview = await fetchOverview();
    final games = await fetchGames();

    // 获取平台标签
    Map<String, String> platforms = {};
    try {
      final resp = await http
          .get(Uri.parse('http://8.153.97.56/api/psn/platforms'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        platforms = Map<String, String>.from(json.decode(resp.body) as Map);
      }
    } catch (_) {}

    // 提取统计数据（headers value 可能是 String "828" 或 int 10）
    final headers = (overview['headers'] as List?) ?? [];
    int totalHours = 0;
    int totalGames = 0;
    for (final h in headers) {
      final desc = h['desc']?.toString() ?? '';
      final val = _safeInt(h['value']);
      if (desc == '总时长 h') totalHours = val;
      if (desc == '总游戏') totalGames = val;
    }

    final details = (overview['details'] as List?) ?? [];
    int platinum = 0, gold = 0, silver = 0, bronze = 0;
    for (final d in details) {
      final desc = d['desc']?.toString() ?? '';
      final val = _safeInt(d['value']);
      if (desc == '白金') platinum = val;
      if (desc == '黄金') gold = val;
      if (desc == '白银') silver = val;
      if (desc == '青铜') bronze = val;
    }

    final player = overview['player'] as Map<String, dynamic>? ?? {};
    // 计算总奖杯
    int totalTrophies = platinum + gold + silver + bronze;

    // 映射游戏列表
    final mappedGames = games.map((g) {
      return {
        'game_id': g['psn_cid']?.toString() ?? '',
        'appid': g['appid']?.toString() ?? '',
        'name': g['game_name']?.toString() ?? '',
        'cover_url': g['game_img']?.toString() ?? '',
        'platform': platforms[g['psn_cid']?.toString()] ?? '',
        'completion_rate': ((g['progress'] ?? 0) as num).toDouble(),
        'playtime_second': g['playtime_second'] ?? 0,
        'playtime_desc': g['playtime_desc']?.toString() ?? '',
        'playtime_percent': g['playtime_percent'] ?? 0,
        'last_play_date': g['last_play_date']?.toString() ?? '',
        'platinum': g['has_platinum'] == 1 ? 1 : 0,
        'gold': g['gold'] ?? 0,
        'silver': g['silver'] ?? 0,
        'bronze': g['bronze'] ?? 0,
        'achieved_count': g['achieved_count'] ?? 0,
        'achievement_count': g['achivement_count'] ?? 0,
        'start_color': g['start_color']?.toString() ?? '',
        'end_color': g['end_color']?.toString() ?? '',
        // 保留原始数据
        '_xhh': g,
      };
    }).toList();

    return {
      'psn_id': playerId,
      'nickname': player['nickname']?.toString() ?? playerId,
      'avatar': player['avatar']?.toString() ?? '',
      'level': player['level'] ?? 0,
      'country': player['country']?.toString() ?? '',
      'country_flag': player['country_flag']?.toString() ?? '',
      'update_desc': player['update_desc']?.toString() ?? '',
      'total_hours': totalHours,
      'total_games': totalGames,
      'total_trophies': totalTrophies,
      'platinum': platinum,
      'gold': gold,
      'silver': silver,
      'bronze': bronze,
      'games': mappedGames,
    };
  }
}
