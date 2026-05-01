import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/trophy_page.dart';
import 'pages/deals_page.dart';
import 'pages/guide_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'models/app_theme.dart';

/// Save crash log locally
Future<void> _reportCrash(String type, dynamic error, StackTrace? stack) async {
  final log = '[${DateTime.now().toIso8601String()}][$type] $error\n$stack';
  try {
    var dir = Directory('/storage/emulated/0/Android/data/com.yann.trophyroom/files');
    if (!await dir.exists()) {
      dir = Directory('/data/data/com.yann.trophyroom/files');
    }
    if (await dir.exists()) {
      await File('${dir.path}/crash.log').writeAsString('$log\n${"=" * 40}\n', mode: FileMode.append);
    }
  } catch (_) {}
}

/// Test real network access to a known server
Future<bool> _checkNetworkAccess() async {
  final testUrls = [
    'https://www.baidu.com',
    'https://httpbin.org/ip',
    'https://gitee.com/yann8888/game-deals/raw/main/README.md',
  ];
  for (final url in testUrls) {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..badCertificateCallback = ((cert, host, port) => true);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'TrophyRoom/1.0');
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        client.close();
        return true;
      }
      client.close();
    } catch (_) {}
  }
  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportCrash('FLUTTER', details.exception, details.stack);
  };

  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _reportCrash('DISPATCH', error, stack);
    return true;
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A12),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final hasNetwork = await _checkNetworkAccess();

  runApp(TrophyRoomApp(hasNetwork: hasNetwork));
}

class TrophyRoomApp extends StatefulWidget {
  final bool hasNetwork;
  const TrophyRoomApp({super.key, required this.hasNetwork});

  @override
  State<TrophyRoomApp> createState() => _TrophyRoomAppState();
}

class _TrophyRoomAppState extends State<TrophyRoomApp> {
  int _currentIndex = 0;
  bool _showSplash = true;
  late bool _networkOk;

  @override
  void initState() {
    super.initState();
    _networkOk = widget.hasNetwork;
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  void _showNetworkGuide() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('网络访问异常', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TrophyRoom 无法访问网络，可能是以下原因：',
              style: TextStyle(color: Color(0xFFaaa), fontSize: 14),
            ),
            const SizedBox(height: 16),
            _guideStep('1', '打开「手机管家」或「安全中心」'),
            _guideStep('2', '找到「联网控制」或「联网管理」'),
            _guideStep('3', '在应用列表中找到 TrophyRoom'),
            _guideStep('4', '打开 Wi-Fi 和移动数据的联网权限'),
            const SizedBox(height: 16),
            const Text(
              '也请检查：设置 → 应用 → TrophyRoom → 权限 → 确保「网络」已开启',
              style: TextStyle(color: Color(0xFF888), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _openAppSettings(),
            child: const Text('去设置', style: TextStyle(color: Color(0xFFa855f7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了', style: TextStyle(color: Color(0xFF666))),
          ),
        ],
      ),
    );
  }

  Widget _guideStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFa855f7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(num, style: const TextStyle(color: Color(0xFFa855f7), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFccc), fontSize: 13))),
        ],
      ),
    );
  }

  void _openAppSettings() async {
    try {
      await Process.run('am', ['start', '-a', 'android.settings.APPLICATION_DETAILS_SETTINGS',
        '-d', 'package:com.yann.trophyroom']);
    } catch (_) {
      // Fallback: try to open settings directly
      try {
        await Process.run('am', ['start', '-a', 'android.settings.SETTINGS']);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash && !_networkOk) {
      // Show network guide after splash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNetworkGuide();
      });
    }

    return MaterialApp(
      title: 'TrophyRoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _showSplash
          ? const SplashPage()
          : Scaffold(
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutQuint,
                switchOutCurve: Curves.easeInQuint,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutExpo,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: _pages[_currentIndex],
                ),
              ),
              bottomNavigationBar: _buildBottomNav(),
            ),
    );
  }

  // ... rest of the existing widget methods (unchanged)
  final List<Widget> _pages = const [
    HomePage(),
    TrophyPage(),
    DealsPage(),
    GuidePage(),
    SettingsPage(),
  ];

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A12).withOpacity(0),
            const Color(0xFF0A0A12),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16, right: 16, bottom: 8,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF12121f).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2a2a3e).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFa855f7).withOpacity(0.05), blurRadius: 20, spreadRadius: -5),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(0, '🏠', '首页'),
                  _navItem(1, '🏆', '奖杯'),
                  _navItem(2, '💰', '折扣'),
                  _navItem(3, '📖', '攻略'),
                  _navItem(4, '⚙️', '设置'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, String emoji, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFa855f7).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive ? Border.all(color: const Color(0xFFa855f7).withOpacity(0.3), width: 1) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: isActive ? 22 : 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFa855f7) : const Color(0xFF999),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
