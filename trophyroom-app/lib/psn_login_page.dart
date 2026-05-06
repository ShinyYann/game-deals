import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 全 App 内 PSN 登录页
/// 在 WebView 中打开 Sony 登录，用户输完账号密码后，
/// 自动提取 NPSSO 值并返回。
class PSNLoginPage extends StatefulWidget {
  const PSNLoginPage({super.key});

  @override
  State<PSNLoginPage> createState() => _PSNLoginPageState();
}

class _PSNLoginPageState extends State<PSNLoginPage> {
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;
  String _status = '正在打开 PSN 登录页面...';
  String? _extractedNpsso;
  bool _done = false;

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
          if (!mounted) return;
          setState(() => _progress = p / 100.0);
        },
        onPageStarted: (url) {
          if (!mounted || _done) return;
          setState(() {
            _loading = true;
            _status = '加载中...';
          });
        },
        onPageFinished: (url) {
          if (!mounted || _done) return;
          setState(() => _loading = false);
          if (url.contains('ssocookie') || url.contains('npsso')) {
            _tryExtractNpsso();
          } else {
            setState(() => _status = '请使用你的 PSN 账号登录');
          }
        },
        onNavigationRequest: (request) {
          if (!_done && (request.url.contains('ssocookie') || request.url.contains('npsso'))) {
            Future.delayed(const Duration(milliseconds: 500), _tryExtractNpsso);
          }
          return NavigationDecision.navigate;
        },
      ))
      ..addJavaScriptChannel('NpssoExtractor', onMessageReceived: (msg) {
        if (_done) return;
        _handlePageContent(msg.message);
      })
      ..loadRequest(Uri.parse('https://ca.account.sony.com/api/v1/ssocookie'));
  }

  void _tryExtractNpsso() {
    if (_done) return;
    setState(() => _status = '正在提取 NPSSO...');
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
    debugPrint('NPSSO Page: $content');

    if (content.startsWith('ERR:') || content == 'EMPTY') {
      setState(() => _status = '请使用你的 PSN 账号登录');
      return;
    }

    try {
      final trimmed = content.trim();
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final jsonStr = trimmed.substring(start, end + 1);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (data.containsKey('npsso')) {
          final npsso = data['npsso'].toString();
          if (npsso.isNotEmpty) {
            _onNpssoFound(npsso);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('NPSSO parse failed: $e');
    }

    setState(() => _status = '等待登录完成...');
  }

  void _onNpssoFound(String npsso) {
    if (_done || !mounted) return;
    _done = true;
    setState(() {
      _extractedNpsso = npsso;
      _status = '🎉 登录成功！';
    });
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
                    _extractedNpsso != null ? '✅ NPSSO 已获取！' : _status,
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
          ),
          if (_loading && _progress > 0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(Colors.amber[700]),
            ),
          if (_extractedNpsso == null && !_loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                '用你的 PSN 邮箱和密码登录，成功后自动提取',
                style: TextStyle(color: Colors.blue[200], fontSize: 12),
              ),
            ),
          if (_extractedNpsso != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('NPSSO 自动获取成功，即将返回',
                      style: TextStyle(color: Colors.green[300], fontSize: 14)),
                ],
              ),
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),

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
                  onPressed: () => _controller.reload(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('浏览器打开'),
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
          ),
        ],
      ),
    );
  }
}
