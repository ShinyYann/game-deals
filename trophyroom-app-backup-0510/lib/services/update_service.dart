/// 热更新服务
/// 检查版本 → 打开浏览器下载 APK
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _channel = MethodChannel('com.trophyroom.trophyroom/update');

class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String changelog;

  AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    this.changelog = '',
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      versionCode: json['versionCode'] as int? ?? 0,
      versionName: json['versionName'] as String? ?? '',
      apkUrl: json['apkUrl'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
    );
  }

  bool get isValid => versionCode > 0 && apkUrl.isNotEmpty;
}

class UpdateService {
  static const String _serverUrl = 'http://8.153.97.56/apk/version.json';
  static String _lastError = '';

  /// 获取最后一次错误信息（用于调试）
  static String getLastError() => _lastError;

  /// 从 native 获取当前版本号
  static Future<int> _getCurrentVersionCode() async {
    try {
      final code = await _channel.invokeMethod<int>('getVersionCode');
      return code ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 检查是否有新版本（不会拉取进度，只返回结果）
  static Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final currentVersion = await _getCurrentVersionCode();
      if (currentVersion <= 0) return null;

      final client = http.Client();
      final response = await client
          .get(Uri.parse(_serverUrl))
          .timeout(const Duration(seconds: 8));
      client.close();

      if (response.statusCode != 200) return null;

      final info = AppUpdateInfo.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
      if (!info.isValid) return null;

      if (info.versionCode > currentVersion) {
        return info;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 下载 APK 并安装 — 直接打开浏览器下载（最可靠）
  static Future<bool> downloadAndInstall({
    required String apkUrl,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // 直接用浏览器打开 APK 下载链接
      // 系统浏览器下载 → 用户点通知安装，100% 可靠
      final uri = Uri.parse(apkUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      _lastError = '无法打开浏览器';
      return false;
    } catch (e) {
      _lastError = e.toString();
      print('[UpdateService] downloadAndInstall failed: $e');
      return false;
    }
  }
}
