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
import 'pages/splash_page.dart';
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

/// Test network via multiple methods
Future<Map<String, dynamic>> _diagnoseNetwork() async {
  final results = <String, dynamic>{};

  // Method 1: dart:io HttpClient to gitee
  try {
    final start = DateTime.now();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..badCertificateCallback = ((cert, host, port) => true);
    final req = await client.getUrl(Uri.parse('https://gitee.com/yann8888/game-deals/raw/main/README.md'));
    req.headers.set('User-Agent', 'TrophyRoom/1.0');
    final resp = await req.close().timeout(const Duration(seconds: 10));
    final body = await utf8.decodeStream(resp);
    client.close();
    results['dart_io_gitee'] = {
      'ok': resp.statusCode == 200,
      'status': resp.statusCode,
      'time_ms': DateTime.now().difference(start).inMilliseconds,
      'body_len': body.length,
    };
  } catch (e) {
    results['dart_io_gitee'] = {'ok': false, 'error': e.toString()};
  }

  // Method 2: dart:io HttpClient to github
  try {
    final start = DateTime.now();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..badCertificateCallback = ((cert, host, port) => true);
    final req = await client.getUrl(Uri.parse('https://raw.githubusercontent.com/ShinyYann/trophyroom/main/README.md'));
    req.headers.set('User-Agent', 'TrophyRoom/1.0');
    final resp = await req.close().timeout(const Duration(seconds: 10));
    final body = await utf8.decodeStream(resp);
    client.close();
    results['dart_io_github'] = {
      'ok': resp.statusCode == 200,
      'status': resp.statusCode,
      'time_ms': DateTime.now().difference(start).inMilliseconds,
      'body_len': body.length,
    };
  } catch (e) {
    results['dart_io_github'] = {'ok': false, 'error': e.toString()};
  }

  // Method 3: DNS lookup
  try {
    await InternetAddress.lookup('gitee.com');
    results['dns_gitee'] = {'ok': true};
  } catch (e) {
    results['dns_gitee'] = {'ok': false, 'error': e.toString()};
  }

  try {
    await InternetAddress.lookup('github.com');
    results['dns_github'] = {'ok': true};
  } catch (e) {
    results['dns_github'] = {'ok': false, 'error': e.toString()};
  }

  // Method 4: Raw TCP socket to gitee:443
  try {
    final start = DateTime.now();
    final socket = await SecureSocket.connect('gitee.com', 443,
        timeout: const Duration(seconds: 8),
        onBadCertificate: (cert) => true);
    socket.write('GET / HTTP/1.1\r\nHost: gitee.com\r\nConnection: close\r\n\r\n');
    await socket.flush();
    final resp = await utf8.decodeStream(socket);
    socket.close();
    results['raw_socket'] = {
      'ok': resp.startsWith('HTTP/'),
      'time_ms': DateTime.now().difference(start).inMilliseconds,
    };
  } catch (e) {
    results['raw_socket'] = {'ok': false, 'error': e.toString()};
  }

  // Method 5: System shell curl (bypasses app-level network controls)
  try {
    final start = DateTime.now();
    final r = await Process.run('curl', [
      '-s', '--connect-timeout', '5', '--max-time', '8',
      '-H', 'User-Agent: TrophyRoom/1.0',
      'https://gitee.com/yann8888/game-deals/raw/main/README.md'
    ]);
    results['shell_curl'] = {
      'ok': r.exitCode == 0 && (r.stdout as String).isNotEmpty,
      'stdout_len': (r.stdout as String).length,
      'stderr': r.stderr.toString(),
      'time_ms': DateTime.now().difference(start).inMilliseconds,
    };
  } catch (e) {
    results['shell_curl'] = {'ok': false, 'error': e.toString()};
  }

  // Method 6: System shell ping
  try {
    final r = await Process.run('ping', ['-c', '1', '-W', '5', 'gitee.com']);
    results['shell_ping'] = {
      'ok': r.exitCode == 0,
      'stdout': r.stdout.toString().substring(0, min(200, (r.stdout as String).length)),
      'stderr': r.stderr.toString(),
    };
  } catch (e) {
    results['shell_ping'] = {'ok': false, 'error': e.toString()};
  }

  // Method 7: System shell wget
  try {
    final start = DateTime.now();
    final r = await Process.run('wget', [
      '-q', '-O', '-', '--timeout=8',
      '--header=User-Agent: TrophyRoom/1.0',
      'https://gitee.com/yann8888/game-deals/raw/main/README.md'
    ]);
    results['shell_wget'] = {
      'ok': r.exitCode == 0 && (r.stdout as String).isNotEmpty,
      'stdout_len': (r.stdout as String).length,
      'time_ms': DateTime.now().difference(start).inMilliseconds,
    };
  } catch (e) {
    results['shell_wget'] = {'ok': false, 'error': e.toString()};
  }


  // Method 8: Native Android HttpURLConnection via MethodChannel
  try {
    final channel = MethodChannel('com.yann.trophyroom/native_http');
    final start = DateTime.now();
    final resp = await channel.invokeMethod<String>('httpGet', {
      'url': 'https://gitee.com/yann8888/game-deals/raw/main/README.md'
    }).timeout(const Duration(seconds: 10));
    results['native_android'] = {
      'ok': resp != null && resp.isNotEmpty,
      'body_len': resp?.length ?? 0,
      'time_ms': DateTime.now().difference(start).inMilliseconds,
    };
  } catch (e) {
    results['native_android'] = {'ok': false, 'error': e.toString()};
  }

  return results;
}

int min(int a, int b) => a < b ? a : b;

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

  // Run full network diagnosis at startup
  final diag = await _diagnoseNetwork();

  runApp(TrophyRoomApp(diagnosis: diag));
}

class TrophyRoomApp extends StatelessWidget {
  final Map<String, dynamic> diagnosis;
  const TrophyRoomApp({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrophyRoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Show a debug screen first with network test results
      home: _NetworkDebugPage(diagnosis: diagnosis),
    );
  }
}

class _NetworkDebugPage extends StatelessWidget {
  final Map<String, dynamic> diagnosis;
  const _NetworkDebugPage({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final allMethods = ['dart_io_gitee', 'dart_io_github', 'dns_gitee', 'dns_github', 'raw_socket', 'shell_curl', 'shell_wget', 'shell_ping'];
    final anyOk = allMethods.any((m) => diagnosis[m]?['ok'] == true);
    // If network is OK after all, redirect to main app
    if (anyOk) {
      Future.microtask(() {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => const _MainApp(),
        ));
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                '网络诊断结果',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (anyOk)
                const Text('✅ 网络正常!', style: TextStyle(color: Color(0xFF22c55e), fontSize: 16))
              else
                const Text('❌ 所有网络请求失败', style: TextStyle(color: Color(0xFFef4444), fontSize: 16)),
              const SizedBox(height: 24),
              ...allMethods.map((method) {
                final r = diagnosis[method] as Map<String, dynamic>?;
                if (r == null) return const SizedBox();
                final ok = r['ok'] == true;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(ok ? '✅' : '❌', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(method,
                            style: TextStyle(
                              color: ok ? const Color(0xFF22c55e) : const Color(0xFFef4444),
                              fontWeight: FontWeight.bold,
                            )),
                        ],
                      ),
                      if (r['status'] != null)
                        Text('状态码: ${r['status']}', style: const TextStyle(color: Color(0xFF888), fontSize: 12)),
                      if (r['time_ms'] != null)
                        Text('耗时: ${r['time_ms']}ms', style: const TextStyle(color: Color(0xFF888), fontSize: 12)),
                      if (r['body_len'] != null)
                        Text('数据大小: ${r['body_len']} bytes', style: const TextStyle(color: Color(0xFF888), fontSize: 12)),
                      if (r['error'] != null)
                        Text('错误: ${r['error']}', style: const TextStyle(color: Color(0xFFef4444), fontSize: 11)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              if (anyOk)
                const Text('正在跳转主界面...', style: TextStyle(color: Color(0xFF666)))
              else ...[
                const Text('可能的原因:', style: TextStyle(color: Color(0xFFaaa), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('1. 手机管家 → 联网管理 → TrophyRoom 被禁网', style: TextStyle(color: Color(0xFF888), fontSize: 12)),
                const Text('2. 应用装在双开/分身/隐私空间', style: TextStyle(color: Color(0xFF888), fontSize: 12)),
                const Text('3. VPN/代理对 TrophyRoom 生效', style: TextStyle(color: Color(0xFF888), fontSize: 12)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => const _MainApp(),
                  )),
                  child: const Text('跳过诊断 → 进入应用', style: TextStyle(color: Color(0xFFa855f7))),
                ),
              ],
            ],
          ),
        ),
      ),
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

  final List<Widget> _pages = const [
    HomePage(),
    TrophyPage(),
    DealsPage(),
    GuidePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
