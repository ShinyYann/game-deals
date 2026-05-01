import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DataService {
  static const String _githubRaw = 'https://shinyyann.github.io/trophyroom/data';

  String get baseUrl => _githubRaw;

  Future<List<Map<String, dynamic>>> fetchDeals({String platform = 'all'}) async {
    try {
      final url = '$_githubRaw/deals.json';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TrophyRoom/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final deals = data.cast<Map<String, dynamic>>();
        if (platform != 'all') {
          return deals.where((d) =>
            (d['platform'] as String?)?.toLowerCase().contains(platform.toLowerCase()) ?? false
          ).toList();
        }
        return deals;
      }
      debugPrint('fetchDeals HTTP \${response.statusCode}');
    } catch (e) {
      debugPrint('fetchDeals error: \$e');
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final url = '$_githubRaw/stats.json';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TrophyRoom/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('fetchStats error: \$e');
    }
    return {'platinum': '0', 'all_achievements': '0', 'games': '0', 'total_deals': '0'};
  }
}
