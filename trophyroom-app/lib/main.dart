import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'pages/game_detail_page.dart';
import 'pages/web_view_page.dart';
import 'pages/bookmark_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/steam_video.dart';

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
    with TickerProviderStateMixin {
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
  String _npsso = '';
  bool _accountsLoaded = false;
  String _error = '';
  Map<String, dynamic>? _cachedHomeData;  // 本地缓存
  int _homeLastRefreshMs = 0;              // 上次刷新时间戳
  // 用 ValueNotifier 避免展开关闭时重建整页
  bool _vfxBlur = true;
  bool _vfxGlass = true;
  bool _videoBg = false;                  // Steam 动态背景
  WebViewController? _videoWebCtrl;
  String? _trailerUrl;
  bool _videoLoading = false;
  Map<String, dynamic> _vfx = {};        // {crystal/neon/sweep/breath: {en,intensity,color,speed}}
  late AnimationController _vfxCtrl;

  static const _vfxColors = {
    '💜': 0xFF7C3AED, '💙': 0xFF3B82F6, '💚': 0xFF06B6D4,
    '💛': 0xFFF59E0B, '🩷': 0xFFEC4899, '🤍': 0xFFE5E7EB,
  };

  Map<String, dynamic> _defaultVfx(String k) => switch (k) {
    'crystal' => {'en': false, 'intensity': 0.15, 'color': 0xFF7C3AED},
    'neon'    => {'en': false, 'intensity': 0.4,  'color': 0xFF7C3AED},
    'sweep'   => {'en': false, 'intensity': 0.5,  'speed': 1.0},
    'breath'  => {'en': false, 'intensity': 0.4,  'color': 0xFF7C3AED, 'speed': 1.0},
    _ => {},
  };

  dynamic _v(String k, String field) => (_vfx[k] ?? _defaultVfx(k))[field];
  bool _ve(String k) => (_vfx[k] ?? _defaultVfx(k))['en'] == true;

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
    _loadVfxPrefs();
    _vfxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  Future<void> _loadVfxPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('vfx_cfg');
    Map<String, dynamic> cfg;
    if (raw != null) {
      cfg = Map<String, dynamic>.from(jsonDecode(raw));
    } else {
      cfg = {};
    }
    setState(() {
      _vfxBlur = prefs.getBool('vfx_blur') ?? true;
      _vfxGlass = prefs.getBool('vfx_glass') ?? true;
      _videoBg = prefs.getBool('video_bg') ?? false;
      _vfx = cfg;
    });
    if (_videoBg) {
      _loadTrailer();
    } else {
      _trailerUrl = null;
      _videoWebCtrl = null;
      setState(() {});
    }
  }

  Future<void> _saveVfx() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vfx_cfg', jsonEncode(_vfx));
  }

  Future<void> _loadTrailer() async {
    if (_videoLoading || _trailerUrl != null) return;
    setState(() => _videoLoading = true);
    // Get latest game name from cached data
    final games = _cachedHomeData?['games'] as List<dynamic>?;
    final gameName = games?.isNotEmpty == true
        ? (games!.first as Map<String, dynamic>)['game_name']?.toString() ?? ''
        : '';
    final url = gameName.isNotEmpty
        ? await SteamVideoService.findTrailer(gameName)
        : null;
    if (mounted && url != null) {
      _trailerUrl = url;
      _initVideoWebView();
    }
    if (mounted) setState(() => _videoLoading = false);
  }

  void _initVideoWebView() {
    if (_trailerUrl == null) return;
    _videoWebCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
<!DOCTYPE html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<style>
*{margin:0;padding:0}
html,body{height:100%;overflow:hidden;background:#000}
video{width:100%;height:100%;object-fit:cover}
</style></head>
<body>
<video autoplay muted loop playsinline webkit-playsinline>
  <source src="$_trailerUrl" type="application/x-mpegURL">
</video>
<script>
var v=document.querySelector("video");
v.play().catch(function(){});
</script>
</body></html>
''');
    setState(() {});
  }

  Future<void> _toggleVideoBg(bool on) async {
    _videoBg = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('video_bg', on);
    if (on) {
      _loadTrailer();
    } else {
      _videoWebCtrl = null;
      _trailerUrl = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scanCtrl.dispose();
    _vfxCtrl.dispose();
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
    final npsso = prefs.getString('psn_npsso') ?? '';

    // 读取本地缓存：秒开关键
    final cacheKey = 'home_cache_$psn';
    _homeLastRefreshMs = prefs.getInt('${cacheKey}_ts') ?? 0;
    final cacheJson = prefs.getString(cacheKey);
    if (cacheJson != null && cacheJson.isNotEmpty) {
      try {
        _cachedHomeData = json.decode(cacheJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    setState(() {
      _psnId = psn;
      _steamId = steam;
      _npsso = npsso;
      _accountsLoaded = true;
    });

    // 有缓存 → 后台静默刷新，App 秒开不倒等
    if (_cachedHomeData != null && _psnId.isNotEmpty) {
      _backgroundRefresh();
    }
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
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHome(),
          _buildDeals(),
          _buildGuide(),
          SettingsPage(onVfxChanged: () => _loadVfxPrefs()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTab,
        onTap: (i) {
          setState(() => _currentTab = i);
          if (i == 0) { _loadAccounts(); _checkNetwork(); }
        },
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
      // 缓存优先：有缓存秒出，没缓存走 API
      future: _cachedHomeData != null
          ? Future.value(_cachedHomeData)
          : _fetchFullPsnData(),
      builder: (context, snapshot) {
        // 有缓存时跳过转圈 —— Future.value() 会有短暂 waiting 态导致闪烁
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_cachedHomeData == null) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          // 缓存命中 — fall through 直接用缓存渲染
        }
        // snapshot.data 有效用 snapshot，否则降级到缓存
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
          // 有缓存 — 降级显示
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
        final recentCoverUrl = (games.isNotEmpty)
            ? (games.first as Map<String, dynamic>)['cover_url']?.toString() ?? ''
            : '';

        return RefreshIndicator(
          color: Colors.purple[300],
          onRefresh: () async {
            // 下拉刷新：跳过缓存，走 API
            _cachedHomeData = null;
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile Summary Card (Spotify-style) ──
              if (hasData) ...[
                AnimatedBuilder(
                  animation: _vfxCtrl,
                  builder: (context, child) {
                    final breath = _ve('breath');
                    final bi = _v('breath', 'intensity') as double;
                    final bc = Color(_v('breath', 'color') as int);
                    final bp = (math.sin(_vfxCtrl.value * 6.28 * (_v('breath', 'speed') as double)) + 1) / 2;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: breath ? [
                          BoxShadow(color: bc.withOpacity(0.2 * bi * bp), blurRadius: 16, spreadRadius: 2),
                          BoxShadow(color: bc.withOpacity(0.08 * bi * bp), blurRadius: 32, spreadRadius: 6),
                        ] : null,
                      ),
                      child: child,
                    );
                  },
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 240,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Layer 0: Steam video background
                        if (_videoBg && _videoWebCtrl != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: WebViewWidget(controller: _videoWebCtrl!),
                            ),
                          ),
                        // Layer 1: Blurred game cover background
                        if (recentCoverUrl.isNotEmpty && _vfxBlur)
                          Positioned.fill(
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Image.network(
                                recentCoverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Non-blurred cover (VFX off)
                        if (recentCoverUrl.isNotEmpty && !_vfxBlur)
                          Positioned.fill(
                            child: Image.network(
                              recentCoverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Fallback gradient when no cover
                        if (recentCoverUrl.isEmpty)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                        // Crystal glass tint overlay
                        if (_ve('crystal'))
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _vfxCtrl,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment(0.3 + math.sin(_vfxCtrl.value * 6.28) * 0.15,
                                          -0.4 + math.cos(_vfxCtrl.value * 6.28) * 0.1),
                                      radius: 0.7,
                                      colors: [
                                        Color(_v('crystal', 'color') as int)
                                            .withOpacity((_v('crystal', 'intensity') as double) * 1.2),
                                        Color(_v('crystal', 'color') as int)
                                            .withOpacity((_v('crystal', 'intensity') as double) * 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Dark overlay — lighter, let the background show through
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.15),
                                  Colors.black.withOpacity(0.35),
                                  Colors.black.withOpacity(0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Layer 2: Content
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 0.5),
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
                                // Row 2: Trophy stat columns
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _trophyStat('🏆', '$platinum', Colors.cyan[300]!),
                                    _trophyStat('🥇', '$gold', Colors.amber[400]!),
                                    _trophyStat('🥈', '$silver', Colors.grey[400]!),
                                    _trophyStat('🥉', '$bronze', Colors.orange[400]!),
                                  ],
                                ),
                                // Row 3: Stats strip (crystal glass)
                                if (_vfxGlass)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(
                                        sigmaX: 16, sigmaY: 16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white.withOpacity(0.25),
                                            width: 0.8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.05),
                                            blurRadius: 2,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Sweep light effect
                        if (_ve('sweep'))
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedBuilder(
                                animation: _vfxCtrl,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _SweepPainter(
                                      time: _vfxCtrl.value * (_v('sweep', 'speed') as double),
                                      intensity: _v('sweep', 'intensity') as double,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        // Neon border glow
                        if (_ve('neon'))
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _vfxCtrl,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _NeonBorderPainter(
                                    color: Color(_v('neon', 'color') as int),
                                    intensity: _v('neon', 'intensity') as double,
                                    time: _vfxCtrl.value,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ),
              ],

              // ── Total Play Time Summary ──
              if (hasData && games.isNotEmpty) ...[
                () {
                  int totalSeconds = 0;
                  for (final g in games) {
                    final dur = (g as Map<String, dynamic>)['play_duration_raw']?.toString() ?? '';
                    final h = RegExp(r'PT(\d+)H').firstMatch(dur);
                    final m = RegExp(r'(\d+)M').firstMatch(dur);
                    final s = RegExp(r'(\d+)S').firstMatch(dur);
                    if (h != null) totalSeconds += int.parse(h.group(1)!) * 3600;
                    if (m != null) totalSeconds += int.parse(m.group(1)!) * 60;
                    if (s != null) totalSeconds += int.parse(s.group(1)!);
                  }
                  final totalHours = totalSeconds ~/ 3600;
                  final totalMins = (totalSeconds % 3600) ~/ 60;
                  final totalTimeStr = totalHours > 0 ? '$totalHours小时${totalMins}分' : '${totalMins}分';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('🎮 总游戏时长：$totalTimeStr',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  );
                }(),
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
              else if (!hasData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text(
                            _error.isNotEmpty ? '加载失败: $_error\n下拉刷新重试' : '数据加载中...',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              else
                ...games.map((g) => _buildGameCard(g as Map<String, dynamic>)),
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

  Widget _trophyStat(String emoji, String count, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(count,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final name = game['name']?.toString() ?? '';
    final coverUrl = game['cover_url']?.toString() ?? '';
    final earned = (game['earned'] as num?)?.toInt() ?? 0;
    final defined = (game['defined'] as num?)?.toInt() ?? 1;
    final platinum = (game['platinum'] as num?)?.toInt() ?? 0;
    final gold = (game['gold'] as num?)?.toInt() ?? 0;
    final silver = (game['silver'] as num?)?.toInt() ?? 0;
    final bronze = (game['bronze'] as num?)?.toInt() ?? 0;
    final progress = (game['progress'] as num?)?.toInt() ??
        (defined > 0 ? (earned * 100 ~/ defined) : 0);
    final playDuration = game['play_duration']?.toString();

    // Calculate game level from trophy counts
    final gamePoints = platinum * 300 + gold * 90 + silver * 30 + bronze * 15;
    final gameLevel = (gamePoints / 60).ceil().clamp(1, 999);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game icon
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: coverUrl.isNotEmpty
                ? Image.network(coverUrl, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48, height: 48, color: Colors.grey[800],
                      child: Icon(Icons.videogame_asset, color: Colors.grey[600], size: 24)))
                : Container(
                    width: 48, height: 48, color: Colors.grey[800],
                    child: Icon(Icons.videogame_asset, color: Colors.grey[600], size: 24)),
          ),
          const SizedBox(width: 12),
          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Level badge row
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Lv.$gameLevel', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 100 ? Colors.cyan[300]! : Colors.purple[300]!),
                  ),
                ),
                const SizedBox(height: 4),
                // Trophy counts row
                Row(
                  children: [
                    _trophyCountIcon('◈', platinum, Colors.cyan[300]!),
                    const SizedBox(width: 8),
                    _trophyCountIcon('●', gold, Colors.amber[400]!),
                    const SizedBox(width: 8),
                    _trophyCountIcon('◉', silver, Colors.grey[400]!),
                    const SizedBox(width: 8),
                    _trophyCountIcon('○', bronze, Colors.orange[400]!),
                    const Spacer(),
                    Text('$progress%', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                // Play duration (if available)
                if (playDuration != null && playDuration.isNotEmpty && playDuration != 'None')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('⏱️ $playDuration',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trophyCountIcon(String icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(width: 2),
        Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }
    final urlRegex = RegExp(r'https?://[^\s，。；！？、]+');
    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 13));
    }
    final spans = <InlineSpan>[];
    int lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      final url = m.group(0)!;
      // Use WidgetSpan with GestureDetector — inline tap opens in-app WebView
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WebViewPage(url: url))),
          child: Text(url,
              style: TextStyle(color: Colors.cyan[300], fontSize: 13, decoration: TextDecoration.underline)),
        ),
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey[300], fontSize: 13),
        children: spans,
      ),
    );
  }

  Future<void> _saveHomeCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'home_cache_$_psnId';
    await prefs.setString(key, json.encode(data));
    await prefs.setInt('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _backgroundRefresh() async {
    final data = await _fetchFullPsnData();
    if (mounted && data['psn_id']?.toString().isNotEmpty == true) {
      // 只在有游戏数据时才更新缓存（失败时不覆盖旧缓存）
      final games = (data['games'] as List?) ?? [];
      if (games.isNotEmpty || data['error'] == null) {
        setState(() {
          _cachedHomeData = data;
          _error = data['error']?.toString() ?? '';
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchFullPsnData() async {
    // 仅 PSN 数据可用时
    if (_psnId.isEmpty || _accountsLoaded == false) {
      return {'psn_id': '', 'games': []};
    }
    try {
      final apiBase = 'http://8.153.97.56';
      final url = '${apiBase}/api/psn?uid=$_psnId${_npsso.isNotEmpty ? '&npsso=$_npsso' : ''}';
      final resp = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['psn_id'] != null) {
          _saveHomeCache(data);
          _cachedHomeData = data;
          return data;
        }
      }
    } catch (e) {
      _error = '$e';
    }
    return {'psn_id': _psnId, 'error': _error, 'games': []};
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
        // 📑 攻略收藏夹入口
        _guideCard(
          icon: '📑',
          title: '攻略收藏夹',
          subtitle: '已收藏的网页攻略 · 点击续读',
          color: const Color(0xFFFF8F00),
          onTapOverride: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BookmarkListPage()));
          },
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
    VoidCallback? onTapOverride,
  }) {
    return InkWell(
      onTap: onTapOverride ??
          () {
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
  final VoidCallback? onVfxChanged;
  const SettingsPage({super.key, this.onVfxChanged});

  static const _vfxColors = {
    '💜': 0xFF7C3AED, '💙': 0xFF3B82F6, '💚': 0xFF06B6D4,
    '💛': 0xFFF59E0B, '🩷': 0xFFEC4899, '🤍': 0xFFE5E7EB,
  };

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _psnCtrl = TextEditingController();
  final TextEditingController _steamCtrl = TextEditingController();
  final TextEditingController _npssoCtrl = TextEditingController();
  String _savedPsnId = '';
  String _savedSteamId = '';
  String _savedNpsso = '';
  bool _loaded = false;
  bool _npssoLoading = false;
  Map<String, dynamic> _vfxCfg = {};
  bool _videoBg = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('vfx_cfg');
    setState(() {
      _savedPsnId = prefs.getString('psn_id') ?? '';
      _savedSteamId = prefs.getString('steam_id') ?? '';
      _savedNpsso = prefs.getString('psn_npsso') ?? '';
      _psnCtrl.text = _savedPsnId;
      _steamCtrl.text = _savedSteamId;
      _npssoCtrl.text = _savedNpsso;
      _vfxCfg = raw != null ? Map<String, dynamic>.from(jsonDecode(raw)) : {};
      _videoBg = prefs.getBool('video_bg') ?? false;
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

  Future<void> _loginPsn() async {
    final npsso = _npssoCtrl.text.trim();
    final uid = _savedPsnId.isNotEmpty ? _savedPsnId : _psnCtrl.text.trim();
    if (npsso.isEmpty || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先绑定 PSN ID 并输入 NPSSO')),
      );
      return;
    }
    setState(() => _npssoLoading = true);
    try {
      final uri = Uri.parse('http://8.153.97.56/api/psn_set_npsso?uid=$uid&npsso=$npsso');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      final data = jsonDecode(resp.body);
      if (data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('psn_npsso', npsso);
        await prefs.setString('psn_id', uid);
        setState(() {
          _savedNpsso = npsso;
          _savedPsnId = uid;
        });
        final onlineId = data['online_id']?.toString();
        if (onlineId != null && onlineId.isNotEmpty && onlineId != uid) {
          _psnCtrl.text = onlineId;
          await prefs.setString('psn_id', onlineId);
          setState(() => _savedPsnId = onlineId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['token_ok'] == true
                ? 'PSN 登录成功！可正常加载游戏数据'
                : 'NPSSO 已保存，但 Token 验证失败：${data['error'] ?? ''}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败：${data['error']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误：$e')),
        );
      }
    } finally {
      setState(() => _npssoLoading = false);
    }
  }

  void _showNpssoGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('如何获取 NPSSO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _guideStep('1', '浏览器打开 playstation.com'),
            _guideStep('2', '登录你的 PSN 账号'),
            _guideStep('3', 'F12 → Application → Cookies'),
            _guideStep('4', '找到 npsso，复制值'),
            _guideStep('5', '粘贴到输入框，点登录'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _guideStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14))),
        ],
      ),
    );
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

  Future<void> _toggleVfx(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    widget.onVfxChanged?.call();
  }

  Widget _buildEffectCard(String key, String title, String subtitle) {
    final data = Map<String, dynamic>.from(_vfxCfg[key] ?? {});
    final enabled = data['en'] == true;
    final intensity = (data['intensity'] ?? 0.4).toDouble();
    final color = data['color'] ?? 0xFF7C3AED;
    final speed = (data['speed'] ?? 1.0).toDouble();
    final hasSpeed = key == 'sweep' || key == 'breath';
    final hasColor = key != 'sweep';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[200])),
            subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            value: enabled,
            activeColor: Colors.purple[300],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            onChanged: (v) => _updateEffect(key, 'en', v),
          ),
          if (enabled) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSlider('强度', intensity, (v) => _updateEffect(key, 'intensity', v)),
                  if (hasSpeed)
                    _buildSlider('速度', speed, (v) => _updateEffect(key, 'speed', v), min: 0.2, max: 3.0),
                  if (hasColor)
                    _buildColorRow(color, (c) => _updateEffect(key, 'color', c)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged, {double min = 0.0, double max = 1.0}) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[400]))),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            activeColor: Colors.purple[300],
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text('${(value * 100).round()}%',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ),
      ],
    );
  }

  Widget _buildColorRow(int current, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('颜色 ', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ...SettingsPage._vfxColors.entries.map((e) => GestureDetector(
            onTap: () => onChanged(e.value),
            child: Container(
              width: 28, height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(e.value),
                border: Border.all(
                  color: current == e.value ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(child: Text(e.key, style: const TextStyle(fontSize: 12))),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _updateEffect(String key, String field, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    _vfxCfg[key] ??= <String, dynamic>{};
    (_vfxCfg[key] as Map<String, dynamic>)[field] = value;
    await prefs.setString('vfx_cfg', jsonEncode(_vfxCfg));
    widget.onVfxChanged?.call();
    setState(() {});
  }

  Widget _vfxSwitch(String title, String subtitle, String key, bool defaultVal) {
    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance().then((p) => p.getBool(key) ?? defaultVal),
      builder: (context, snap) {
        final value = snap.data ?? defaultVal;
        return SwitchListTile(
          title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[200])),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          value: value,
          activeColor: Colors.purple[300],
          onChanged: (v) => _toggleVfx(key, v),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('psn_id');
    await prefs.remove('steam_id');
    await prefs.remove('psn_npsso');
    setState(() {
      _savedPsnId = '';
      _savedSteamId = '';
      _savedNpsso = '';
      _psnCtrl.clear();
      _steamCtrl.clear();
      _npssoCtrl.clear();
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
    _npssoCtrl.dispose();
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
        // NPSSO login (manual once per user)
        if (_savedPsnId.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '🔐 PSN 登录凭证',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber[300]),
          ),
          const SizedBox(height: 4),
          Text(
            '从浏览器登录 PSN 后抓取 NPSSO cookie，仅需一次',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _npssoCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '粘贴 NPSSO 令牌',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _savedNpsso.isNotEmpty
                        ? Icon(Icons.check_circle, color: Colors.green[400], size: 20)
                        : null,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _npssoLoading ? null : _loginPsn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _npssoLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_savedNpsso.isNotEmpty ? '已登录' : '登录'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.help_outline, color: Colors.grey[500], size: 20),
                onPressed: _showNpssoGuide,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (_savedNpsso.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                '✅ 已登录，游戏数据通过 PSN API 直连',
                style: TextStyle(fontSize: 11, color: Colors.green[400]),
              ),
            ),
        ],
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
        // ── VFX Settings ──
        Text('✨ 特效设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300])),
        const SizedBox(height: 10),
        _vfxSwitch('封面模糊', '游戏封面毛玻璃效果', 'vfx_blur', true),
        _vfxSwitch('水晶玻璃统计条', '统计栏毛玻璃+边框发光', 'vfx_glass', true),
        SwitchListTile(
          title: const Text('🎬 Steam 动态背景'),
          subtitle: const Text('当前游戏 Steam 预告片作为背景'),
          value: _videoBg,
          activeColor: Colors.purple[300],
          onChanged: (v) async {
            await SharedPreferences.getInstance().then((p) => p.setBool('video_bg', v));
            setState(() => _videoBg = v);
            widget.onVfxChanged?.call();
          },
        ),
        const SizedBox(height: 6),
        Text('🎨 封面特效自定义',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
        const SizedBox(height: 8),
        _buildEffectCard('crystal', '🔮 水晶光晕', '径向渐变彩色光晕'),
        _buildEffectCard('neon', '💜 霓虹边框', '多层发光边框环绕卡片'),
        _buildEffectCard('sweep', '✨ 光扫', '一道白光来回扫过'),
        _buildEffectCard('breath', '🫁 呼吸光晕', '卡片外围光晕明暗呼吸'),
        const SizedBox(height: 30),
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

// ── VFX Painters ──
class _SweepPainter extends CustomPainter {
  final double time;
  final double intensity;
  _SweepPainter({required this.time, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final x = (time % 2.0) < 1.0
        ? (time % 2.0) * size.width * 1.4
        : (2.0 - (time % 2.0)) * size.width * 1.4;
    final sweepW = size.width * 0.3;
    final rect = Rect.fromLTWH(x - sweepW / 2, 0, sweepW, size.height);
    final gradient = LinearGradient(
      colors: [
        Colors.white.withOpacity(0),
        Colors.white.withOpacity(0.1 * intensity),
        Colors.white.withOpacity(0.35 * intensity),
        Colors.white.withOpacity(0.1 * intensity),
        Colors.white.withOpacity(0),
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant _SweepPainter old) =>
      old.time != time || old.intensity != intensity;
}

class _NeonBorderPainter extends CustomPainter {
  final Color color;
  final double intensity;
  final double time;
  _NeonBorderPainter({required this.color, required this.intensity, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size, const Radius.circular(16),
    );
    for (int i = 3; i >= 0; i--) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.0 + i * 2.5) * intensity
        ..color = color.withOpacity((0.06 + i * 0.08) * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(rrect, paint);
    }
    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * intensity
      ..color = color.withOpacity(0.7 * intensity));
  }

  @override
  bool shouldRepaint(covariant _NeonBorderPainter old) =>
      old.color != color || old.intensity != intensity || old.time != time;
}
