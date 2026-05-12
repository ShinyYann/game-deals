/// 🧰 工具箱 Tab — 收藏夹 + 宝可梦图鉴 + 插件小工具
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bookmark_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'browser_page.dart';
import 'pokemon/pokemon_home_page.dart';
import 'pokopia/pokopia_home_page.dart';

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

class ToolboxPage extends StatefulWidget {
  const ToolboxPage({super.key});

  @override
  State<ToolboxPage> createState() => _ToolboxPageState();
}

class _ToolboxPageState extends State<ToolboxPage> {
  bool _bookmarksExpanded = false;
  _PluginEntry? _activePlugin;
  /// WebView 控制器持久化：key=URL，value=WebViewController
  final Map<String, WebViewController> _webControllers = {};

  void _openPlugin(_PluginEntry p) {
    setState(() => _activePlugin = p);
  }

  void _backToHome() {
    setState(() => _activePlugin = null);
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

  @override
  Widget build(BuildContext context) {
    // 如果正在使用 WebView，显示全屏 WebView
    if (_activePlugin != null) {
      return _PluginWebView(
        plugin: _activePlugin!,
        onBack: _backToHome,
        controller: _webControllers.putIfAbsent(
          _activePlugin!.url,
          () => _buildController(_activePlugin!),
        ),
      );
    }

    // 正常工具箱首页
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        // ── 标题行 ──
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
              child: const Icon(Icons.build_circle, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧰 工具箱',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('攻略收藏 · 图鉴 · 实用小工具',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── ⭐ 收藏夹（可展开/收起） ──
        FutureBuilder<List<Bookmark>>(
          future: BookmarkService.load(),
          builder: (context, snapshot) {
            final bookmarks = snapshot.data ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(children: [
                // 标题栏（可点击）
                InkWell(
                  onTap: () => setState(() => _bookmarksExpanded = !_bookmarksExpanded),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text('⭐ 收藏夹',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[200])),
                        const Spacer(),
                        Text('${bookmarks.length} 个收藏',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(width: 6),
                        Icon(_bookmarksExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                            color: Colors.grey[500], size: 20),
                      ],
                    ),
                  ),
                ),
                // 展开内容
                if (_bookmarksExpanded) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.15)),
                    ),
                    child: bookmarks.isEmpty
                        ? Text('在奖杯心得点链接 → 浏览器右上角 ⭐ 收藏',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                        : Column(children: bookmarks.map((bm) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BrowserPage(
                                    initialUrl: bm.url,
                                    initialTitle: bm.title,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text('删除收藏？',
                                      style: TextStyle(color: Colors.white)),
                                  content: Text(bm.title,
                                      style: TextStyle(color: Colors.grey[400])),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        BookmarkService.remove(bm.url);
                                        Navigator.pop(ctx);
                                        setState(() {});
                                      },
                                      child: const Text('删除',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[800]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.bookmark, color: Colors.amber[700], size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(bm.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 2),
                                        Text(bm.url,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 12),
                                ],
                              ),
                            ),
                          ),
                        )).toList()),
                  ),
                ],
              ]),
            );
          },
        ),

        // ── 宝可梦图鉴 ──
        _toolCard(
          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
          title: '宝可梦',
          subtitle: '图鉴 / 队伍 / 闪符 / 配队 / 闪值排行',
          color: const Color(0xFFE53935),
          icon: Icons.catching_pokemon,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PokemonHomePage()),
            );
          },
        ),
        const SizedBox(height: 14),

        // ── Pokopia 宝可梦绘 ──
        _toolCard(
          imageUrl: 'https://www.pocoapokemon.jp/assets/img/favicon/android-icon-192x192.png',
          title: 'Pokopia 宝可梦绘',
          subtitle: '活动 · 情报 · 305 只宝可梦 · 栖息地 · 攻略 · 角色 · 城镇',
          color: const Color(0xFF7C4DFF),
          icon: Icons.auto_awesome,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PokopiaHomePage()),
            );
          },
        ),
        const SizedBox(height: 14),

        // ── 插件小工具 ──
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.extension, color: Color(0xFF7C4DFF), size: 18),
              const SizedBox(width: 6),
              Text('🔌 插件工具',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[200])),
            ],
          ),
        ),
        ..._plugins.map((p) => _pluginCard(p)),
      ],
    );
  }

  /// 工具箱卡片（宝可梦等）
  Widget _toolCard({
    String? imageUrl,
    required String title,
    required String subtitle,
    required Color color,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title — 制作中'), duration: const Duration(seconds: 2)),
        );
      },
      child: Container(
        padding: AppSpacing.padLg,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, width: 36, height: 36,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon ?? Icons.videogame_asset, color: Colors.grey[600], size: 30))
            else
              Icon(icon ?? Icons.videogame_asset, color: color, size: 32),
            AppSpacing.wLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  AppSpacing.hXs,
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  /// 插件卡片
  Widget _pluginCard(_PluginEntry plugin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openPlugin(plugin);
        },
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(plugin.icon, color: plugin.iconColor, size: 24),
                ),
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
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 插件内嵌 WebView
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
