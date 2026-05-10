/// 桌面小组件更新器
/// 1. Flutter 写入 SharedPreferences
/// 2. Kotlin 从同一 SharedPreferences 读取
/// 3. MethodChannel 只负责触发刷新通知（不传输数据）
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('com.trophyroom.trophyroom/widget');

class WidgetUpdater {
  static Timer? _timer;

  /// 初始化：写入默认值 + 首次推送
  static Future<void> init() async {
    // 先写入默认占位数据，确保 widget 至少能显示文案而非空
    await _writeDefaults();
    // 首次推送 + 定时推送
    await _push();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _push());
  }

  /// 写入默认占位数据
  static Future<void> _writeDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    // 只覆盖尚未写入的 key
    if (prefs.getString('widget_title') == null) {
      await prefs.setString('widget_title', '🏆 奖杯屋');
    }
    if (prefs.getString('widget_psn') == null) {
      await prefs.setString('widget_psn', '🏆 PSN: -');
    }
    if (prefs.getString('widget_steam') == null) {
      await prefs.setString('widget_steam', '🎮 Steam: -');
    }
    if (prefs.getString('widget_switch') == null) {
      await prefs.setString('widget_switch', '🕹️ Switch: -');
    }
    if (prefs.getString('widget_pokemon') == null) {
      await prefs.setString('widget_pokemon', '🐉 宝可梦: -');
    }
    if (prefs.getString('widget_updated') == null) {
      await prefs.setString('widget_updated', '--');
    }
  }

  /// 首页数据就绪后调用 — 写入缓存并推送组件
  static Future<void> pushHomeData({
    required String psnTrophies,
    required String psnPlat,
    required String steamGames,
    required String steamAchievements,
    required String switchGames,
    required String switchHours,
  }) async {
    final now = DateTime.now();
    final updated =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final hasPsn = psnTrophies != '-' && psnTrophies.isNotEmpty;
    final hasSteam = steamGames != '-' || steamAchievements != '-';
    final hasSwitch = switchGames != '-' || switchHours != '-';

    // 有数据 → 显示真实数据
    // 无数据 → 显示 -
    final psnText = hasPsn
        ? (psnPlat != '-' && psnPlat != '0'
            ? '🏆 PSN: $psnTrophies ($psnPlat👑)'
            : '🏆 PSN: $psnTrophies')
        : '🏆 PSN: -';

    final steamText = hasSteam
        ? (steamAchievements != '-' && steamAchievements.isNotEmpty
            ? '🎮 Steam: $steamAchievements'
            : '🎮 Steam: $steamGames 个')
        : '🎮 Steam: -';

    final switchText = hasSwitch
        ? (switchHours != '-' && switchHours.isNotEmpty
            ? '🕹️ Switch: $switchGames / ${switchHours}h'
            : '🕹️ Switch: $switchGames 个')
        : '🕹️ Switch: -';

    // 1. 写入 Flutter SharedPreferences（始终写入，即使数据未就绪）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_psn', psnText);
    await prefs.setString('widget_steam', steamText);
    await prefs.setString('widget_switch', switchText);
    await prefs.setString('widget_updated', updated);
    await prefs.setString('widget_title', '🏆 奖杯屋');

    // 2. 通知 Kotlin 侧刷新组件（直接传数据，不依赖 SharedPreferences）
    await _pushData({
      'title': '🏆 奖杯屋',
      'psn': psnText,
      'steam': steamText,
      'switch': switchText,
      'pokemon': prefs.getString('widget_pokemon') ?? '🐉 宝可梦: -',
      'updated': updated,
    });
  }

  /// 推送宝可梦数据
  static Future<void> pushPokemonData(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_pokemon', text);
    await _pushData({
      'pokemon': text,
    });
  }

  /// 直接通过 MethodChannel 传数据刷新组件
  static Future<void> _pushData(Map<String, String> data) async {
    try {
      await _channel.invokeMethod('refreshWidget', data);
    } catch (e) {
      print('[WidgetUpdater] pushData failed: $e');
    }
  }

  /// 从 SharedPreferences 读取数据并通知 Kotlin 刷新组件
  static Future<void> _push() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _pushData({
        'title': prefs.getString('widget_title') ?? '🏆 奖杯屋',
        'psn': prefs.getString('widget_psn') ?? '🏆 PSN: -',
        'steam': prefs.getString('widget_steam') ?? '🎮 Steam: -',
        'switch': prefs.getString('widget_switch') ?? '🕹️ Switch: -',
        'updated': prefs.getString('widget_updated') ?? '--',
      });
    } catch (e) {
      print('[WidgetUpdater] push failed: $e');
    }
  }

  /// 手动调试推送，返回 true=成功 false=失败
  static Future<bool> debugPush() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await _channel.invokeMethod('refreshWidget', {
        'title': prefs.getString('widget_title') ?? '🏆 奖杯屋',
        'psn': prefs.getString('widget_psn') ?? '🏆 PSN: 调试',
        'steam': prefs.getString('widget_steam') ?? '🎮 Steam: 调试',
        'switch': prefs.getString('widget_switch') ?? '🕹️ Switch: 调试',
        'updated': '调试模式',
      });
      if (result is Map) {
        print('[WidgetUpdater] debugPush result: $result');
      }
      return true;
    } catch (e) {
      print('[WidgetUpdater] debugPush failed: $e');
      return false;
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
