import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/trophy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TrophyRoomApp());
}

class TrophyRoomApp extends StatelessWidget {
  const TrophyRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '奖杯屋',
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
  bool _loading = false;
  String _dealsStatus = '';
  String _platform = 'all';
  late final WebViewController _psnWebCtrl;
  bool _psnWebLoading = true;
  String _psnId = '';
  String _steamId = '';
  bool _accountsLoaded = false;
  List<TrophyGame> _trophyGames = [];
  String _error = '';

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
    setState(() => _loading = true);
    await _checkNetwork();
    setState(() => _loading = false);
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
    await _fetchTrophyData(psn, steam);
  }

  Future<void> _fetchTrophyData(String psnId, String steamId) async {
    final apiBase = 'http://8.153.97.56';
    _trophyGames = [];
    _error = '';

    try {
      if (steamId.isNotEmpty) {
        final resp = await http.get(Uri.parse('$apiBase/api/steam?uid=$steamId'))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data['status'] == 'ok' && data['games'] != null) {
            for (final g in data['games']) {
              _trophyGames.add(TrophyGame(
                name: g['name'] ?? 'Unknown',
                platform: 'steam',
                coverUrl: g['logo'],
                totalAchievements: g['total_achievements'] ?? 0,
                unlockedAchievements: g['unlocked_achievements'] ?? 0,
                completionRate: (g['unlocked_achievements'] ?? 0) > 0 && (g['total_achievements'] ?? 0) > 0
                    ? ((g['unlocked_achievements'] / g['total_achievements']) * 100).roundToDouble()
                    : 0,
              ));
            }
          }
        }
      }

      if (psnId.isNotEmpty) {
        final resp = await http.get(Uri.parse('$apiBase/api/psn?uid=$psnId'))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data['psn_id'] != null) {
            _trophyGames.add(TrophyGame(
              name: 'PSN: $psnId',
              platform: 'psn',
              platinum: data['platinum'] ?? 0,
              gold: data['gold'] ?? 0,
              silver: data['silver'] ?? 0,
              bronze: data['bronze'] ?? 0,
              completionRate: double.tryParse((data['completion_rate'] ?? '0').toString()) ?? 0,
            ));
          } else if (data['error'] != null) {
            _error = 'PSN: ${data['error']}';
          }
        }
      }
    } catch (e) {
      _error = '加载失败: $e';
    }
    setState(() => _loading = false);
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
                    // ── 🏆 奖杯屋 — 金橙渐变静态底 + 白色流光 ──
                    SizedBox(
                      height: 30,
                      child: Stack(
                        children: [
                          // 底层：静态金橙渐变
                          Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFF4500)],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                '🏆 奖杯屋',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // 上层：RGB 彩色流光扫描
                          Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                final w = bounds.width;
                                final lightStart = glow * w;
                                final lightEnd = lightStart + w * 0.3;
                                final fadeStart = lightStart - w * 0.15;
                                final fadeEnd = lightEnd + w * 0.15;
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
                                '🏆 奖杯屋',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ── trophyroom — 金橙渐变 + RGB 彩色流光 ──
                    SizedBox(
                      height: 14,
                      child: Stack(
                        children: [
                          Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFF4500)],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                'trophyroom',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w300,
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
                                final lightEnd = lightStart + w * 0.25;
                                return LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    HSLColor.fromAHSL(0.7, ((g * 360) % 360).toDouble(), 0.8, 0.6).toColor(),
                                    HSLColor.fromAHSL(0.7, ((g * 360) % 360).toDouble(), 0.8, 0.6).toColor(),
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                  stops: [
                                    0.0,
                                    (lightStart / w).clamp(0.0, 1.0),
                                    ((lightStart + 6) / w).clamp(0.0, 1.0),
                                    ((lightEnd - 6) / w).clamp(0.0, 1.0),
                                    (lightEnd / w).clamp(0.0, 1.0),
                                    1.0,
                                  ],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'trophyroom',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
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
        _buildPSNStore(),
        _buildModSearch(),
        _buildGuide(),
        const SettingsPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'PSN商店'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Mod'),
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
              onPressed: () => setState(() => _currentTab = 5),
            ),
          ],
        ),
      );
    }

    // Trophy wall content
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              if (_psnId.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.sports_esports, size: 18, color: Colors.blue),
                  label: Text('PSN: $_psnId', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue[900]!.withOpacity(0.3),
                ),
              if (_psnId.isNotEmpty && _steamId.isNotEmpty)
                const SizedBox(width: 8),
              if (_steamId.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.sports_esports, size: 18, color: Colors.orange),
                  label: Text('Steam: $_steamId', style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.orange[900]!.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _trophyGames.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_esports, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text(_error.isNotEmpty ? '加载出错' : '暂无数据',
                                style: TextStyle(color: Colors.grey[500])),
                            if (_error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_error, style: TextStyle(fontSize: 11, color: Colors.red[300])),
                              ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _trophyGames.length,
                        itemBuilder: (ctx, i) {
                          final g = _trophyGames[i];
                          return Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  g.platform == 'psn'
                                      ? Icons.sports_esports
                                      : Icons.games,
                                  size: 36,
                                  color: g.platform == 'psn'
                                      ? Colors.blue[400]
                                      : Colors.orange[400],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    g.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (g.platform == 'psn')
                                  Text('🏆 P' + g.platinum.toString() + ' 🥇' + g.gold.toString() + ' 🥈' + g.silver.toString() + ' 🥉' + g.bronze.toString(),
                                      style: const TextStyle(fontSize: 10))
                                else
                                  Text(g.unlockedAchievements.toString() + '/' + g.totalAchievements.toString(),
                                      style: TextStyle(fontSize: 12, color: Colors.green[300])),
                                if (g.completionRate > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
                                    child: LinearProgressIndicator(
                                      value: g.completionRate / 100,
                                      backgroundColor: Colors.grey[800],
                                      color: Colors.purple[300],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _quickBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.purple[300], size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

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
              if (_loading)
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

  /// PSN商店页面 — WebView 内嵌
  Widget _buildPSNStore() {
    final controller = _psnWebCtrl;
    final loading = _psnWebLoading;
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (loading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  /// Mod搜索页面
  Widget _buildModSearch() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _linkCard(
          icon: Icons.extension,
          title: 'Nexus Mods',
          subtitle: '最大的游戏模组社区',
          url: 'https://www.nexusmods.com',
        ),
        const SizedBox(height: 12),
        _linkCard(
          icon: Icons.gamepad,
          title: 'Steam 创意工坊',
          subtitle: 'Steam Workshop',
          url: 'https://steamcommunity.com/app/570/workshop/',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('快速搜索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: '搜索游戏模组...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (q) async {
                  final encoded = Uri.encodeComponent(q);
                  final url = 'https://www.nexusmods.com/search/?q=$encoded';
                  await _launchUrl(url);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 攻略入口页面
  Widget _buildGuide() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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

  /// 链接卡片
  Widget _linkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[850]!, Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple[300], size: 32),
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
            Icon(Icons.open_in_new, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
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
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('打开链接'),
            content: Text('请复制链接到浏览器打开:\n$url',
                style: const TextStyle(fontSize: 12)),
            actions: [
              TextButton(
                child: const Text('关闭'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    }
  }
  
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
        Text(
          '账号设置',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[100],
          ),
        ),
        const SizedBox(height: 32),
        // PSN account
        Text(
          'PSN 账号',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _bindPsn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('绑定'),
            ),
          ],
        ),
        if (_savedPsnId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
                const SizedBox(width: 6),
                Text(
                  '已绑定 PSN: $_savedPsnId',
                  style: TextStyle(fontSize: 13, color: Colors.green[400]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        // Steam account
        Text(
          'Steam 账号',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _bindSteam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('绑定'),
            ),
          ],
        ),
        if (_savedSteamId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
                const SizedBox(width: 6),
                Text(
                  '已绑定 Steam: $_savedSteamId',
                  style: TextStyle(fontSize: 13, color: Colors.green[400]),
                ),
              ],
            ),
          ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('退出登录', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
