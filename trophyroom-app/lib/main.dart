import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'pages/game_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/psnine_client.dart';
import 'services/bookmark_service.dart';
import 'pages/browser_page.dart';
import 'widgets/trophy_icon.dart';

void main() {
  runApp(const TrophyRoomApp());
}

class TrophyRoomApp extends StatelessWidget {
  const TrophyRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrophyRoom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA855F7),
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// 启动动画：纯 Flutter 粒子碎裂 → TROPHYROOM → 奖杯屋大字 → 过渡到首页
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;



  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
    _ctrl.addListener(() => setState(() {}));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionsBuilder: (_, anim, __, child) =>
                Stack(
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 1, end: 0).animate(anim),
                      child: const Scaffold(
                        backgroundColor: Color(0xFF0A0A12),
                        body: SizedBox.shrink(),
                      ),
                    ),
                    FadeTransition(opacity: anim, child: child),
                  ],
                ),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    final fadeIn = (t / 0.2).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: Opacity(
          opacity: fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo 图片 + 轮廓流光 ──
          AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) {
              final t = (_ctrl.value * 2.5) % 1.0;
              return Container(
                width: 172,
                height: 172,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: HSLColor.fromAHSL(
                      0.9,
                      (t * 360) % 360,
                      0.8,
                      0.55,
                    ).toColor(),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HSLColor.fromAHSL(
                        0.5,
                        ((t * 360) % 360),
                        0.8,
                        0.55,
                      ).toColor(),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/logo/logo_yann_design.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
              const SizedBox(height: 16),
              Opacity(
                opacity: ((t - 0.3) * 4).clamp(0.0, 1.0),
                child: Text(
                  'TROPHYROOM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 6,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  final double time;
  final double opacity;

  _SplashPainter({required this.time, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final s = (size.width < size.height ? size.width : size.height) / 360;

    final breathe = 1.0 + 0.04 * math.sin(time * math.pi * 2 * 0.8);
    final glowIntensity = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(time * math.pi * 2 * 0.6));
    final alpha = (opacity * 255).toInt();

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(breathe, breathe);
    canvas.translate(-cx, -cy);

    final gold = Paint()
      ..color = Color.fromARGB(alpha, 212, 175, 55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final glow = Paint()
      ..color = Color.fromARGB((glowIntensity * alpha).toInt(), 255, 215, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * s
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final body = Path();
    body.moveTo(cx - 80*s, cy + 20*s);
    body.lineTo(cx - 80*s, cy - 40*s);
    body.lineTo(cx - 100*s, cy - 45*s);
    body.lineTo(cx - 100*s, cy - 75*s);
    body.lineTo(cx - 70*s, cy - 55*s);
    body.lineTo(cx - 45*s, cy - 90*s);
    body.lineTo(cx, cy - 110*s);
    body.lineTo(cx + 45*s, cy - 90*s);
    body.lineTo(cx + 70*s, cy - 55*s);
    body.lineTo(cx + 100*s, cy - 75*s);
    body.lineTo(cx + 100*s, cy - 45*s);
    body.lineTo(cx + 80*s, cy - 40*s);
    body.lineTo(cx + 80*s, cy + 20*s);
    body.close();
    canvas.drawPath(body, glow);
    canvas.drawPath(body, gold);
    canvas.drawLine(Offset(cx - 55*s, cy + 40*s), Offset(cx + 55*s, cy + 40*s), gold);
    canvas.drawLine(Offset(cx - 75*s, cy + 60*s), Offset(cx + 75*s, cy + 60*s), gold);

    final hl = Path();
    hl.moveTo(cx - 82*s, cy - 30*s);
    hl.cubicTo(cx - 110*s, cy - 25*s, cx - 135*s, cy, cx - 115*s, cy + 35*s);
    canvas.drawPath(hl, glow);
    canvas.drawPath(hl, gold);
    final hr = Path();
    hr.moveTo(cx + 82*s, cy - 30*s);
    hr.cubicTo(cx + 110*s, cy - 25*s, cx + 135*s, cy, cx + 115*s, cy + 35*s);
    canvas.drawPath(hr, glow);
    canvas.drawPath(hr, gold);

    final tGold = Paint()
      ..color = Color.fromARGB(alpha, 255, 215, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    final tGlow = Paint()
      ..color = Color.fromARGB((glowIntensity * alpha).toInt(), 255, 215, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * s
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final tS = 25 * s, tH = 45 * s, tCy = cy + 5 * s;
    canvas.drawLine(Offset(cx - tS, tCy - tH * 0.6), Offset(cx + tS, tCy - tH * 0.6), tGlow);
    canvas.drawLine(Offset(cx - tS, tCy - tH * 0.6), Offset(cx + tS, tCy - tH * 0.6), tGold);
    canvas.drawLine(Offset(cx, tCy - tH * 0.6), Offset(cx, tCy + tH * 0.6), tGlow);
    canvas.drawLine(Offset(cx, tCy - tH * 0.6), Offset(cx, tCy + tH * 0.6), tGold);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplashPainter old) => time != old.time;
}


const List<Map<String, dynamic>> _offlineGames = [
  {"img":"", "name": "Resident Evil 4 PS4 & PS5", "discount": "60%", "price": "HK\$123.20", "original": "HK\$308.00", "platform": "PSN"},
  {"img":"", "name": "Street Fighter 6", "discount": "50%", "price": "HK\$144.00", "original": "HK\$288.00", "platform": "PSN"},
  {"img":"", "name": "人中之龍 極２", "discount": "30%", "price": "HK\$130.90", "original": "HK\$187.00", "platform": "PSN"},
  {"img":"", "name": "Resident Evil Village", "discount": "75%", "price": "HK\$77.00", "original": "HK\$308.00", "platform": "PSN"},
  {"img":"", "name": "ELDEN RING", "discount": "30%", "price": "HK\$348.60", "original": "HK\$498.00", "platform": "PSN"},
  {"img":"", "name": "Cyberpunk 2077", "discount": "50%", "price": "HK\$199.00", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Persona 5 Royal", "discount": "40%", "price": "HK\$238.80", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "God of War Ragnarök", "discount": "25%", "price": "HK\$368.00", "original": "HK\$468.00", "platform": "PSN"},
  {"img":"", "name": "The Last of Us Part I", "discount": "30%", "price": "HK\$308.00", "original": "HK\$438.00", "platform": "PSN"},
  {"img":"", "name": "Horizon Forbidden West", "discount": "50%", "price": "HK\$198.00", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Gran Turismo 7", "discount": "40%", "price": "HK\$238.80", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Spider-Man: Miles Morales", "discount": "45%", "price": "HK\$198.00", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Returnal", "discount": "55%", "price": "HK\$238.00", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Demon's Souls", "discount": "45%", "price": "HK\$318.00", "original": "HK\$568.00", "platform": "PSN"},
  {"img":"", "name": "Ratchet & Clank: Rift Apart", "discount": "40%", "price": "HK\$238.80", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Final Fantasy VII Remake", "discount": "50%", "price": "HK\$199.00", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Ghost of Tsushima", "discount": "40%", "price": "HK\$358.80", "original": "HK\$568.00", "platform": "PSN"},
  {"img":"", "name": "Sekiro: Shadows Die Twice", "discount": "50%", "price": "HK\$199.00", "original": "HK\$398.00", "platform": "PSN"},
  {"img":"", "name": "Bloodborne", "discount": "60%", "price": "HK\$123.20", "original": "HK\$308.00", "platform": "PSN"},
  {"img":"", "name": "Death Stranding", "discount": "65%", "price": "HK\$107.80", "original": "HK\$308.00", "platform": "PSN"},
  {"img":"", "name": "Days Gone", "discount": "60%", "price": "HK\$123.20", "original": "HK\$308.00", "platform": "PSN"},
  {"img":"", "name": "Uncharted 4", "discount": "50%", "price": "HK\$119.00", "original": "HK\$238.00", "platform": "PSN"},
  {"img":"", "name": "Stray", "discount": "40%", "price": "HK\$178.80", "original": "HK\$298.00", "platform": "PSN"},
  {"img":"", "name": "Baldur's Gate 3", "discount": "10%", "price": "HK\$418.00", "original": "HK\$468.00", "platform": "PSN"},
  {"img":"", "name": "Final Fantasy VII Rebirth", "discount": "20%", "price": "HK\$468.00", "original": "HK\$568.00", "platform": "PSN"},
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  String _netStatus = '检测中...';
  bool _netChecked = false;
  late AnimationController _animCtrl;
  late Animation<double> _titleSlide;
  late AnimationController _scanCtrl;
  bool _animDone = false;
  List<Map<String, dynamic>> _deals = [];
  String _dealsStatus = '';
  String _platform = 'all';
  late final WebViewController _psnWebCtrl;
  bool _psnWebLoading = true;
  String _psnId = '';
  String _steamId = '';
  bool _accountsLoaded = false;
  String _error = '';
  Map<String, dynamic>? _cachedHomeData;
  String? _expandedGameId;
  Map<String, List<dynamic>> _gameTrophies = {};
  Map<String, bool> _expandedLoading = {};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleSlide = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _animCtrl.forward().then((_) => setState(() => _animDone = true));
    });
    _deals = List.from(_offlineGames);
    _dealsStatus = '${_offlineGames.length} 款内置游戏';
    _initPSNWebView();
    _checkNetwork();
    _loadAccounts();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  void _initPSNWebView() {
    _psnWebCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _psnWebLoading = true),
          onPageFinished: (_) => setState(() => _psnWebLoading = false),
        ),
      )
      ..loadRequest(Uri.parse('https://store.playstation.com/zh-hans-hk'));
  }

  /// 遍历多个数据源，只要有数据就用在线数据
  Future<void> _checkNetwork() async {
    final urls = [
      'https://gitee.com/yann8888/game-deals/raw/main/docs/data/deals.txt',
      'https://shinyyann.github.io/trophyroom/data/deals.json',
      'https://raw.githubusercontent.com/ShinyYann/trophyroom/main/docs/data/deals.json',
    ];

    for (final url in urls) {
      try {
        final resp = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 8),
            );
        if (resp.statusCode == 200 && resp.body.isNotEmpty) {
          try {
            final data = json.decode(resp.body);
            List<Map<String, dynamic>> list = [];
            if (data is List) {
              list = data.cast<Map<String, dynamic>>();
            } else if (data is Map) {
              for (final key in ['psn', 'steam', 'switch', 'p9_new_lows']) {
                if (data[key] is List) {
                  for (final item in data[key]) {
                    if (item is Map) list.add(Map<String, dynamic>.from(item));
                  }
                }
              }
            }
            if (list.isNotEmpty) {
              setState(() {
                _deals = list;
                _netStatus = '✅ 在线';
                _dealsStatus = '${list.length} 款游戏（在线）';
                _netChecked = true;
              });
              return;
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    // 所有数据源都失败 — 保持离线数据
    setState(() {
      _netStatus = '📡 离线';
      _dealsStatus = '${_offlineGames.length} 款内置游戏（离线）';
      _netChecked = true;
    });
  }

  Future<void> _reloadDeals() async {
    setState(() => _dealsStatus = '刷新中...');
    await _checkNetwork();
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final psn = prefs.getString('psn_id') ?? '';
    final steam = prefs.getString('steam_id') ?? '';
    setState(() {
      _psnId = psn;
      _steamId = steam;
      _accountsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: AnimatedBuilder(
          animation: Listenable.merge([_titleSlide, _scanCtrl]),
          builder: (ctx, _) {
            // RGB 流光位置
            final scan = _scanCtrl.value;
            final r = (scan * 1.0).clamp(0.0, 1.0);
            final g = ((scan + 0.33) % 1.0);
            final b = ((scan + 0.66) % 1.0);
            final glow = (scan * 1.5).clamp(0.0, 1.0);

            return Transform.translate(
              offset: Offset(0, 30 * (1 - _titleSlide.value)),
              child: Opacity(
                opacity: _titleSlide.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 热爱，从来不止一个屏幕。一句热爱，万局不怠。──
                    SizedBox(
                      height: 20,
                      child: Stack(
                        children: [
                          Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFF4500)],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                '热爱，从来不止一个屏幕。',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                final w = bounds.width;
                                final lightStart = glow * w;
                                final lightEnd = lightStart + w * 0.3;
                                return LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    HSLColor.fromAHSL(0.8, ((r * 360) % 360).toDouble(), 0.8, 0.6).toColor(),
                                    HSLColor.fromAHSL(0.8, ((r * 360) % 360).toDouble(), 0.8, 0.6).toColor(),
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                  stops: [
                                    0.0,
                                    (lightStart / w).clamp(0.0, 1.0),
                                    ((lightStart + 10) / w).clamp(0.0, 1.0),
                                    ((lightEnd - 10) / w).clamp(0.0, 1.0),
                                    (lightEnd / w).clamp(0.0, 1.0),
                                    1.0,
                                  ],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                '热爱，从来不止一个屏幕。',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 16,
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Color(0xFF9370DB), Color(0xFF7B68EE)],
                          ).createShader(bounds),
                          child: Text(
                            '一句热爱，万局不怠。',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          if (_netChecked)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(_netStatus, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ),
        ],
      ),
      body: [
        _buildHome(),
        _buildDeals(),
        _buildGuide(),
        SettingsPage(onNpssoChanged: () async {
          // 先加载账号再清缓存，确保 FutureBuilder 拿到最新 _psnId
          await _loadAccounts();
          if (mounted) {
            setState(() {
              _cachedHomeData = null;
            });
          }
        }),
      ][_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        selectedItemColor: Colors.purple[300],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: '折扣'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '攻略'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    if (!_accountsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasAccount = _psnId.isNotEmpty || _steamId.isNotEmpty;

    if (!hasAccount) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              '请先去设置页绑定账号',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('前往设置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () => setState(() => _currentTab = 3),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _cachedHomeData != null
          ? Future.value(_cachedHomeData)
          : _fetchFullPsnData(),
      builder: (context, snapshot) {
        // 首次加载且无缓存时显示加载中
        if (snapshot.connectionState == ConnectionState.waiting && _cachedHomeData == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        // 有效数据：优先用 snapshot，降级到缓存
        final effectiveData = (snapshot.hasData && !snapshot.hasError)
            ? snapshot.data
            : (_cachedHomeData ?? snapshot.data);

        if (snapshot.hasError || !snapshot.hasData) {
          if (effectiveData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text('加载失败: ${snapshot.error ?? "未知错误"}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            );
          }
          // 有缓存时继续渲染
        }
        final data = effectiveData!;
        final psnId = data['psn_id']?.toString() ?? '';
        final level = data['level']?.toString() ?? '?';
        final platinum = data['platinum'] ?? 0;
        final gold = data['gold'] ?? 0;
        final silver = data['silver'] ?? 0;
        final bronze = data['bronze'] ?? 0;
        final totalGames = data['total_games'] ?? 0;
        final perfectGames = data['perfect_games'] ?? 0;
        final completionRate = data['completion_rate'] ?? 0;
        final totalTrophies = (platinum as num).toInt() +
            (gold as num).toInt() +
            (silver as num).toInt() +
            (bronze as num).toInt();
        final games = data['games'] as List<dynamic>? ?? [];
        final hasData = psnId.isNotEmpty;

        return RefreshIndicator(
          color: Colors.purple[300],
          onRefresh: () async {
            _expandedGameId = null;
            _gameTrophies.clear();
            _expandedLoading.clear();
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile Summary Card ──
              if (hasData) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2D1B69)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: PSN ID + Level badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              psnId,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Lv $level',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Purple level progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFA855F7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Row 2: 4 trophy stat columns
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _trophyStat(
                              '🏆', '$platinum', '白金', Colors.cyan[300]!),
                          _trophyStat(
                              '🥇', '$gold', '金', Colors.amber[400]!),
                          _trophyStat(
                              '🥈', '$silver', '银', Colors.grey[400]!),
                          _trophyStat(
                              '🥉', '$bronze', '铜', Colors.orange[400]!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 3: Total Games | Perfect Games | Completion Rate | Total Trophies
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('📊', '$totalGames', '游戏'),
                            _statItem('🏅', '$perfectGames', '完美'),
                            _statItem('🎯', '$completionRate%', '完成率'),
                            _statItem('🏆', '$totalTrophies', '总数'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Game List Title ──
              if (hasData)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '📋 我的游戏 (${games.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),


              // ── 数据加载失败提示 ──
              if (!hasData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text("数据加载失败", style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          "请检查网络连接，在「设置」页绑定 PSN 账号",
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => setState(() => _currentTab = 3),
                          icon: Icon(Icons.settings, size: 18, color: Colors.purple[300]),
                          label: Text("前往设置", style: TextStyle(color: Colors.purple[300])),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // ── Game List ──
              if (games.isEmpty && hasData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.games_outlined,
                            size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text(
                            _error.isNotEmpty
                                ? _error
                                : '暂无游戏数据',
                            style:
                                TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              else
                ...games.map((g) {
                  final game = g as Map<String, dynamic>;
                  final gameId = game['game_id']?.toString() ?? '';
                  final isExpanded = _expandedGameId == gameId;
                  return _buildExpandableGameCard(game,
                      isExpanded: isExpanded);
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text('$emoji $value',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7))),
      ],
    );
  }

  Widget _trophyStat(String emoji, String count, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 2),
        Text(count,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildExpandableGameCard(Map<String, dynamic> game,
      {required bool isExpanded}) {
    final gameId = (game['game_id']?.toString() ?? game['id']?.toString() ?? '');
    final rawName = game['name']?.toString() ?? '';
    final name = _translateGameName(rawName);
    final coverUrl = game['cover_url']?.toString() ?? '';
    final platform = game['platform']?.toString() ?? '';
    final cr = ((game['completion_rate'] ?? 0) as num).toDouble();
    final platinum = game['platinum'] ?? 0;
    final gold = game['gold'] ?? 0;
    final silver = game['silver'] ?? 0;
    final bronze = game['bronze'] ?? 0;

    return Card(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded
              ? Colors.purple[400]!.withOpacity(0.5)
              : Colors.grey[800]!,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => _toggleGame(gameId),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Cover image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: coverUrl.isNotEmpty
                          ? Image.network(coverUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.grey[850],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                    color: Colors.grey[850],
                                    child: Icon(Icons.image,
                                        color: Colors.grey[700],
                                        size: 24),
                                  ))
                          : Container(
                              color: Colors.grey[850],
                              child: Icon(Icons.image,
                                  color: Colors.grey[700],
                                  size: 24),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + Trophy counts (vertical layout)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name + Platform badge on same row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (platform.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: platform == 'PS5'
                                      ? Colors.blue[800]
                                      : platform == 'PS4'
                                          ? Colors.indigo[800]
                                          : platform == 'PS Vita'
                                              ? Colors.teal[800]
                                              : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(platform,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Trophy counts (PSN style icons)
                        Row(
                          children: [
                            if (platinum > 0) ...[
                              const TrophyIcon(type: 'platinum', size: 18),
                              const SizedBox(width: 2),
                              Text('$platinum  ',
                                  style: TextStyle(fontSize: 12, color: Colors.cyan[300])),
                            ],
                            if (gold > 0) ...[
                              const TrophyIcon(type: 'gold', size: 18),
                              const SizedBox(width: 2),
                              Text('$gold  ',
                                  style: TextStyle(fontSize: 12, color: Colors.amber[400])),
                            ],
                            if (silver > 0) ...[
                              const TrophyIcon(type: 'silver', size: 18),
                              const SizedBox(width: 2),
                              Text('$silver  ',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                            ],
                            if (bronze > 0) ...[
                              const TrophyIcon(type: 'bronze', size: 18),
                              const SizedBox(width: 2),
                              Text('$bronze',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[400])),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Progress bar
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: cr / 100,
                                  minHeight: 4,
                                  backgroundColor: Colors.grey[800],
                                  color: cr >= 100
                                      ? Colors.amber
                                      : Colors.purple[300],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${cr.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content (trophy list)
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            if (_expandedLoading[gameId] == true)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2),
                  ),
                ),
              )
            else if (_gameTrophies.containsKey(gameId))
              ...(_gameTrophies[gameId] as List<dynamic>).map((t) {
                final trophy = t as Map<String, dynamic>;
                return _buildTrophyRow(trophy);
              })
            else
              const SizedBox.shrink(),
          ],
        ],
      ),
    );
  }

  Widget _buildTrophyRow(Map<String, dynamic> trophy) {
    final type = trophy['type']?.toString().toLowerCase() ?? '';
    final name = trophy['name']?.toString() ?? '';
    final description = trophy['description']?.toString() ?? '';
    final earned = trophy['earned'] == true;
    final iconUrl = trophy['icon_url']?.toString() ?? '';
    final isPlatinum = type == 'platinum';

    IconData icon;
    Color iconColor;
    if (isPlatinum) {
      icon = Icons.star;
      iconColor = Colors.cyan[300]!;
    } else if (type == 'gold') {
      icon = Icons.emoji_events;
      iconColor = Colors.amber[400]!;
    } else if (type == 'silver') {
      icon = Icons.workspace_premium;
      iconColor = Colors.grey[400]!;
    } else {
      icon = Icons.circle;
      iconColor = Colors.orange[400]!;
    }

    return GestureDetector(
      onTap: () => _showTrophyDetailDialog(context, trophy),
      child: Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: Colors.grey[850]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Trophy icon
          if (iconUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                iconUrl,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                color: earned ? null : Colors.grey,
                colorBlendMode:
                    earned ? null : BlendMode.saturation,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  size: 24,
                  color: earned
                      ? iconColor
                      : iconColor.withOpacity(0.3),
                ),
              ),
            )
          else
            Icon(
              icon,
              size: 24,
              color: earned
                  ? iconColor
                  : iconColor.withOpacity(0.3),
            ),
          const SizedBox(width: 12),
          // Trophy name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: earned
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: earned
                          ? Colors.grey[500]
                          : Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
          // Trophy type badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPlatinum
                  ? Colors.cyan[800]!.withOpacity(0.3)
                  : (type == 'gold'
                      ? Colors.amber[800]!.withOpacity(0.3)
                      : (type == 'silver'
                          ? Colors.grey[700]!.withOpacity(0.3)
                          : Colors.orange[800]!.withOpacity(0.3))),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPlatinum ? '白金' : (type == 'gold' ? '金' : (type == 'silver' ? '银' : '铜')),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPlatinum
                      ? Colors.cyan[300]
                      : (type == 'gold'
                          ? Colors.amber[400]
                          : (type == 'silver'
                              ? Colors.grey[400]
                              : Colors.orange[400]))),
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showTrophyDetailDialog(BuildContext context, Map<String, dynamic> trophy) {
    final name = trophy['name']?.toString() ?? '';
    final type = trophy['type']?.toString() ?? 'bronze';
    final earned = trophy['earned'] == true;
    final earnedDate = trophy['earned_date']?.toString() ?? '';
    final iconUrl = trophy['icon_url']?.toString() ?? '';
    final description = trophy['description']?.toString() ?? '';
    final trophyId = trophy['id']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: _TrophyDetailDialog(
          name: name,
          type: type,
          earned: earned,
          earnedDate: earnedDate,
          iconUrl: iconUrl,
          description: description,
          trophyId: trophyId,
        ),
      ),
    );
  }

  void _toggleGame(String gameId) async {
    if (_expandedGameId == gameId) {
      setState(() => _expandedGameId = null);
      return;
    }

    setState(() {
      _expandedGameId = gameId;
    });

    if (!_gameTrophies.containsKey(gameId)) {
      setState(() => _expandedLoading[gameId] = true);

      // 1. 手机直连 psnine 获取奖杯
      if (_psnId.isNotEmpty) {
        try {
          final psnine = PsnineClient(_psnId);
          final trophies = await psnine.fetchGameTrophies(gameId);
          if (trophies.isNotEmpty) {
            setState(() {
              _gameTrophies[gameId] = trophies;
              _expandedLoading[gameId] = false;
            });
            // 异步缓存到服务器
            _cacheTrophiesToServer(gameId, trophies);
            return;
          }
        } catch (e) {
          print('[Trophies] psnine direct failed: $e');
        }
      }

      // 2. 服务器兜底
      try {
        final resp = await http
            .get(Uri.parse(
                'http://8.153.97.56/api/psn_game_detail?game_id=$gameId&uid=$_psnId'))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          final trophies = data['trophies'] as List<dynamic>? ?? [];
          setState(() {
            _gameTrophies[gameId] = trophies;
            _expandedLoading[gameId] = false;
          });
        } else {
          setState(() => _expandedLoading[gameId] = false);
        }
      } catch (e) {
        setState(() => _expandedLoading[gameId] = false);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchFullPsnData() async {
    // 仅 PSN 数据可用时
    if (_psnId.isEmpty || _accountsLoaded == false) {
      return {'psn_id': '', 'games': []};
    }

    // 1. 先走服务器缓存（最快，~22ms 返回已缓存数据）
    Map<String, dynamic>? serverData;
    try {
      final apiBase = 'http://8.153.97.56';
      final url = '$apiBase/api/psn?uid=$_psnId';
      final resp = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['psn_id'] != null && data['games'] is List && (data['games'] as List).isNotEmpty) {
          serverData = data;
          _cachedHomeData = data;
          print('[Fetch] server cache OK: ${(data['games'] as List).length} games');
          // 服务器有数据 → 立即返回，后台刷新 psnine
          _backgroundRefreshPsnine();
          return data;
        }
      }
    } catch (e) {
      print('[Fetch] server failed: $e');
      _error = '$e';
    }

    // 2. 服务器没数据 → 手机直连 psnine
    try {
      final psnine = PsnineClient(_psnId);
      final data = await psnine.fetchFullData();
      if (data['games'] is List && (data['games'] as List).isNotEmpty) {
        print('[Fetch] psnine OK: ${(data['games'] as List).length} games');
        _cachedHomeData = data;
        // 异步发送到服务器做缓存
        _cacheToServer(data);
        return data;
      }
    } catch (e) {
      print('[Fetch] psnine failed: $e');
    }

    return {'psn_id': _psnId, 'error': '加载失败', 'games': []};
  }

  /// 后台刷新 psnine 数据
  Future<void> _backgroundRefreshPsnine() async {
    try {
      final psnine = PsnineClient(_psnId);
      final data = await psnine.fetchFullData();
      if (data['games'] is List && (data['games'] as List).isNotEmpty) {
        print('[BgRefresh] psnine OK: ${(data['games'] as List).length} games');
        _cacheToServer(data);
        if (mounted) {
          setState(() => _cachedHomeData = data);
        }
      }
    } catch (e) {
      print('[BgRefresh] failed: $e');
    }
  }

  /// 缓存数据到服务器
  Future<void> _cacheToServer(Map<String, dynamic> data) async {
    try {
      final games = data['games'] as List? ?? [];
      // 包含所有数据：游戏列表 + 档案统计
      final cacheBody = {
        'uid': _psnId,
        'games': games,
      };
      // 复制档案级字段
      for (final key in ['level', 'platinum', 'gold', 'silver', 'bronze',
                         'total_games', 'perfect_games', 'completion_rate',
                         'avatar', 'trophy_level', 'progress', 'psn_data_source']) {
        if (data.containsKey(key)) {
          cacheBody[key] = data[key];
        }
      }
      await http.post(
        Uri.parse('http://8.153.97.56/api/psn_cache'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cacheBody),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// 缓存奖杯数据到服务器
  Future<void> _cacheTrophiesToServer(String gameId, List<dynamic> trophies) async {
    try {
      await http.post(
        Uri.parse('http://8.153.97.56/api/psn_cache'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': _psnId,
          'game_id': gameId,
          'trophies': trophies,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// 游戏名称中文化（映射英文→中文）
  static final Map<String, String> _gameNameMap = {
    'Clair Obscur: Expedition 33': '光与影 33号远征队',
    'ELDEN RING NIGHTREIGN': '艾尔登法环 黑夜君临',
    'ELDEN RING': '艾尔登法环',
    'STEINS;GATE ELITE': '命运石之门 精英版',
    'STEINS;GATE': '命运石之门',
    'Monster Hunter Wilds': '怪物猎人 荒野',
    'Monster Hunter Rise': '怪物猎人 崛起',
    'Monster Hunter World': '怪物猎人 世界',
    'Cyberpunk 2077': '赛博朋克 2077',
    'Stellar Blade': '剑星',
    'Trails through Daybreak': '界之轨迹',
    'Trails into Reverie': '黎之轨迹',
    'Trails of Cold Steel': '闪之轨迹',
    "Astro's Playroom": '宇宙机器人无线控制器使用指南',
    'ASTRO BOT': '宇宙机器人',
    'God of War Ragnarök': '战神 诸神黄昏',
    'God of War': '战神',
    'Final Fantasy VII Rebirth': '最终幻想7 重生',
    'Final Fantasy VII Remake': '最终幻想7 重制版',
    'Final Fantasy XVI': '最终幻想16',
    'Black Myth: Wukong': '黑神话 悟空',
    'Ghost of Tsushima': '对马岛之魂',
    'Horizon Forbidden West': '地平线 西之绝境',
    'Horizon Zero Dawn': '地平线 零之黎明',
    'Marvel\'s Spider-Man 2': '漫威蜘蛛侠2',
    'Marvel\'s Spider-Man': '漫威蜘蛛侠',
    'The Last of Us Part I': '最后生还者 第一章',
    'The Last of Us Part II': '最后生还者 第二章',
    'Baldur\'s Gate 3': '博德之门3',
    'Red Dead Redemption 2': '荒野大镖客 救赎2',
    'Grand Theft Auto V': '给他爱5',
    'Wukong': '黑神话 悟空',
    'Persona 5 Royal': '女神异闻录5 皇家版',
    'Persona 5': '女神异闻录5',
    'Persona 4 Golden': '女神异闻录4 黄金版',
    'NieR: Automata': '尼尔 机械纪元',
  };

  /// 翻译游戏名为中文（如果在映射表中）
  String _translateGameName(String name) {
    if (_gameNameMap.containsKey(name)) return _gameNameMap[name]!;
    // 模糊匹配：忽略大小写
    final lower = name.toLowerCase();
    for (final entry in _gameNameMap.entries) {
      if (lower == entry.key.toLowerCase()) return entry.value;
    }
    return name;
  }

  /// 从索尼 API 获取精确游玩时间并合并到 psnine 数据中（不覆盖奖杯状态）
  Widget _buildDeals() {
    List<Map<String, dynamic>> filtered;
    if (_platform == 'newlow') {
      filtered = _deals
          .where((g) => g['discount']?.toString().contains('新史低') == true)
          .toList();
    } else {
      filtered = _platform == 'all'
          ? _deals.where((g) =>
              g['platform']?.toString().toLowerCase() != 'p9_new_lows').toList()
          : _deals.where((g) =>
              g['platform']?.toString().toLowerCase() == _platform).toList();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'psn', 'steam', 'switch', 'newlow'].map((p) {
                final active = _platform == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p == 'all' ? '全部' : p == 'newlow' ? '📉 新史低' : p.toUpperCase()),
                    selected: active,
                    onSelected: (_) => setState(() => _platform = p),
                    selectedColor: Colors.purple[700],
                    labelStyle: TextStyle(
                        fontSize: 13,
                        color: active ? Colors.white : Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(_dealsStatus,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const Spacer(),
              if (_dealsStatus == '刷新中...')
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                GestureDetector(
                  onTap: _reloadDeals,
                  child: Icon(Icons.refresh, size: 18,
                      color: Colors.purple[300]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('暂无数据',
                      style: TextStyle(color: Colors.grey[600])))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final g = filtered[i];
                    final imgUrl = g['img']?.toString() ?? '';
                    final name = g['name']?.toString() ?? '';
                    final plat = g['platform']?.toString() ?? '';
                    final price = g['price']?.toString() ?? '';
                    final original = g['original']?.toString() ?? '';
                    final disc = g['discount']?.toString() ?? '';
                    return InkWell(
                      onTap: () => _showGameDetail(ctx, g),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            // 封面图
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 60, height: 60,
                                child: imgUrl.isNotEmpty
                                    ? Image.network(imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholderIcon())
                                    : _placeholderIcon(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 游戏信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _tag(plat),
                                      const SizedBox(width: 6),
                                      if (original.isNotEmpty)
                                        Text('原$original',
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 11,
                                                decoration: TextDecoration
                                                    .lineThrough)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(price,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                      if (disc.isNotEmpty && disc != '-') ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red[700],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(disc,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.grey[600], size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: text == 'PSN'
            ? Colors.blue[800]
            : text == 'Steam'
                ? Colors.orange[800]
                : Colors.green[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white)),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: Colors.grey[850],
      child: Icon(Icons.videogame_asset, color: Colors.grey[600], size: 30),
    );
  }

  /// 攻略入口页面
  Widget _buildGuide() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── ★ 收藏夹 ──
        FutureBuilder<List<Bookmark>>(
          future: BookmarkService.load(),
          builder: (context, snapshot) {
            final bookmarks = snapshot.data ?? [];
            if (bookmarks.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text('收藏夹',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[200])),
                    const Spacer(),
                    Text('${bookmarks.length} 个收藏',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 8),
                ...bookmarks.map((bm) => Padding(
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
                )),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
        // ── 攻略卡片 ──
        _guideCard(
          icon: '🐉',
          title: '宝可梦殿堂',
          subtitle: '图鉴 / 队伍 / 闪符 / 配队 / 闪值排行',
          color: const Color(0xFFE53935),
        ),
        const SizedBox(height: 12),
        _guideCard(
          icon: '🌿',
          title: '黑神话悟空',
          subtitle: '精魄 / 葫芦 / 结局记录',
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 12),
        _guideCard(
          icon: '🗡️',
          title: '艾尔登法环',
          subtitle: '追忆 / 流派 / 全收集',
          color: const Color(0xFFFDD835),
        ),
        const SizedBox(height: 12),
        _guideCard(
          icon: '🐾',
          title: '怪物猎人荒野',
          subtitle: '金冠 / 武器 / 名片',
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '攻略站数据建设中...\n即将推出各游戏专属攻略内容',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  /// 攻略卡片
  Widget _guideCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        // TODO: 跳转到具体攻略页
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title — 攻略制作中'), duration: const Duration(seconds: 2)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
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

  /// 打开外部链接
  /// 打开外部链接（占位）
  Future<void> _launchUrl(String url) async {}

  void _showGameDetail(BuildContext context, Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _GameDetailCard(game: game),
      ),
    );
  }
}

/// 解析心得内容中的 HTML 链接和纯文本 URL 为 RichText 可点击 span
InlineSpan _parseHtmlLinks(String text, BuildContext context) {
  final spans = <InlineSpan>[];
  final linkPattern = RegExp(r'<a\s+href="(https?://[^"]+)"[^>]*>([^<]+)</a>');
  
  // 第一步：替换所有 <a> 标签为占位符，同时保存链接信息
  final links = <_ParsedLink>[];
  String cleanText = text.replaceAllMapped(linkPattern, (m) {
    links.add(_ParsedLink(url: m.group(1)!, label: m.group(2)!));
    return '%%LINK${links.length - 1}%%';
  });
  
  // 第二步：检测纯文本 URL（http/https）
  final urlPattern = RegExp(r'(https?://[^\s<>"]+)');
  cleanText = cleanText.replaceAllMapped(urlPattern, (m) {
    links.add(_ParsedLink(url: m.group(1)!, label: m.group(1)!));
    return '%%LINK${links.length - 1}%%';
  });

  // 第三步：分割占位符，构建 RichText
  final segments = cleanText.split(RegExp(r'(%%LINK\d+%%)'));
  for (final seg in segments) {
    if (seg.startsWith('%%LINK') && seg.endsWith('%%')) {
      final idx = int.tryParse(seg.replaceAll(RegExp(r'[^\d]'), ''));
      if (idx != null && idx < links.length) {
        final link = links[idx];
        spans.add(TextSpan(
          text: link.label,
          style: const TextStyle(color: Colors.lightBlue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BrowserPage(initialUrl: link.url, initialTitle: link.label),
                ),
              );
            },
        ));
        continue;
      }
    }
    if (seg.isNotEmpty) {
      spans.add(TextSpan(text: seg));
    }
  }

  return TextSpan(children: spans);
}

class _ParsedLink {
  final String url;
  final String label;
  _ParsedLink({required this.url, required this.label});
}

class _TrophyDetailDialog extends StatefulWidget {
  final String name;
  final String type;
  final bool earned;
  final String earnedDate;
  final String iconUrl;
  final String description;
  final String trophyId;

  const _TrophyDetailDialog({
    required this.name,
    required this.type,
    required this.earned,
    required this.earnedDate,
    required this.iconUrl,
    required this.description,
    this.trophyId = '',
  });

  @override
  State<_TrophyDetailDialog> createState() => _TrophyDetailDialogState();
}

class _TrophyDetailDialogState extends State<_TrophyDetailDialog> {
  List<Map<String, dynamic>> _tips = [];
  bool _tipsLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.trophyId.isNotEmpty) {
      _fetchTips();
    }
  }

  Future<void> _fetchTips() async {
    if (!mounted) return;
    setState(() => _tipsLoading = true);
    try {
      final psnine = PsnineClient('');
      final tips = await psnine.fetchTrophyTips(widget.trophyId);
      if (mounted) {
        setState(() {
          _tips = tips;
          _tipsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _tipsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.type == 'platinum' ? '白金' :
                      widget.type == 'gold' ? '金' :
                      widget.type == 'silver' ? '银' : '铜';
    final typeColor = widget.type == 'platinum' ? Colors.cyan[300] :
                      widget.type == 'gold' ? Colors.amber[400] :
                      widget.type == 'silver' ? Colors.grey[400] : Colors.orange[400];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 关闭按钮 ──
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              ),
            ),
          ),
        ),
        // ── 奖杯信息 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Icon
              if (widget.iconUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.iconUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    color: widget.earned ? null : Colors.grey,
                    colorBlendMode: widget.earned ? null : BlendMode.saturation,
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.emoji_events, size: 32, color: typeColor),
                ),
              const SizedBox(height: 12),
              // Name
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Description
              if (widget.description.isNotEmpty)
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              const SizedBox(height: 10),
              // Earned status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.earned
                      ? Colors.green[900]!.withOpacity(0.3)
                      : Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.earned ? Icons.check_circle : Icons.lock,
                      size: 14,
                      color: widget.earned ? Colors.green[300] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.earned
                          ? (widget.earnedDate.isNotEmpty
                              ? '已获得 · ${widget.earnedDate}'
                              : '已获得')
                          : '未获得',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.earned ? Colors.green[300] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ═══ 心得 ═══
              if (_tipsLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        // ── 心得列表（可滚动） ──
        if (_tips.isNotEmpty)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💬 心得',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: _tips.map((tip) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // 用户头像
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Image.network(
                                      tip['avatar']?.toString() ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: Colors.grey[700]),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(tip['user'] ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.cyan[300], fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Text(tip['date'] ?? '',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              _parseHtmlLinks(tip['content'] ?? '', context),
                              style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  final VoidCallback? onNpssoChanged;

  const SettingsPage({super.key, this.onNpssoChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _psnCtrl = TextEditingController();
  final TextEditingController _steamCtrl = TextEditingController();
  String _savedPsnId = '';
  String _savedSteamId = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPsnId = prefs.getString('psn_id') ?? '';
      _savedSteamId = prefs.getString('steam_id') ?? '';
      _psnCtrl.text = _savedPsnId;
      _steamCtrl.text = _savedSteamId;
      _loaded = true;
    });
  }

  Future<void> _bindPsn() async {
    final id = _psnCtrl.text.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('psn_id', id);
    setState(() => _savedPsnId = id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PSN 账号已绑定')),
      );
    }
    widget.onNpssoChanged?.call();
  }

  Future<void> _bindSteam() async {
    final id = _steamCtrl.text.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('steam_id', id);
    setState(() => _savedSteamId = id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Steam 账号已绑定')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('psn_id');
    await prefs.remove('steam_id');
    setState(() {
      _savedPsnId = '';
      _savedSteamId = '';
      _psnCtrl.clear();
      _steamCtrl.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已退出登录')),
      );
    }
  }

  @override
  void dispose() {
    _psnCtrl.dispose();
    _steamCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        Text('账号设置',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[100]),
        ),
        const SizedBox(height: 32),
        Text('PSN 账号',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _psnCtrl,
                decoration: InputDecoration(
                  hintText: '输入 PSN ID',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: _bindPsn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('绑定'),
            ),
          ],
        ),
        if (_savedPsnId.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
                SizedBox(width: 6),
                Text('已绑定 PSN: $_savedPsnId',
                  style: TextStyle(fontSize: 13, color: Colors.green[400]),
                ),
              ],
            ),
          ),
        SizedBox(height: 24),
        Text('Steam 账号',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300]),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _steamCtrl,
                decoration: InputDecoration(
                  hintText: '输入 Steam ID',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: _bindSteam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('绑定'),
            ),
          ],
        ),
        if (_savedSteamId.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
                SizedBox(width: 6),
                Text('已绑定 Steam: $_savedSteamId',
                  style: TextStyle(fontSize: 13, color: Colors.green[400]),
                ),
              ],
            ),
          ),
        SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text('退出登录', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }
}

class _GameDetailCard extends StatelessWidget {
  final Map<String, dynamic> game;
  const _GameDetailCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final name = game['name']?.toString() ?? '';
    final imgUrl = game['img']?.toString() ?? '';
    final plat = game['platform']?.toString() ?? '';
    final price = game['price']?.toString() ?? '';
    final original = game['original']?.toString() ?? '';
    final disc = game['discount']?.toString() ?? '';
    final rating = game['rating']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[800]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 封面大图
          if (imgUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(imgUrl, height: 200,
                  width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200, color: Colors.grey[850],
                    child: Icon(Icons.videogame_asset, size: 60,
                        color: Colors.grey[600]),
                  )),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // 信息行
                _infoRow(Icons.smartphone, plat),
                if (rating.isNotEmpty)
                  _infoRow(Icons.star, '评分: $rating'),
                const SizedBox(height: 12),
                // 价格
                Row(
                  children: [
                    Text(price, style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold,
                        color: Colors.green[400])),
                    if (original.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(original, style: TextStyle(
                          fontSize: 14, color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough)),
                    ],
                    if (disc.isNotEmpty && disc != '-') ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(disc, style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
        ],
      ),
    );
  }
}
// Trigger build Sun May  3 20:14:20 CST 2026
// trigger 1777813344
