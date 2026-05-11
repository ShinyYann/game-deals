/// ⚠️ 已废弃 — 插件内容已合并至 `toolbox_page.dart`
/// 此文件保留仅作参考，不再被任何文件导入。
///
/// 插件 Tab — 插件列表 + 内嵌 WebView（持久化登录状态）
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
  /// WebView 控制器持久化：key=URL，value=WebViewController
  /// 退出插件页不销毁，再次进入复用，保持登录状态
  final Map<String, WebViewController> _controllers = {};

  void _openPlugin(_PluginEntry p) {
    setState(() => _activePlugin = p);
  }

  void _backToHome() {
    setState(() => _activePlugin = null);
  }

  @override
  void dispose() {
    // 只释放页面，不释放 _controllers（保持登录状态）
    // 如果整个 PluginTabPage 被销毁（app 进程被回收），登录状态自然丢失
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activePlugin != null) {
      return _PluginWebView(
        plugin: _activePlugin!,
        onBack: _backToHome,
        controller: _controllers.putIfAbsent(
          _activePlugin!.url,
          () => _buildController(_activePlugin!),
        ),
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

  WebViewController _buildController(_PluginEntry plugin) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        ' (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            const blocked = [
              'a.app.qq.com',
              'appdownload',
              'heybox://',
              'xiaoheihe://',
            ];
            if (blocked.any((p) => url.contains(p))) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(plugin.url));
    return controller;
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
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                SizedBox(width: 48, height: 48,
                  child: Center(child: Icon(Icons.auto_awesome, color: Color(0xFFF5C444), size: 24))),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('燕雲十六聲',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 3),
                      Text('官方數據小工具',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 插件内嵌 WebView — 使用从父级传入的持久化控制器
class _PluginWebView extends StatelessWidget {
  final _PluginEntry plugin;
  final VoidCallback onBack;
  final WebViewController controller;

  const _PluginWebView({
    required this.plugin,
    required this.onBack,
    required this.controller,
  });

  Future<void> _openInBrowser(BuildContext context) async {
    try {
      final currentUrl = await controller.currentUrl() ?? plugin.url;
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
          onPressed: onBack,
        ),
        title: Text(plugin.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white70),
            tooltip: '在浏览器打开',
            onPressed: () => _openInBrowser(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
