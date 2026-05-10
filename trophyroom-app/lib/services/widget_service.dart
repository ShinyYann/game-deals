/// TrophyRoom 桌面组件数据服务
/// 从可用 API 获取综合数据，推送给桌面小组件

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const String _prefsKey = 'widget_dashboard';

  /// 获取首页集成看板数据
  static Future<Map<String, String>> getWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      return Map<String, String>.from(jsonDecode(cached));
    }
    return _fetchAll(prefs);
  }

  /// 强制刷新
  static Future<Map<String, String>> refreshWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    return _fetchAll(prefs);
  }

  /// 拉取各平台数据
  static Future<Map<String, String>> _fetchAll(SharedPreferences prefs) async {
    try {
      // 并行拉取 poke数据，其余平台走存根
      final futures = <Future>[];

      // 宝可梦图鉴统计
      futures.add(http
          .get(Uri.parse('http://8.153.97.56/api/poke/stats'))
          .timeout(const Duration(seconds: 8)));

      // 宝可梦聚焦（皮卡丘作为默认）
      futures.add(http
          .get(Uri.parse('http://8.153.97.56/api/poke/pokemon/25'))
          .timeout(const Duration(seconds: 8)));

      final results = await Future.wait(futures);

      // 宝可梦数据
      String pokemonText = '🐉 宝可梦: -';
      String psnText = '🏆 PSN: -';
      String steamText = '🎮 Steam: -';
      String switchText = '🕹️ Switch: -';
      String spotlightType = '';

      if (results[0] is http.Response) {
        final stats = jsonDecode((results[0] as http.Response).body);
        final count = stats['pokemon_count'] ?? 0;
        pokemonText = '🐉 宝可梦: $count';
      }

      // 从 pokemon 数据获取 spotlight 信息
      if (results[1] is http.Response) {
        try {
          final pkmn = jsonDecode((results[1] as http.Response).body);
          final name = pkmn['name_zh'] ?? '皮卡丘';
          final typeList = pkmn['type'] as List? ?? [];
          final type2 = pkmn['type2']?.toString() ?? '';
          final types = typeList.join('/') + (type2.isNotEmpty ? '/$type2' : '');
          spotlightType = '✨ $name · $types';
        } catch (_) {}
      }

      // 尝试从主 API 拉取综合数据（超时短，失败不影响）
      try {
        final dashRes = await http
            .get(Uri.parse('http://8.153.97.56/api/'))
            .timeout(const Duration(seconds: 4));
        if (dashRes.statusCode == 200) {
          final dash = jsonDecode(dashRes.body);
          final psn = dash['psn'] as Map? ?? {};
          final steam = dash['steam'] as Map? ?? {};
          final swi = dash['switch'] as Map? ?? {};

          final psnTrophies = psn['trophies'] ?? psn['total'] ?? '-';
          final psnPlat = psn['platinum'] ?? 0;
          psnText = psnPlat != 0
              ? '🏆 PSN: $psnTrophies ($psnPlat👑)'
              : '🏆 PSN: $psnTrophies';

          final achUnlocked = steam['achievements_unlocked'];
          final achTotal = steam['achievements_total'];
          if (achUnlocked != null && achTotal != null) {
            steamText = '🎮 Steam: $achUnlocked/$achTotal';
          } else if (steam['games'] != null) {
            steamText = '🎮 Steam: ${steam['games']} 个';
          }

          final swiGames = swi['games'];
          final swiHours = swi['hours'];
          if (swiGames != null) {
            switchText = swiHours != null
                ? '🕹️ Switch: $swiGames / ${swiHours}h'
                : '🕹️ Switch: $swiGames 个';
          }
        }
      } catch (_) {
        // 综合数据不可用时静默，只显示宝可梦
      }

      final now = DateTime.now();
      final updated =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final data = <String, String>{
        'psn_text': psnText,
        'steam_text': steamText,
        'switch_text': switchText,
        'pokemon_text': pokemonText,
        'spotlight': spotlightType,
        'updated': updated,
      };

      await prefs.setString(_prefsKey, jsonEncode(data));
      return data;
    } catch (e) {
      // 兜底：至少显示宝可梦数据
      try {
        final stats = await http
            .get(Uri.parse('http://8.153.97.56/api/poke/stats'))
            .timeout(const Duration(seconds: 5));
        if (stats.statusCode == 200) {
          final s = jsonDecode(stats.body);
          final count = s['pokemon_count'] ?? '-';
          final now = DateTime.now();
          final updated =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          return {
            'psn_text': '🏆 PSN: -',
            'steam_text': '🎮 Steam: -',
            'switch_text': '🕹️ Switch: -',
            'pokemon_text': '🐉 宝可梦: $count',
            'spotlight': '',
            'updated': updated,
          };
        }
      } catch (_) {}

      return {
        'psn_text': '🏆 PSN: -',
        'steam_text': '🎮 Steam: -',
        'switch_text': '🕹️ Switch: -',
        'pokemon_text': '🐉 宝可梦: -',
        'spotlight': '',
        'updated': '--',
      };
    }
  }
}
