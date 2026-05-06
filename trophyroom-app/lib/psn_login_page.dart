import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// App 内 PSN 一键登录（WebView + NPSSO 提取）
///
/// 流程：
/// 1. 打开 Sony OAuth 授权页（自带登录表单）
/// 2. 用户输入 PSN 邮箱密码登录
/// 3. Sony 尝试重定向到 com.scee.psxandroid.scecompcall://redirect?code=xxx
///    WebView 无法处理自定义 scheme → 报错
/// 4. 但 NPSSO cookie 已设置！自动跳转到 ssocookie 读取
/// 5. 提取 NPSSO → 发到服务器验证 → 返回 online_id
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
  bool _triedSsoCookie = false;

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
          
          // 检测 Sony 自定义 scheme 重定向
          if (url.startsWith(_redirectUri) || url.contains('scecompcall:')) {
            _handleRedirect(url);
          }
        },
        onPageFinished: (url) {
          if (!mounted || _done) return;
          setState(() => _loading = false);
          // 页面加载完成后尝试提取 NPSSO
          _tryExtractNpssoFromPage();
        },
        onNavigationRequest: (request) {
          final url = request.url;
          // 拦截 Sony OAuth 自定义 scheme 回调
          if (url.startsWith(_redirectUri) || url.contains('scecompcall:')) {
            _handleRedirect(url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onWebResourceError: (error) {
          if (!mounted || _done) return;
          // Sony 自定义 scheme 会导致错误 → 走 ssocookie 提取 NPSSO
          if (!_triedSsoCookie) {
            _triedSsoCookie = true;
            // 给 Sony 一点时间设置 cookie
            Future.delayed(const Duration(milliseconds: 500), () {
              _navigateToSsoCookie();
            });
          }
        },
      ));

    // 设置真实 Chrome UA 绕过 Akamai
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
    debugPrint('[PSNLogin] Loading: $url');
    _controller.loadRequest(Uri.parse(url));
  }

  /// 检测到 Sony 自定义 scheme 重定向
  void _handleRedirect(String url) {
    if (_done) return;
    debugPrint('[PSNLogin] Redirect intercepted: $url');
    
    final uri = Uri.tryParse(url);
    final code = uri?.queryParameters['code'] ?? '';
    if (code.isNotEmpty) {
      // 有授权码，走 OAuth 交换
      _done = true;
      setState(() {
        _loading = true;
        _status = '正在验证登录…';
      });
      _exchangeCode(code, '');
      return;
    }
    
    // 没有 code，可能是其他类型回调 → 走 ssocookie
    _triedSsoCookie = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      _navigateToSsoCookie();
    });
  }

  /// 跳转到 ssocookie 提取 NPSSO
  Future<void> _navigateToSsoCookie() async {
    if (_done || !mounted) return;
    debugPrint('[PSNLogin] Navigating to ssocookie...');
    setState(() => _status = '正在提取登录凭证…');
    await _controller.loadRequest(
      Uri.parse('https://ca.account.sony.com/api/v1/ssocookie'),
    );
  }

  /// 尝试通过 JS 提取 NPSSO
  Future<void> _tryExtractNpssoFromPage() async {
    if (_done || !mounted) return;
    try {
      final js = """
(function() {
  try {
    var text = document.body ? document.body.innerText || '' : '';
    var match = text.match(/"npsso"\\s*:\\s*"([^"]+)"/);
    if (match && match[1]) {
      return match[1];
    }
    // 尝试 JSON parse
    var data = JSON.parse(text);
    if (data && data.npsso) {
      return data.npsso;
    }
  } catch(e) {}
  return '';
})();
""";
      final npsso = await _controller.runJavaScriptReturningResult(js);
      final npssoStr = npsso.toString().replaceAll('"', '').trim();
      if (npssoStr.isNotEmpty && npssoStr.length > 10 && !_done && mounted) {
        _done = true;
        setState(() {
          _loading = true;
          _status = '正在验证 NPSSO…';
        });
        await _verifyNpsso(npssoStr);
      }
    } catch (e) {
      debugPrint('[PSNLogin] JS extraction error: $e');
    }
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
        await Future.delayed(const Duration(milliseconds: 800));
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

  /// 用 NPSSO 验证登录
  Future<void> _verifyNpsso(String npsso) async {
    try {
      final uri = Uri.parse(
          'http://8.153.97.56/api/psn_set_npsso?uid=npssologin&npsso=$npsso');
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(resp.body);

      if (data['ok'] == true) {
        final onlineId = data['online_id']?.toString() ?? '';
        setState(() {
          _result = onlineId;
          _status = '✅ 登录成功！PSN 账号：$onlineId';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, onlineId);
      } else {
        setState(() {
          _loading = false;
          _status = '❌ 验证失败：${data['error'] ?? 'NPSSO 无效'}';
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

          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green.withValues(alpha: 0.08),
              child: Text('PSN: $_result',
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
                  onPressed: () {
                    _triedSsoCookie = false;
                    _loadAuthorizeUrl();
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.vpn_key, size: 18),
                  label: const Text('提取 NPSSO'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                  onPressed: _navigateToSsoCookie,
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
