/// WebView Cookie 隔离 — 切换账号自动清空，防止串号
/// 注：webview_flutter 4.2.0 不支持读取 cookies（getCookies），仅能清空/写入
/// 因此策略为：切换账号时清空所有 cookies，每个账号独立起始
import 'package:webview_flutter/webview_flutter.dart';

class CookieIsolation {
  /// 清除所有 WebView cookies（登出/切换账号时调用）
  static Future<void> clearAll() async {
    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {}
  }

  /// 切换账号时清空 cookies
  static Future<void> onUserSwitch() async {
    await clearAll();
  }
}
