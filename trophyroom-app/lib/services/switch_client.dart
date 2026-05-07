/// 小黑盒 Switch 数据客户端 v3 — 多账号 + userid 兼容
import 'dart:convert';
import 'package:http/http.dart' as http;

class SwitchClient {
  static const String _apiBase = 'http://8.153.97.56';

  /// 获取所有 Switch 账号数据，返回列表
  static Future<List<Map<String, dynamic>>> fetchAllAccounts(String rawId) async {
    final url = Uri.parse('$_apiBase/api/xhh/switch?id=${Uri.encodeComponent(rawId)}');
    final resp = await http.get(url).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data.containsKey('error')) throw Exception(data['error']);
      final accounts = (data['accounts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return accounts;
    }
    throw Exception('小黑盒 API 返回 ${resp.statusCode}');
  }

  /// 触发小黑盒更新
  static Future<String> triggerUpdate(String accountId) async {
    final url = Uri.parse('$_apiBase/api/xhh/update?account_id=${Uri.encodeComponent(accountId)}');
    final resp = await http.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return data['result']?['desc'] ?? data['msg'] ?? '已触发';
    }
    throw Exception('更新失败');
  }
}
