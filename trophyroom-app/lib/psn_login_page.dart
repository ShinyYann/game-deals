import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 全 App 内 PSN 登录页
/// 流程：
/// 1. WebView 设置真实 Chrome UA 绕过 Akamai
/// 2. 加载 playstation.com，用户点击 Sign In
/// 3. 用户输入 PSN 邮箱密码登录
/// 4. 登录后主动跳转 ssocookie 提取 NPSSO
/// 5. 自动返回
class PSNLoginPage extends StatefulWidget {
  const PSNLoginPage({super.key});

  @override
  State<PSNLoginPage> createState() => _PSNLoginPageState();
}

class _PSNLoginPageState extends State<PSNLoginPage> {
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;
  String _status = '初始化...';
  String? _extractedNpsso;
  bool _done = false;
  bool _navigatedToSsoCookie = false;

  static const String _npssoUrl = 'https://ca.account.sony.com/api/v1/ssocookie';
  static const String _startUrl = 'https://www.playstation.com/';
  static const String _mobileChromeUA =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.6367.83 Mobile Safari/537.36';

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
          setState(() {
            _loading = true;
            _status = '加载中…';
          });
        },
        onPageFinished: (url) {
          if (!mounted || _done) return;
          setState(() {
            _loading = false;
            _status = url.contains('ssocookie') ? '提取 NPSSO…' : '';
          });

          // 到达 ssocookie 页面 → 提取 NPSSO
          if (url.contains('ssocookie')) {
            _navigatedToSsoCookie = true;
            _tryExtractNpsso();
          }
        },
        onNavigationRequest: (request) {
          // 检测是否被重定向到 ssocookie
          if (!_done && request.url.contains('ssocookie')) {
            _navigatedToSsoCookie = true;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..addJavaScriptChannel('NpssoExtractor', onMessageReceived: (msg) {
        if (_done) return;
        _handlePageContent(msg.message);
      });

    // 设置真实 Chrome UA
    _setUserAgent().then((_) {
      // 加载 PlayStation 首页，用户自行登录
      if (mounted) {
        setState(() => _status = '请登录你的 PSN 账号');
        _controller.loadRequest(Uri.parse(_startUrl));
      }
    });
  }

  Future<void> _setUserAgent() async {
    if (Platform.isAndroid) {
      try {
        await _controller.setUserAgent(_mobileChromeUA);
      } catch (_) {
        // 某些旧版 webview_flutter 不支持 setUserAgent
      }
    }
  }

  /// 前往 ssocookie 页面提取 NPSSO
  Future<void> _goToNpsso() async {
    if (_done) return;
    setState(() => _status = '正在获取 NPSSO…');
    await _controller.loadRequest(Uri.parse(_npssoUrl));
  }

  void _tryExtractNpsso() {
    if (_done) return;
    _controller.runJavaScript('''
      try {
        var text = document.body.innerText.trim();
        if (text && text.length > 0) {
          NpssoExtractor.postMessage(text);
        } else {
          NpssoExtractor.postMessage('EMPTY');
        }
      } catch(e) {
        NpssoExtractor.postMessage('ERR: ' + e.message);
      }
    ''');
  }

  void _handlePageContent(String content) {
    if (_done || !mounted) return;

    if (content.startsWith('ERR:') || content == 'EMPTY') {
      return; // 页面还没加载完
    }

    try {
      // 去掉可能的干扰字符，找 JSON
      final trimmed = content.trim();
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final jsonStr = trimmed.substring(start, end + 1);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;

        if (data.containsKey('npsso')) {
          final npsso = data['npsso'].toString();
          if (npsso.isNotEmpty && npsso != 'null') {
            _onNpssoFound(npsso);
            return;
          }
        }
        if (data.containsKey('error')) {
          final err = data['error'].toString();
          if (err == 'invalid_grant') {
            // 需要登录 → 回到首页
            setState(() => _status = '请先登录 PSN 账号');
            return;
          }
        }
      }
    } catch (e) {
      // 不是 JSON，说明还没 SSO Cookie
    }
    // 页面内容不是预期的 NPSSO JSON
    setState(() => _status = '等待登录完成...');
  }

  void _onNpssoFound(String npsso) {
    if (_done || !mounted) return;
    _done = true;
    setState(() {
      _extractedNpsso = npsso;
      _status = '🎉 NPSSO 已获取！';
    });
    // 自动返回
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context, npsso);
    });
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
          onPressed: () => Navigator.pop(context, _extractedNpsso),
        ),
        actions: [
          if (_extractedNpsso != null)
            TextButton(
              onPressed: () => Navigator.pop(context, _extractedNpsso),
              child: const Text('确认 ✓',
                  style: TextStyle(color: Colors.amber, fontSize: 16)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          _buildStatusBar(),
          if (_loading && _progress > 0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
            ),

          // 操作提示区
          if (!_done)
            _buildHintBar(),

          // 提取成功提示
          if (_extractedNpsso != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('NPSSO 已获取，即将返回',
                      style: TextStyle(color: Colors.green[300], fontSize: 14)),
                ],
              ),
            ),

          // WebView 主体
          Expanded(child: WebViewWidget(controller: _controller)),

          // 底部按钮栏
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          if (_loading)
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            )
          else if (_extractedNpsso != null)
            const Icon(Icons.check_circle, color: Colors.green, size: 18)
          else
            Icon(Icons.login_rounded, color: Colors.amber[400], size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _extractedNpsso != null
                  ? '✅ 登录成功！'
                  : _status,
              style: TextStyle(
                color: _extractedNpsso != null
                    ? Colors.green[300]
                    : Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[300], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '在下方网页中点击 Sign In 登录 PSN。登录后，点击底部"获取 NPSSO"按钮。',
              style: TextStyle(color: Colors.blue[200], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 返回首页
          TextButton.icon(
            icon: const Icon(Icons.home, size: 18),
            label: const Text('首页'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            onPressed: () => _controller.loadRequest(Uri.parse(_startUrl)),
          ),
          // 刷新
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('刷新'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            onPressed: () => _controller.reload(),
          ),
          // 获取NPSSO（登录后点这个）
          TextButton.icon(
            icon: Icon(Icons.vpn_key, size: 18,
                color: _navigatedToSsoCookie ? Colors.amber : Colors.grey[500]),
            label: Text('获取 NPSSO',
                style: TextStyle(
                  color: _navigatedToSsoCookie ? Colors.amber : Colors.grey[500],
                )),
            onPressed: _goToNpsso,
          ),
          // 用外部浏览器
          TextButton.icon(
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text('浏览器'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            onPressed: () async {
              final url = await _controller.currentUrl();
              if (url != null && mounted) {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
