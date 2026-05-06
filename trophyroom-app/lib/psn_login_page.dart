import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// App 内 PSN 一键登录
///
/// 流程：
/// 1. 打开 Sony OAuth 授权页（自带登录表单）
/// 2. 用户输入 PSN 邮箱密码登录
/// 3. Sony 重定向到 com.scee.psxandroid.scecompcall://redirect?code=xxx
/// 4. WebView 拦截该重定向，提取 code
/// 5. 发到服务器 /api/psn_oauth_exchange 换 token
/// 6. 服务器验证成功，保存
class PSNLoginPage extends StatefulWidget {
  const PSNLoginPage({super.key});

  @override
  State<PSNLoginPage> createState() => _PSNLoginPageState();
}

class _PSNLoginPageState extends State<PSNLoginPage> {
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;
  String _status = '初始化…';
  String? _result;
  bool _done = false;

  // Sony OAuth
  static const String _clientId = '09515159-7237-4370-9b40-3806e67c0891';
  static const String _redirectUri = 'com.scee.psxandroid.scecompcall://redirect';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (!mounted || _done) return;
          setState(() => _progress = p / 100.0);
        },
        onPageStarted: (url) {
          if (!mounted || _done) return;
          setState(() => _loading = true);
        },
        onPageFinished: (url) {
          if (!mounted || _done) return;
          setState(() {
            _loading = false;
            _status = '';
          });
        },
        onNavigationRequest: (request) {
          final url = request.url;
          // 拦截 Sony 的 OAuth 回调（自定义 scheme 重定向）
          if (url.startsWith(_redirectUri) || url.contains('scecompcall')) {
            _handleOAuthRedirect(url);
            return NavigationDecision.prevent;
          }
          // 也拦截任何包含 code= 的回调
          if (url.contains('code=') && url.contains('scecompcall')) {
            _handleOAuthRedirect(url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onWebResourceError: (error) {
          // 如果是因为自定义 scheme 导致的错误，忽略（我们已拦截）
          if (!mounted || _done) return;
        },
      ));

    // 设置真实 Chrome UA
    _setUserAgent().then((_) {
      _loadAuthorizeUrl();
    });
  }

  Future<void> _setUserAgent() async {
    try {
      await _controller.setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.6367.83 Mobile Safari/537.36',
      );
    } catch (_) {}
  }

  void _loadAuthorizeUrl() {
    if (mounted) {
      setState(() => _status = '正在打开 PSN 登录页面…');
    }
    final params = {
      'access_type': 'offline',
      'client_id': _clientId,
      'response_type': 'code',
      'scope': 'psn:mobile.v2.core psn:clientapp',
      'request_locale': 'zh_Hans',
      'redirect_uri': _redirectUri,
    };
    final qs = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final url = 'https://ca.account.sony.com/api/authz/v3/oauth/authorize?$qs';
    _controller.loadRequest(Uri.parse(url));
  }

  /// 处理 Sony OAuth 回调
  void _handleOAuthRedirect(String url) {
    if (_done) return;
    _done = true;

    setState(() {
      _loading = true;
      _status = '正在验证登录…';
    });

    // 从 URL 中提取 code
    final uri = Uri.tryParse(url);
    final code = uri?.queryParameters['code'] ?? '';
    final verifier = uri?.queryParameters['code_verifier'] ?? '';

    if (code.isEmpty) {
      setState(() {
        _loading = false;
        _status = '❌ 获取授权码失败';
      });
      return;
    }

    _exchangeCode(code, verifier);
  }

  /// 用授权码换 token
  Future<void> _exchangeCode(String code, String verifier) async {
    try {
      var verifierParam = '';
      if (verifier.isNotEmpty) verifierParam = '&verifier=$verifier';

      final uri = Uri.parse(
          'http://8.153.97.56/api/psn_oauth_exchange?code=$code$verifierParam');

      setState(() => _status = '正在验证 PSN 身份…');

      final resp = await http.get(uri).timeout(const Duration(seconds: 30));
      final data = jsonDecode(resp.body);

      if (data['valid'] == true) {
        final onlineId = data['online_id']?.toString() ?? '';
        setState(() {
          _result = onlineId;
          _status = '✅ 登录成功！PSN 账号：$onlineId';
        });

        // 自动返回
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, onlineId);
      } else {
        setState(() {
          _loading = false;
          _status = '❌ 验证失败：${data['error'] ?? '未知错误'}';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _status = '❌ 网络错误：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('PSN 登录',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context, _result),
        ),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                if (_loading && _result == null)
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                  )
                else if (_result != null)
                  const Icon(Icons.check_circle, color: Colors.green, size: 18)
                else
                  Icon(Icons.login_rounded, color: Colors.amber[400], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _result != null ? '✅ 登录成功' : _status,
                    style: TextStyle(
                      color: _result != null ? Colors.green[300] : Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading && _progress > 0 && _result == null)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
            ),

          // Hint
          if (_result == null && !_loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                '请在下方用你的 PSN 邮箱和密码登录',
                style: TextStyle(color: Colors.blue[200], fontSize: 12),
              ),
            ),

          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green.withValues(alpha: 0.08),
              child: Text('PSN: $_result  已登录',
                  style: TextStyle(color: Colors.green[300], fontSize: 14)),
            ),

          // WebView
          Expanded(child: WebViewWidget(controller: _controller)),

          // Bottom bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('刷新'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                  onPressed: _loadAuthorizeUrl,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('浏览器登录'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                  onPressed: () async {
                    final params = {
                      'access_type': 'offline',
                      'client_id': _clientId,
                      'response_type': 'code',
                      'scope': 'psn:mobile.v2.core psn:clientapp',
                      'request_locale': 'zh_Hans',
                      'redirect_uri': _redirectUri,
                    };
                    final qs = params.entries
                        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
                        .join('&');
                    final url = 'https://ca.account.sony.com/api/authz/v3/oauth/authorize?$qs';
                    final uri = Uri.tryParse(url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
