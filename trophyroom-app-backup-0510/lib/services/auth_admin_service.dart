/// Auth Admin Service — 使用 auth server API 替代 Supabase
/// 提供注册审核（pending/active/rejected）+ 在线用户功能
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthAdminService {
  static const String _api = 'http://8.153.97.56/api/auth';

  // ═══════════════════════════════════════════════
  // 用户状态查询
  // ═══════════════════════════════════════════════

  /// 获取用户状态（pending / active / rejected / null）
  static Future<String?> getUserStatus(String token) async {
    if (token.isEmpty) return null;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6);
      final req = await client.getUrl(Uri.parse('$_api/download'));
      req.headers.set('Authorization', 'Bearer $token');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      if (resp.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        // 如果 pending 状态，返回 "pending"
        if (data.containsKey('status') && data['status'] == 'pending') {
          return 'pending';
        }
        // 成功了代表 active
        return 'active';
      } else if (resp.statusCode == 403) {
        // rejected 用户返回 403
        return 'rejected';
      }
      return null;
    } catch (e) {
      print('[AuthAdmin] getUserStatus error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  // 管理员 — 待审核用户列表
  // ═══════════════════════════════════════════════

  /// 获取待审核用户列表
  static Future<List<Map<String, dynamic>>> getPendingRequests(
      String token) async {
    if (token.isEmpty) return [];
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6);
      final req = await client.getUrl(Uri.parse('$_api/admin/requests'));
      req.headers.set('Authorization', 'Bearer $token');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      if (resp.statusCode == 200) {
        final list = json.decode(body) as List;
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[AuthAdmin] getPendingRequests error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // 管理员 — 审核操作
  // ═══════════════════════════════════════════════

  /// 通过审核
  static Future<bool> approveUser(String token, int userId) async {
    if (token.isEmpty) return false;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.postUrl(Uri.parse('$_api/admin/approve'));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization', 'Bearer $token');
      req.write(json.encode({'user_id': userId}));
      final resp = await req.close();
      await resp.transform(utf8.decoder).join();
      client.close();
      return resp.statusCode == 200;
    } catch (e) {
      print('[AuthAdmin] approveUser error: $e');
      return false;
    }
  }

  /// 拒绝审核
  static Future<bool> rejectUser(String token, int userId) async {
    if (token.isEmpty) return false;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req = await client.postUrl(Uri.parse('$_api/admin/reject'));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization', 'Bearer $token');
      req.write(json.encode({'user_id': userId}));
      final resp = await req.close();
      await resp.transform(utf8.decoder).join();
      client.close();
      return resp.statusCode == 200;
    } catch (e) {
      print('[AuthAdmin] rejectUser error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // 管理员 — 在线用户
  // ═══════════════════════════════════════════════

  /// 获取在线用户列表
  static Future<List<Map<String, dynamic>>> getOnlineUsers(
      String token) async {
    if (token.isEmpty) return [];
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6);
      final req = await client.getUrl(Uri.parse('$_api/admin/online'));
      req.headers.set('Authorization', 'Bearer $token');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      if (resp.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        if (data['online'] is List) {
          return (data['online'] as List).cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('[AuthAdmin] getOnlineUsers error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // 时间格式化
  // ═══════════════════════════════════════════════

  /// 将秒数格式化为「刚刚」「X 分钟前」「X 小时前」
  static String formatTimeAgo(int secondsAgo) {
    if (secondsAgo < 30) return '刚刚';
    if (secondsAgo < 60) return '$secondsAgo 秒前';
    final minutes = secondsAgo ~/ 60;
    if (minutes < 60) return '$minutes 分钟前';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours 小时前';
    final days = hours ~/ 24;
    if (days < 7) return '$days 天前';
    return '${days ~/ 7} 周前';
  }

  // ═══════════════════════════════════════════════
  // 心跳 — 使用 AuthService.ping() 已有实现
  // 不需要额外方法
  // ═══════════════════════════════════════════════
}
