import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _apiUrl =
      'https://api.github.com/repos/ShinyYann/trophyroom/releases/latest';

  /// Check for update. Returns (hasUpdate, latestVersion, downloadUrl, releaseNotes)
  static Future<Map<String, dynamic>?> checkUpdate(String currentVersion) async {
    try {
      final resp = await http
          .get(Uri.parse(_apiUrl), headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'TrophyRoom/1.0',
          })
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return null;

      final data = json.decode(resp.body);
      final latestTag = data['tag_name'] as String? ?? '';
      final assets = data['assets'] as List? ?? [];
      String? downloadUrl;
      for (final a in assets) {
        final name = a['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = a['browser_download_url'] as String?;
          break;
        }
      }
      if (downloadUrl == null && assets.isNotEmpty) {
        downloadUrl = assets[0]['browser_download_url'] as String?;
      }
      downloadUrl ??= '${_apiUrl.replaceAll('/releases/latest', '/releases/latest/download/TrophyRoom.apk')}';

      final hasUpdate = _compareVersions(latestTag, currentVersion);
      return {
        'hasUpdate': hasUpdate,
        'latestVersion': latestTag,
        'downloadUrl': downloadUrl,
        'releaseNotes': data['body'] as String? ?? '',
      };
    } catch (e) {
      debugPrint('checkUpdate error: $e');
      return null;
    }
  }

  static bool _compareVersions(String latest, String current) {
    final lNum = int.tryParse(latest.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final cNum = int.tryParse(current.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return lNum > cNum;
  }

  /// Download APK and open with system installer
  static Future<void> downloadAndInstall(
      BuildContext context, String url) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📥 正在下载更新...')),
      );

      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/TrophyRoom-Update.apk');

      // Download with progress
      final resp = await http
          .get(Uri.parse(url), headers: {
            'User-Agent': 'TrophyRoom/1.0',
          })
          .timeout(const Duration(minutes: 3));

      await file.writeAsBytes(resp.bodyBytes);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Open file with system intent
      final uri = Uri.parse('file://${file.path}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: tell user where the file is
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载完成! 请手动打开: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 下载失败: $e')),
      );
    }
  }
}
