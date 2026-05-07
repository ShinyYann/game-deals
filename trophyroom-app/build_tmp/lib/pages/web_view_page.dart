import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String? restorePosition; // saved scrollY to restore

  const WebViewPage({super.key, required this.url, this.restorePosition});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _pageTitle = '加载中...';
  bool _isBookmarked = false;
  String? _scrollY;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _checkBookmark();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      )
      ..setBackgroundColor(const Color(0xFF0F0F1A))
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            // Block app-scheme redirects (B站 etc.)
            if (url.startsWith('bilibili://') ||
                url.startsWith('b23://') ||
                url.startsWith('intent://') ||
                url.startsWith('market://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            // Get page title
            final title = await _controller.getTitle();
            if (title != null && title.isNotEmpty) {
              setState(() => _pageTitle = title);
            }
            // Restore scroll position
            if (widget.restorePosition != null && widget.restorePosition!.isNotEmpty) {
              _controller.runJavaScript(
                'window.scrollTo(0, ${widget.restorePosition});',
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _checkBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_bookmarks') ?? '[]';
    final list = jsonDecode(raw) as List;
    setState(() {
      _isBookmarked = list.any((b) => b['url'] == widget.url);
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_bookmarks') ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    if (_isBookmarked) {
      list.removeWhere((b) => b['url'] == widget.url);
    } else {
      // Save current scroll position
      try {
        _scrollY = await _controller.runJavaScriptReturningResult('window.pageYOffset').then(
          (v) => v.toString().replaceAll('"', ''),
        );
      } catch (_) {
        _scrollY = '0';
      }
      list.add({
        'url': widget.url,
        'title': _pageTitle,
        'scrollY': int.tryParse(_scrollY ?? '0') ?? 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    await prefs.setString('saved_bookmarks', jsonEncode(list));
    setState(() => _isBookmarked = !_isBookmarked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBookmarked ? '已收藏 ✅' : '已取消收藏'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveScrollPosition() async {
    if (_isBookmarked) {
      try {
        _scrollY = await _controller.runJavaScriptReturningResult('window.pageYOffset').then(
          (v) => v.toString().replaceAll('"', ''),
        );
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('saved_bookmarks') ?? '[]';
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        for (int i = 0; i < list.length; i++) {
          if (list[i]['url'] == widget.url) {
            list[i]['scrollY'] = int.tryParse(_scrollY ?? '0') ?? 0;
            list[i]['title'] = _pageTitle;
            break;
          }
        }
        await prefs.setString('saved_bookmarks', jsonEncode(list));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _saveScrollPosition();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(
            _pageTitle,
            style: const TextStyle(fontSize: 15, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan)),
              ),
            IconButton(
              icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? Colors.amber[300] : Colors.grey[400]),
              onPressed: _toggleBookmark,
              tooltip: _isBookmarked ? '取消收藏' : '收藏此页',
            ),
          ],
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
