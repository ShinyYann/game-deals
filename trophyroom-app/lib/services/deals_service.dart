import 'dart:convert';
import 'package:http/http.dart' as http;

class DealsService {
  static const String BASE = 'http://8.153.97.56/deals';

  /// Normalize platform name for app tabs (all lowercase)
  static String _normPlatform(String p) {
    final map = {
      'psn hk': 'psn',
      'steam': 'steam',
      'nintendo switch hk': 'switch',
    };
    return map[p.trim().toLowerCase()] ?? p.toLowerCase();
  }

  /// Fetch all deals from server, returns merged list
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    final sources = [
      'steam_deals.json',
      'psn_hk_deals.json',
      'nintendo_s_deals.json',
    ];

    final results = <Map<String, dynamic>>[];
    for (final src in sources) {
      try {
        final resp = await http
            .get(Uri.parse('$BASE/$src'))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) continue;

        final body = json.decode(resp.body);
        if (body is! Map || body['deals'] is! List) continue;

        for (final item in body['deals']) {
          if (item is! Map) continue;
          results.add({
            'img': item['image']?.toString() ?? '',
            'name': item['name']?.toString() ?? '?',
            'price': item['current_price']?.toString() ?? '',
            'original': item['original_price']?.toString() ?? '',
            'discount': item['discount']?.toString() ?? '',
            'platform': _normPlatform(
                item['platform']?.toString() ?? ''),
          });
        }
      } catch (_) {}
    }
    return results;
  }

  /// Quick fetch single platform
  static Future<List<Map<String, dynamic>>> fetchOne(String platform) async {
    final map = {
      'psn': 'psn_hk_deals.json',
      'steam': 'steam_deals.json',
      'switch': 'nintendo_s_deals.json',
    };
    final file = map[platform];
    if (file == null) return [];

    try {
      final resp = await http
          .get(Uri.parse('$BASE/$file'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final body = json.decode(resp.body);
      if (body is! Map || body['deals'] is! List) return [];

      return (body['deals'] as List).map((item) {
        if (item is! Map) return <String, dynamic>{};
        return {
          'img': item['image']?.toString() ?? '',
          'name': item['name']?.toString() ?? '?',
          'price': item['current_price']?.toString() ?? '',
          'original': item['original_price']?.toString() ?? '',
          'discount': item['discount']?.toString() ?? '',
          'platform': _normPlatform(
              item['platform']?.toString() ?? platform),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
