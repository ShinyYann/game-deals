/// Switch 游戏库本地存储服务
///
/// 使用 shared_preferences 存储 JSON
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/switch_game.dart';

class SwitchService {
  static const String _keyPrefix = 'switch_games_';
  static const String _lastSyncKey = 'switch_last_sync';

  /// 获取当前 PSN ID 对应的 Switch 游戏列表 key
  static String _storageKey(String psnId) => '$_keyPrefix$psnId';

  /// 加载 Switch 游戏列表
  static Future<List<SwitchGame>> loadGames(String psnId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey(psnId));
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => SwitchGame.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[Switch] Load error: $e');
      return [];
    }
  }

  /// 保存 Switch 游戏列表
  static Future<void> saveGames(
      String psnId, List<SwitchGame> games) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_storageKey(psnId), jsonStr);
  }

  /// 添加游戏
  static Future<void> addGame(String psnId, SwitchGame game) async {
    final games = await loadGames(psnId);
    games.add(game);
    await saveGames(psnId, games);
  }

  /// 删除游戏
  static Future<void> removeGame(String psnId, int index) async {
    final games = await loadGames(psnId);
    if (index >= 0 && index < games.length) {
      games.removeAt(index);
      await saveGames(psnId, games);
    }
  }

  /// 更新游戏时长
  static Future<void> updatePlayTime(
      String psnId, int index, int hours, int minutes) async {
    final games = await loadGames(psnId);
    if (index >= 0 && index < games.length) {
      games[index] = SwitchGame(
        name: games[index].name,
        coverUrl: games[index].coverUrl,
        hoursPlayed: hours,
        minutesPlayed: minutes,
        comment: games[index].comment,
        addedAt: games[index].addedAt,
        lastPlayed: DateTime.now(),
      );
      await saveGames(psnId, games);
    }
  }

  /// 获取总游戏数和总时长
  static Future<Map<String, dynamic>> getStats(String psnId) async {
    final games = await loadGames(psnId);
    int totalMinutes = 0;
    for (final g in games) {
      totalMinutes += g.totalMinutes;
    }
    return {
      'count': games.length,
      'total_hours': (totalMinutes / 60).toStringAsFixed(1),
    };
  }
}
