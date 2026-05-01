import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class DataService {
  static const String _htmlUrl =
      'https://shinyyann.github.io/trophyroom/';

  String get baseUrl => _htmlUrl;

  /// Fetch deals from the HTML page (parsed in Flutter/Dart)
  Future<List<Map<String, dynamic>>> fetchDeals({String platform = 'all'}) async {
    final html = await _fetchHtml();
    if (html == null) return [];

    final deals = <Map<String, dynamic>>[];
    
    // Parse game cards from HTML data attributes
    final cardPattern = RegExp(
      r'<div\s+class="game-card"[^>]*data-title="([^"]*)"'
      r'\s+data-desc="([^"]*)"'
      r'\s+data-url="([^"]*)"'
      r'\s+data-price="([^"]*)"'
      r'\s+data-oldprice="([^"]*)"'
      r'\s+data-discount="([^"]*)"'
      r'\s+data-platform="([^"]*)"'
      r'\s+data-img="([^"]*)"'
      r'\s+data-tags="([^"]*)"'
      r'\s+data-rating="([^"]*)"'
      r'[^>]*>',
      caseSensitive: false,
    );

    for (final match in cardPattern.allMatches(html)) {
      final title = _unescape(match.group(1) ?? '');
      final desc = _unescape(match.group(2) ?? '');
      final url = _unescape(match.group(3) ?? '');
      final price = _unescape(match.group(4) ?? '0');
      final oldPrice = _unescape(match.group(5) ?? '0');
      final discount = _unescape(match.group(6) ?? '0%');
      final plat = _unescape(match.group(7) ?? '');
      final img = _unescape(match.group(8) ?? '');
      final tags = _unescape(match.group(9) ?? '');
      final rating = _unescape(match.group(10) ?? '');

      if (platform != 'all' && !plat.contains(platform)) continue;

      deals.add({
        'title': title,
        'description': desc,
        'url': url,
        'price': price,
        'old_price': oldPrice,
        'discount': discount,
        'platform': plat,
        'image': img,
        'tags': tags.split('|').where((t) => t.isNotEmpty).toList(),
        'rating': rating,
      });
    }

    // Fallback: try parsing cards from inline JSON
    if (deals.isEmpty) {
      deals.addAll(await _fetchFromJson());
    }

    return deals;
  }

  /// Parse inline JSON from the HTML
  Future<List<Map<String, dynamic>>> _fetchFromJson() async {
    final html = await _fetchHtml();
    if (html == null) return [];

    // Try to find JSON data embedded in script tags
    final scriptPattern = RegExp(
      r'<script[^>]*>\s*window\.__DATA__\s*=\s*(\{.+?\})\s*</script>',
      caseSensitive: false,
      dotAll: true,
    );
    
    for (final match in scriptPattern.allMatches(html)) {
      try {
        final data = json.decode(match.group(1)!) as Map<String, dynamic>;
        if (data.containsKey('deals')) {
          return (data['deals'] as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }

    return [];
  }

  /// Fetch the HTML from GitHub Pages
  Future<String?> _fetchHtml() async {
    final uri = Uri.parse(_htmlUrl);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = ((cert, host, port) => true);

    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'TrophyRoom/1.0');
      final response = await request.close().timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }
    } catch (e) {
      debugPrint('_fetchHtml error: $e');
      // Fallback: raw socket
      return await _socketGet(uri);
    } finally {
      client.close();
    }
    return null;
  }

  /// Raw TCP socket HTTP request (fallback)
  Future<String?> _socketGet(Uri uri) async {
    try {
      final socket = await SecureSocket.connect(
        uri.host, 443,
        timeout: const Duration(seconds: 10),
        onBadCertificate: (cert) => true,
      );

      final path = uri.path.isNotEmpty ? uri.path : '/';
      final httpRequest = 'GET $path HTTP/1.1\r\n'
          'Host: ${uri.host}\r\n'
          'User-Agent: TrophyRoom/1.0\r\n'
          'Connection: close\r\n'
          '\r\n';

      socket.write(httpRequest);
      await socket.flush();
      
      final response = await utf8.decodeStream(socket);
      // Extract body after headers
      final parts = response.split('\r\n\r\n');
      if (parts.length > 1) {
        return parts.sublist(1).join('\r\n\r\n');
      }
    } catch (e) {
      debugPrint('_socketGet error: $e');
    }
    return null;
  }

  String _unescape(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/');
  }
}
