import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'pages/home_page.dart';
import 'pages/trophy_page.dart';
import 'pages/deals_page.dart';
import 'pages/guide_page.dart';
import 'pages/settings_page.dart';
import 'models/app_theme.dart';

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

  // Request network permission on startup (triggers system dialog on Chinese ROMs)
  try {
    final channel = MethodChannel('com.yann.trophyroom/native_http');
    await channel.invokeMethod<bool>('requestNetworkPermission');
  } catch (_) {}

  runApp(TrophyRoomApp());
}

class TrophyRoomApp extends StatelessWidget {
  const TrophyRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrophyRoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _MainApp(),
    );
  }
}

class _MainApp extends StatefulWidget {
  const _MainApp();

  @override
  State<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<_MainApp> {
  int _currentIndex = 0;
  bool _networkIssue = false;

  final List<Widget> _pages = const [
    HomePage(),
    TrophyPage(),
    DealsPage(),
    GuidePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    bool ok = false;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..badCertificateCallback = ((cert, host, port) => true);
      final req = await client.getUrl(Uri.parse('https://gitee.com/yann8888/game-deals/raw/main/README.md'));
      req.headers.set('User-Agent', 'TrophyRoom/1.0');
      final resp = await req.close().timeout(const Duration(seconds: 5));
      ok = resp.statusCode == 200;
      client.close();
    } catch (_) {}

    if (!ok && mounted) {
      setState(() => _networkIssue = true);
    }
  }

  void _onRequestNetwork() {
    // Ask user to go to settings to enable network access
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('📶', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text('需要联网权限', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TrophyRoom 需要联网才能获取游戏数据。\n\n'
              '请点击下方按钮，在系统设置中：\n'
              '找到 "TrophyRoom" → 开启联网开关\n\n'
              '如果找不到联网选项，请查看手机管家的"联网管理"',
              style: TextStyle(color: Color(0xFFaaa), fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后', style: TextStyle(color: Color(0xFF666))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openNetworkSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFa855f7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('去开启联网', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openNetworkSettings() async {
    try {
      await Process.run('am', [
        'start',
        '-a', 'android.settings.APPLICATION_DETAILS_SETTINGS',
        '-d', 'package:com.yann.trophyroom'
      ]);
    } catch (_) {
      try {
        await Process.run('am', [
          'start',
          '-a', 'android.settings.MANAGE_ALL_APPLICATIONS_SETTINGS'
        ]);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Network warning banner
              if (_networkIssue)
                GestureDetector(
                  onTap: _onRequestNetwork,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFef4444), Color(0xFFdc2626)],
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text('🚫', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '无网络连接，点击开启联网权限',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
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
              ),
            ],
          ),
          // Bottom nav
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

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
