import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _apiUrl =
      'https://api.github.com/repos/ShinyYann/trophyroom/releases/latest';

  /// Check for update. Returns (hasUpdate, latestVersion, downloadUrl, releaseNotes)
  static Future<Map<String, dynamic>?> checkUpdate(String currentVersion) async {
    try {
      final uri = Uri.parse(_apiUrl);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = ((cert, host, port) => true);

      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      request.headers.set('User-Agent', 'TrophyRoom/1.0');

      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = await utf8.decodeStream(response);
      client.close();

      final data = json.decode(body);
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
      downloadUrl ??= 'https://github.com/ShinyYann/trophyroom/releases/latest/download/TrophyRoom.apk';

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

      final uri = Uri.parse(url);
      final client = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'TrophyRoom/1.0');
      final response = await request.close().timeout(const Duration(minutes: 3));

      final bytes = await response.fold<List<int>>(
        <int>[], (prev, chunk) => prev..addAll(chunk),
      );
      await file.writeAsBytes(bytes);
      client.close();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final fUri = Uri.parse('file://${file.path}');
      if (await canLaunchUrl(fUri)) {
        await launchUrl(fUri);
      } else {
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
