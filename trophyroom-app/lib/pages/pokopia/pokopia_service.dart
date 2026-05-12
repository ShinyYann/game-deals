import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pokopia_models.dart';

class PokopiaService {
  static const String _baseUrl = 'http://8.153.97.56:3000/api/pokopia';

  // In-memory caches
  static Map<String, dynamic>? _allData;

  /// Fetch all data at once and cache locally
  static Future<Map<String, dynamic>> fetchAll() async {
    if (_allData != null) return _allData!;
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/all')).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        _allData = json.decode(resp.body);
        return _allData!;
      }
    } catch (_) {}
    return {};
  }

  static Future<PokopiaSummary> fetchSummary() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/summary')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return PokopiaSummary.fromJson(json.decode(resp.body));
      }
    } catch (_) {}
    return PokopiaSummary(lastUpdated: '', counts: {});
  }

  static Future<List<PokopiaEvent>> fetchEvents() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/events')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        return list.map((e) => PokopiaEvent.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<PokopiaNews>> fetchNews() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/news')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        return list.map((e) => PokopiaNews.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<PokopiaPokemon>> fetchPokemon({String? query}) async {
    try {
      var url = '$_baseUrl/pokemon';
      if (query != null && query.isNotEmpty) url += '?q=${Uri.encodeComponent(query)}';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        return list.map((e) => PokopiaPokemon.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<PokopiaHabitat>> fetchHabitats({String? query}) async {
    try {
      var url = '$_baseUrl/habitats';
      if (query != null && query.isNotEmpty) url += '?q=${Uri.encodeComponent(query)}';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        return list.map((e) => PokopiaHabitat.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<PokopiaGuide>> fetchGuides({String? query}) async {
    try {
      var url = '$_baseUrl/guides';
      if (query != null && query.isNotEmpty) url += '?q=${Uri.encodeComponent(query)}';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        return list.map((e) => PokopiaGuide.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<PokopiaCharacter>> fetchCharacters() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/characters')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        return list.map((e) => PokopiaCharacter.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<PokopiaTown>> fetchTowns() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/towns')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        return list.map((e) => PokopiaTown.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> search(String query) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}')).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      }
    } catch (_) {}
    return {'query': query, 'results': []};
  }

  /// Clear cache to force fresh fetch
  static void clearCache() => _allData = null;
}
