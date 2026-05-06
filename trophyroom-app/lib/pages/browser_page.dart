import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bookmark_service.dart';

class BrowserPage extends StatefulWidget {
  final String initialUrl;
  final String? initialTitle;

  const BrowserPage({
    super.key,
    required this.initialUrl,
    this.initialTitle,
  });

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late WebViewController _controller;
  String _currentUrl = '';
  String _currentTitle = '';
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isBookmarked = false;
  double _scrollProgress = 0;

  final TextEditingController _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.initialTitle ?? '';
    _currentUrl = widget.initialUrl;
    _urlCtrl.text = widget.initialUrl;
    _initWebView();
    _checkBookmark();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _saveScrollPosition();
    super.dispose();
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
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            _controller.canGoBack().then((b) => _canGoBack = b);
            _controller.canGoForward().then((f) => _canGoForward = f);
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            }
            _checkBookmark();
            _updateTitle();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
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

  Future<void> _saveScrollPosition() async {
    // Only save for bookmarked pages
    if (!_isBookmarked) return;
    final progress = _scrollProgress;
    if (progress > 0) {
      await BookmarkService.saveScrollPosition(_currentUrl, progress);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () {
            _urlCtrl.text = _currentUrl;
            _urlCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _currentUrl.length);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey),
                  )
                else
                  Icon(Icons.lock, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // ★ Bookmark button
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
          // Progress bar
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.grey[850],
              color: Colors.purple[300],
            ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          // Navigation bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              border: Border(top: BorderSide(color: Colors.grey[850]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navBtn(Icons.arrow_back, _canGoBack, _goBack),
                _navBtn(Icons.arrow_forward, _canGoForward, _goForward),
                _navBtn(Icons.refresh, true, _reload),
                _navBtn(Icons.open_in_new, true, () => _launchExternal(_currentUrl)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, bool enabled, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: enabled ? Colors.white70 : Colors.grey[700]),
      onPressed: enabled ? onPressed : null,
    );
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
