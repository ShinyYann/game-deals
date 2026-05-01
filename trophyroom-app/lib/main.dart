import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'pages/trophy_page.dart';
import 'pages/deals_page.dart';
import 'pages/guide_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'models/app_theme.dart';

/// Global crash log path
String? crashLogPath;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) async {
    FlutterError.presentError(details);
    final log = '[${DateTime.now()}][FLUTTER] ${details.exception}\n${details.stack}\n';
    final dir = Directory('/storage/emulated/0/Android/data/com.yann.trophyroom/files');
    if (await dir.exists()) {
      await File('${dir.path}/crash.log').writeAsString(log, mode: FileMode.append);
    } else {
      // fallback
      final tmp = Directory('/data/data/com.yann.trophyroom/files');
      if (await tmp.exists()) {
        await File('${tmp.path}/crash.log').writeAsString(log, mode: FileMode.append);
      }
    }
  };

  // Try-catch the entire app
  runZonedGuarded(() async {
    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0A12),
        systemNavigationBarIconBrightness: Brightness.light,
      ));
      runApp(const TrophyRoomApp());
    } catch (e, stack) {
      final log = '[${DateTime.now()}][INIT] $e\n$stack\n';
      final dir = Directory('/data/data/com.yann.trophyroom/files');
      if (await dir.exists()) {
        await File('${dir.path}/crash.log').writeAsString(log, mode: FileMode.append);
      }
    }
  }, (Object error, StackTrace stack) async {
    final log = '[${DateTime.now()}][ZONE] $error\n$stack\n';
    final dir = Directory('/data/data/com.yann.trophyroom/files');
    if (await dir.exists()) {
      await File('${dir.path}/crash.log').writeAsString(log, mode: FileMode.append);
    }
  });
}

class TrophyRoomApp extends StatefulWidget {
  const TrophyRoomApp({super.key});

  @override
  State<TrophyRoomApp> createState() => _TrophyRoomAppState();
}

class _TrophyRoomAppState extends State<TrophyRoomApp> {
  int _currentIndex = 0;
  bool _showSplash = true;

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
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          // Navigation background blur panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF12121f).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2a2a3e).withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFa855f7).withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
            ),
          ),
          // Nav items
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
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFa855f7).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(
                  color: const Color(0xFFa855f7).withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: isActive ? 22 : 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFa855f7)
                    : const Color(0xFF666),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
