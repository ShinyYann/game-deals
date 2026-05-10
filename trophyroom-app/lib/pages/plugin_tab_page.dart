/// 插件 Tab — 插件列表 + 内嵌 WebView
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// 插件条目
class _PluginEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String url;

  const _PluginEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.url,
  });
}

/// 所有插件列表
const _plugins = <_PluginEntry>[
  _PluginEntry(
    title: '燕雲十六聲',
    subtitle: '官方數據小工具',
    icon: Icons.auto_awesome,
    iconColor: Color(0xFFF5C444),
    url: 'https://www.wherewindsmeetgame.com/m/2025h5sjgj/tw/',
  ),
];

class PluginTabPage extends StatefulWidget {
  const PluginTabPage({super.key});

  @override
  State<PluginTabPage> createState() => _PluginTabPageState();
}

class _PluginTabPageState extends State<PluginTabPage> {
  _PluginEntry? _activePlugin;

  void _openPlugin(_PluginEntry p) {
    setState(() => _activePlugin = p);
  }

  void _backToHome() {
    setState(() => _activePlugin = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_activePlugin != null) {
      return _PluginWebView(
        plugin: _activePlugin!,
        onBack: _backToHome,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.extension, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('插件',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(height: 4),
                            Text('实用小工具合集',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 插件卡片列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = _plugins[index];
                    return _PluginCard(plugin: p, onTap: () => _openPlugin(p));
                  },
                  childCount: _plugins.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个插件卡片
class _PluginCard extends StatelessWidget {
  final _PluginEntry plugin;
  final VoidCallback onTap;

  const _PluginCard({required this.plugin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF16213E),
                const Color(0xFF1A1A2E).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: plugin.iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(plugin.icon, color: plugin.iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plugin.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(plugin.subtitle,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 插件内嵌 WebView
class _PluginWebView extends StatefulWidget {
  final _PluginEntry plugin;
  final VoidCallback onBack;

  const _PluginWebView({required this.plugin, required this.onBack});

  @override
  State<_PluginWebView> createState() => _PluginWebViewState();
}

class _PluginWebViewState extends State<_PluginWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  static const _blockedPatterns = [
    'a.app.qq.com',
    'appdownload',
    'heybox://',
    'xiaoheihe://',
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        ' (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (_blockedPatterns.any((p) => url.contains(p))) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.plugin.url));
  }

  Future<void> _openInBrowser() async {
    try {
      final currentUrl = await _controller.currentUrl() ?? widget.plugin.url;
      final uri = Uri.tryParse(currentUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
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
        title: Text(widget.plugin.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white70),
            tooltip: '在浏览器打开',
            onPressed: _openInBrowser,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Color(0xFF1A1A2E),
                color: Color(0xFF7C4DFF),
              ),
            ),
        ],
      ),
    );
  }
}
