import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DataService {
  static const String _giteeBase =
      'https://gitee.com/yann8888/game-deals/raw/main';
  static const String _githubBase =
      'https://raw.githubusercontent.com/ShinyYann/trophyroom/main';

  String get baseUrl => _giteeBase;

  /// Fetch JSON using dart:io HttpClient (bypasses Flutter http package)
  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final url = '$baseUrl/docs/data/stats.json';
      final body = await _httpGet(url);
      if (body != null) {
        return json.decode(body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('fetchStats error: $e');
    }
    return {'platinum': '0', 'all_achievements': '0', 'games': '0'};
  }

  Future<List<Map<String, dynamic>>> fetchDeals({String platform = 'all'}) async {
    try {
      final url = '$baseUrl/docs/data/deals.json';
      final body = await _httpGet(url);
      if (body != null) {
        final data = json.decode(body) as List;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('fetchDeals error: $e');
    }
    return [];
  }

  /// Core HTTP GET using dart:io HttpClient
  Future<String?> _httpGet(String url) async {
    final uri = Uri.parse(url);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = ((cert, host, port) => true); // Accept any cert

    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'TrophyRoom/1.0');
      request.headers.set('Accept', '*/*');
      request.headers.set('Connection', 'keep-alive');

      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await utf8.decodeStream(response);
      } else {
        debugPrint('HTTP ${response.statusCode}: $url');
        return null;
      }
    } catch (e) {
      debugPrint('_httpGet error: $e');
      // Fallback: try with socket directly
      return await _socketGet(uri);
    } finally {
      client.close();
    }
  }

  /// Last resort: raw TCP socket connection + manual HTTP request
  Future<String?> _socketGet(Uri uri) async {
    try {
      final host = uri.host;
      final port = uri.scheme == 'https' ? 443 : 80;
      final path = uri.path.isNotEmpty ? uri.path : '/';
      final query = uri.query.isNotEmpty ? '?${uri.query}' : '';

      debugPrint('_socketGet: connecting to $host:$port$path$query');

      final socket = await SecureSocket.connect(
        host, port,
        timeout: const Duration(seconds: 10),
        // Accept any certificate to avoid Android 15 SSL issues
        onBadCertificate: (cert) => true,
      );

      // Send raw HTTP request
      final httpRequest = 'GET $path$query HTTP/1.1\r\n'
          'Host: $host\r\n'
          'User-Agent: TrophyRoom/1.0\r\n'
          'Accept: */*\r\n'
          'Connection: close\r\n'
          '\r\n';

      socket.write(httpRequest);
      await socket.flush();

      // Read response
      final response = await utf8.decodeStream(socket);
      socket.close();

      // Parse out headers and body
      final parts = response.split('\r\n\r\n');
      if (parts.length >= 2) {
        final statusLine = parts[0].split('\r\n')[0];
        debugPrint('Socket response: $statusLine');
        return parts.sublist(1).join('\r\n\r\n');
      }
      return response;
    } catch (e) {
      debugPrint('_socketGet error: $e');
      return null;
    }
  }
}
