/// 浏览器 Tab（第 6 个底部导航）— 包装浏览器页面在 tab 中使用
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bookmark_service.dart';

class BrowserTabPage extends StatefulWidget {
  const BrowserTabPage({super.key});

  /// 代理域名列表（App 启动时由 main.dart 初始化）
  static List<String> proxyDomains = [];


  @override
  State<BrowserTabPage> createState() => _BrowserTabPageState();
}

class _BrowserTabPageState extends State<BrowserTabPage> {
  bool _showBrowser = false;
  String _browserUrl = '';
  String _browserTitle = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (!url.contains('.') || url.contains(' ')) {
      url = 'https://www.bing.com/search?q=${Uri.encodeComponent(url.replaceFirst('https://', ''))}';
    }
    setState(() {
      _browserUrl = url;
      _browserTitle = '';
      _showBrowser = true;
    });
  }

  void _goBackToHome() {
    setState(() {
      _showBrowser = false;
      _browserUrl = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showBrowser && _browserUrl.isNotEmpty) {
      return _BrowserTabWebView(
        url: _browserUrl,
        title: _browserTitle,
        onTitleChanged: (t) => _browserTitle = t,
        onBack: _goBackToHome,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text('🌐 浏览',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text('输入网址打开任何页面',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '输入网址（如 example.com）',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[500], size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey[500], size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFA855F7), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: _openUrl,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 24),
            // 3DM Mod 快捷入口（小卡片）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _openUrl('https://mod.3dmgame.com/'),
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎮', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      const Text('3DM Mod',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────
// 内嵌浏览器 WebView（作为 tab 内容）
// ────────────────────────────────────────────────────

class _BrowserTabWebView extends StatefulWidget {
  final String url;
  final String title;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback onBack;

  const _BrowserTabWebView({
    required this.url,
    required this.title,
    this.onTitleChanged,
    required this.onBack,
  });

  @override
  State<_BrowserTabWebView> createState() => _BrowserTabWebViewState();
}

class _BrowserTabWebViewState extends State<_BrowserTabWebView> {
  late WebViewController _controller;
  final TextEditingController _urlCtrl = TextEditingController();
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isBookmarked = false;
  String _currentUrl = '';
  String _currentTitle = '';

  static const _apiBase = 'http://8.153.97.56';

  static bool _shouldProxy(String url) {
    final list = BrowserTabPage.proxyDomains.isNotEmpty
        ? BrowserTabPage.proxyDomains
        : <String>['filejin.ru', 'xn--wcv59z.com'];
    final lower = url.toLowerCase();
    return list.any((d) => lower.contains(d));
  }

  static String _proxyUrl(String url) {
    return '$_apiBase/api/proxy/page?url=${Uri.encodeComponent(url)}';
  }

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _urlCtrl.text = widget.url;
    _initWebView();
    _checkBookmark();
    // 从 SharedPreferences 同步加载代理域名（如果静态列表为空）
    if (BrowserTabPage.proxyDomains.isEmpty) {
      _loadProxyDomainsFromCache();
    }
  }

  /// 从 SharedPreferences 缓存加载代理域名
  void _loadProxyDomainsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('proxy_domains_cache');
      if (cached != null) {
        final list = json.decode(cached) as List;
        BrowserTabPage.proxyDomains = list.map((e) => e.toString()).toList();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _initWebView() async {
    final loadUrl =
        _shouldProxy(widget.url) ? _proxyUrl(widget.url) : widget.url;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        ' (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('steamcommunity.com') ||
                url.contains('store.steampowered.com')) {
              _launchExternal(url);
              return NavigationDecision.prevent;
            }
            if (url.contains('$_apiBase/api/proxy/')) {
              return NavigationDecision.navigate;
            }
            if (_shouldProxy(url) && !url.contains('$_apiBase')) {
              _controller.loadRequest(Uri.parse(_proxyUrl(url)));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            _controller.canGoBack().then((b) => _canGoBack = b);
            _controller.canGoForward().then((f) => _canGoForward = f);
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
                _urlCtrl.text = url;
              });
            }
            _checkBookmark();
            _updateTitle();
          },
        ),
      )
      ..loadRequest(Uri.parse(loadUrl));
  }

  Future<void> _checkBookmark() async {
    final bm = await BookmarkService.isBookmarked(_currentUrl);
    if (mounted) setState(() => _isBookmarked = bm);
  }

  Future<void> _updateTitle() async {
    try {
      final title = await _controller.getTitle();
      if (mounted && title != null && title.isNotEmpty) {
        setState(() => _currentTitle = title);
        widget.onTitleChanged?.call(title);
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await BookmarkService.remove(_currentUrl);
    } else {
      await BookmarkService.add(Bookmark(
        title: _currentTitle.isNotEmpty ? _currentTitle : _currentUrl,
        url: _currentUrl,
      ));
    }
    if (mounted) setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  Future<void> _reload() async {
    await _controller.reload();
  }

  void _loadUrl() {
    var url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final loadUrl = _shouldProxy(url) ? _proxyUrl(url) : url;
    _controller.loadRequest(Uri.parse(loadUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _urlCtrl,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _loadUrl(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock,
                  size: 14, color: Colors.grey[500]),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: Colors.grey),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.star : Icons.star_border,
              color: _isBookmarked ? Colors.amber : Colors.grey,
            ),
            tooltip: _isBookmarked ? '取消收藏' : '收藏此页',
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.grey[850],
              color: Colors.purple[300],
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              border:
                  Border(top: BorderSide(color: Colors.grey[850]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navBtn(Icons.arrow_back, _canGoBack, _goBack),
                _navBtn(Icons.arrow_forward, _canGoForward, _goForward),
                _navBtn(Icons.refresh, true, _reload),
                _navBtn(Icons.open_in_new, true,
                    () => _launchExternal(_currentUrl)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, bool enabled, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon,
          color: enabled ? Colors.white70 : Colors.grey[700]),
      onPressed: enabled ? onPressed : null,
    );
  }

  Future<void> _launchExternal(String url) async {
    if (url.contains('steamcommunity.com') ||
        url.contains('store.steampowered.com')) {
      final steamUrl = url.replaceFirst('https://', 'steam://openurl/');
      final steamUri = Uri.tryParse(steamUrl);
      if (steamUri != null && await canLaunchUrl(steamUri)) {
        await launchUrl(steamUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
