/// 注册/登录/数据同步服务
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// 所有 API 路径统一前缀 /api/auth/
  /// /api/auth/register — 注册
  /// /api/auth/login — 登录
  /// /api/auth/upload — 上传数据 (需 Bearer token)
  /// /api/auth/download — 下载数据 (需 Bearer token)
  /// /api/auth/ping — 活跃心跳 (需 Bearer token)

  static const String _api = 'http://8.153.97.56/api/auth';

  // ─── 账户 ──────────────────────────────────────

  /// 注册
  static Future<AuthResult> register(String username, String password) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.postUrl(Uri.parse('$_api/register'));
      req.headers.contentType = ContentType.json;
      req.write(json.encode({'username': username, 'password': password}));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final data = json.decode(body) as Map<String, dynamic>;
      client.close();
      if (resp.statusCode == 200) {
        return AuthResult.ok(data['token'] as String, data['username'] as String);
      }
      return AuthResult.fail(data['error'] as String? ?? '注册失败');
    } catch (e) {
      return AuthResult.fail('网络错误: $e');
    }
  }

  /// 登录
  static Future<AuthResult> login(String username, String password) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.postUrl(Uri.parse('$_api/login'));
      req.headers.contentType = ContentType.json;
      req.write(json.encode({'username': username, 'password': password}));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final data = json.decode(body) as Map<String, dynamic>;
      client.close();
      if (resp.statusCode == 200) {
        return AuthResult.ok(data['token'] as String, data['username'] as String);
      }
      return AuthResult.fail(data['error'] as String? ?? '登录失败');
    } catch (e) {
      return AuthResult.fail('网络错误: $e');
    }
  }

  /// 保存 token 到本地
  static Future<void> saveToken(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_username', username);
  }

  /// 读取本地 token
  static Future<({String? token, String? username})> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      token: prefs.getString('auth_token'),
      username: prefs.getString('auth_username'),
    );
  }

  /// 是否已登录
  static Future<bool> isLoggedIn() async {
    final t = await loadToken();
    return t.token != null && t.token!.isNotEmpty;
  }

  /// 退出登录（清本地 + 可选清数据）
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_username');
  }

  // ─── 数据同步 ──────────────────────────────────────

  /// 上传所有用户数据到服务器
  static Future<bool> syncUpload({
    required String token,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = data ?? _buildSyncPayload(prefs);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final req = await client.postUrl(Uri.parse('$_api/upload'));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization', 'Bearer $token');
      req.write(json.encode(payload));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 从服务器下载用户数据
  static Future<Map<String, dynamic>?> syncDownload({required String token}) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(Uri.parse('$_api/download'));
      req.headers.set('Authorization', 'Bearer $token');
      final resp = await req.close();
      if (resp.statusCode != 200) return null;
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 构建要同步的数据
  static Map<String, dynamic> _buildSyncPayload(SharedPreferences prefs) {
    return {
      'psn_id': prefs.getString('psn_id') ?? '',
      'steam_id': prefs.getString('steam_id') ?? '',
      'switch_token': prefs.getString('switch_token') ?? '',
      'shiny_collection': prefs.getString('shiny_collection') ?? '{}',
      'active_effects': prefs.getString('active_effects') ?? 'none',
      'widget_enabled': prefs.getBool('widget_enabled') ?? false,
      'settings': {
        'psn_id': prefs.getString('psn_id') ?? '',
        'steam_id': prefs.getString('steam_id') ?? '',
      },
    };
  }

  /// 将服务器数据应用到本地
  /// 返回额外数据（如 _admin 统计）
  static Future<void> applyRemoteData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['psn_id'] is String && (data['psn_id'] as String).isNotEmpty) {
      await prefs.setString('psn_id', data['psn_id'] as String);
    }
    if (data['steam_id'] is String && (data['steam_id'] as String).isNotEmpty) {
      await prefs.setString('steam_id', data['steam_id'] as String);
    }
    if (data['shiny_collection'] is String) {
      await prefs.setString('shiny_collection', data['shiny_collection'] as String);
    }
    if (data['active_effects'] is String) {
      await prefs.setString('active_effects', data['active_effects'] as String);
    }
    if (data['switch_token'] is String) {
      final token = (data['switch_token'] as String).trim();
      if (token.isNotEmpty) {
        await prefs.setString('switch_token', token);
      }
    }
  }

  // ─── 活跃心跳 ──────────────────────────────────────

  /// 发送活跃心跳（App 每 5 分钟调用一次）
  static Future<bool> ping({required String token}) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.postUrl(Uri.parse('$_api/ping'));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization', 'Bearer $token');
      req.write('{}');
      final resp = await req.close();
      client.close();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final String? username;
  final String? error;

  AuthResult._(this.success, this.token, this.username, this.error);

  factory AuthResult.ok(String token, String username) =>
      AuthResult._(true, token, username, null);

  factory AuthResult.fail(String error) =>
      AuthResult._(false, null, null, error);
}
