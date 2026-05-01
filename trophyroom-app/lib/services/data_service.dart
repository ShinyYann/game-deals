import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DataService {
  static const String _githubRaw = 'https://shinyyann.github.io/trophyroom/data';
  
  String get baseUrl => _githubRaw;

  /// Fetch deals from generated JSON
  Future<List<Map<String, dynamic>>> fetchDeals({String platform = 'all'}) async {
    try {
      final url = '$_githubRaw/deals.json';
      final body = await _httpGet(url);
      if (body != null) {
        final data = json.decode(body) as List;
        final deals = data.cast<Map<String, dynamic>>();
        if (platform != 'all') {
          return deals.where((d) =>
            (d['platform'] as String?)?.toLowerCase().contains(platform.toLowerCase()) ?? false
          ).toList();
        }
        return deals;
      }
    } catch (e) {
      debugPrint('fetchDeals error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final url = '$_githubRaw/stats.json';
      final body = await _httpGet(url);
      if (body != null) {
        return json.decode(body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('fetchStats error: $e');
    }
    return {'platinum': '0', 'all_achievements': '0', 'games': '0', 'total_deals': '0'};
  }

  /// Core HTTP GET using dart:io HttpClient
  Future<String?> _httpGet(String url) async {
    final uri = Uri.parse(url);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = ((cert, host, port) => true);

    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'TrophyRoom/1.0');
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await utf8.decodeStream(response);
      }
      debugPrint('HTTP \${response.statusCode}: \$url');
    } catch (e) {
      debugPrint('_httpGet error: \$e');
      // Fallback: raw TCP socket
      return await _socketGet(uri);
    } finally {
      client.close();
    }
    return null;
  }

  /// Raw TCP socket HTTP request (fallback for locked-down networks)
  Future<String?> _socketGet(Uri uri) async {
    try {
      final socket = await SecureSocket.connect(
        uri.host, 443,
        timeout: const Duration(seconds: 10),
        onBadCertificate: (cert) => true,
      );

      final path = uri.path.isNotEmpty ? uri.path : '/';
      final httpRequest = 'GET \$path HTTP/1.1\r\n'
          'Host: \${uri.host}\r\n'
          'User-Agent: TrophyRoom/1.0\r\n'
          'Connection: close\r\n'
          '\r\n';

      socket.write(httpRequest);
      await socket.flush();
      final response = await utf8.decodeStream(socket);
      final parts = response.split('\r\n\r\n');
      if (parts.length > 1) {
        return parts.sublist(1).join('\r\n\r\n');
      }
    } catch (e) {
      debugPrint('_socketGet error: \$e');
    }
    return null;
  }
}
