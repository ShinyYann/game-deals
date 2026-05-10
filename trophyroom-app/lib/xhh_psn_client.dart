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
    // 先试小黑盒
    try {
      final overview = await fetchOverview();
      final games = await fetchGames();

      // 小黑盒 API 改版：player 为空说明走 download_url 新接口，放弃小黑盒
      if (overview['player'] is Map && (overview['player'] as Map).isNotEmpty) {
        return _buildFromXhh(overview, games);
      }
      print('[XHH] overview missing player, falling back to server API');
    } catch (e) {
      print('[XHH] failed, falling back to server API: $e');
    }

    // 小黑盒不给力 → 走自己的 PSN API 服务器
    return _fetchFromServer();
  }

  /// 从小黑盒数据构建统一格式
  Future<Map<String, dynamic>> _buildFromXhh(
      Map<String, dynamic> overview, List<Map<String, dynamic>> games) async {
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
      if (desc == '青铜' || desc == '黄铜') bronze = val;
    }

    final player = overview['player'] as Map<String, dynamic>? ?? {};
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
      };
    }).toList();

    return {
      'psn_id': playerId,
      'nickname': player['nickname']?.toString() ?? playerId,
      'avatar': player['avatar']?.toString() ?? '',
      'level': player['level'] ?? 0,
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

  /// 从自有 PSN API 服务器获取数据（小黑盒后备）
  Future<Map<String, dynamic>> _fetchFromServer() async {
    try {
      final resp = await http
          .get(Uri.parse('http://8.153.97.56/api/psn?uid=$playerId'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data.containsKey('error')) throw Exception(data['error']);

      final rawGames = (data['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final mappedGames = rawGames.map((g) {
        // 解析游玩时长 ISO 8601 → 秒
        int playtimeSeconds = 0;
        final iso = g['play_duration_raw']?.toString() ?? '';
        if (iso.isNotEmpty) {
          final h = RegExp(r'(\d+)H').firstMatch(iso);
          final m = RegExp(r'(\d+)M').firstMatch(iso);
          final s = RegExp(r'(\d+)S').firstMatch(iso);
          playtimeSeconds = (int.tryParse(h?.group(1) ?? '0') ?? 0) * 3600
                          + (int.tryParse(m?.group(1) ?? '0') ?? 0) * 60
                          + (int.tryParse(s?.group(1) ?? '0') ?? 0);
        }

        return {
          'game_id': g['id']?.toString() ?? g['np_id']?.toString() ?? '',
          'name': g['name']?.toString() ?? '',
          'cover_url': g['cover_url']?.toString() ?? '',
          'platform': g['platform']?.toString() ?? '',
          'completion_rate': (g['progress'] as num?)?.toDouble() ?? 0,
          'playtime_second': playtimeSeconds,
          'playtime_desc': g['play_duration']?.toString() ?? '',
          'last_play_date': g['last_played']?.toString() ?? '',
          'platinum': _safeInt(g['platinum']),
          'gold': _safeInt(g['gold']),
          'silver': _safeInt(g['silver']),
          'bronze': _safeInt(g['bronze']),
          'achieved_count': _safeInt(g['earned']),
          'achievement_count': _safeInt(g['defined']),
        };
      }).toList();

      return {
        'psn_id': playerId,
        'nickname': playerId,
        'avatar': '',
        'level': _safeInt(data['level']),
        'total_hours': 0,
        'total_games': _safeInt(data['total_games']),
        'total_trophies': _safeInt(data['total_trophies']),
        'platinum': _safeInt(data['platinum']),
        'gold': _safeInt(data['gold']),
        'silver': _safeInt(data['silver']),
        'bronze': _safeInt(data['bronze']),
        'games': mappedGames,
        'psn_data_source': 'server',
      };
    } catch (e) {
      print('[PSN Server] fallback failed: $e');
      // 最后兜底
      return {
        'psn_id': playerId,
        'nickname': playerId,
        'avatar': '',
        'level': 0,
        'total_hours': 0,
        'total_games': 0,
        'total_trophies': 0,
        'platinum': 0,
        'gold': 0,
        'silver': 0,
        'bronze': 0,
        'games': [],
      };
    }
  }
}
