/// PSN API 客户端 — 手机端直接调索尼 API，不走服务器中转
///
/// 阿里云无法访问索尼 API，故在手机端直接发起请求
import 'dart:convert';
import 'package:http/http.dart' as http;

class PsnApiClient {
  static const String _baseUrl = 'https://m.np.playstation.com/api';
  static const String _authBase = 'https://ca.account.sony.com/api/authz/v3';

  String? _npsso;
  String? _accessToken;
  int _tokenExpiresAt = 0;

  PsnApiClient(this._npsso);

  /// 用 NPSSO 获取 access token
  Future<String?> getAccessToken() async {
    if (_accessToken != null && DateTime.now().millisecondsSinceEpoch ~/ 1000 < _tokenExpiresAt) {
      return _accessToken;
    }

    if (_npsso == null || _npsso!.isEmpty) return null;

    try {
      final authStr = base64Encode(utf8.encode('09515159-7237-4370-9b40-3806e67c0891:ucPjka5tntB2KqsP'));
      final resp = await http.post(
        Uri.parse('$_authBase/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $authStr',
          'Cookie': 'npsso=$_npsso',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': 'oGbQW7osP9AXx2kBz07i1M9DkwAHVSydlDdBXxM24R8',
          'token_format': 'jwt',
          'scope': 'psn:mobile.v2.core psn:clientapp',
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _accessToken = data['access_token'];
        final expiresIn = (data['expires_in'] ?? 3600) as int;
        _tokenExpiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn - 300;
        return _accessToken;
      }
    } catch (e) {
      print('[PSN API] Token error: $e');
    }
    return null;
  }

  /// 获取 PSN 账号基本信息
  Future<String?> getOnlineId() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final resp = await http.get(
        Uri.parse('https://m.np.playstation.com/api/userProfile/v1/internal/users/me/profile2'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['onlineId'];
      }
    } catch (e) {
      print('[PSN API] Profile error: $e');
    }
    return null;
  }

  /// 获取游戏列表（含时长）
  Future<List<Map<String, dynamic>>?> getGames() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/gamelist/v2/users/me/titles?limit=200&offset=0'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final titles = data['titles'] as List? ?? [];
        return titles.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('[PSN API] Games error: $e');
    }
    return null;
  }

  /// 获取某个游戏的奖杯列表
  Future<List<Map<String, dynamic>>?> getTrophies(String npCommunicationId) async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/trophy/v1/users/me/groups/0/titles/$npCommunicationId/trophies?limit=999'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final trophies = data['trophies'] as List? ?? [];
        return trophies.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('[PSN API] Trophies error: $e');
    }
    return null;
  }

  /// 获取游戏奖杯进度摘要
  Future<Map<String, dynamic>?> getTitleTrophies(String npCommunicationId) async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/trophy/v1/users/me/groups/0/titles/$npCommunicationId/all'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
    } catch (e) {
      print('[PSN API] Title trophies error: $e');
    }
    return null;
  }
}
