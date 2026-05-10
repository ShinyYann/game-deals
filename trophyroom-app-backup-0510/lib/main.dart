import 'dart:async';
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
import 'services/steam_client.dart';
import 'services/switch_client.dart';
import 'xhh_psn_client.dart';
import 'services/switch_service.dart';
import 'services/deals_service.dart';
import 'models/switch_game.dart';
import 'pages/browser_page.dart';
import 'pages/browser_tab_page.dart';
import 'pages/info_summary_page.dart';
import 'pages/pending_approval_page.dart';
import 'pages/admin_panel_page.dart';
import 'pages/pokedex_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'widgets/trophy_icon.dart';
import 'widgets/particle_engine.dart';
import 'widgets/effect_card.dart';
import 'services/widget_updater.dart';
import 'services/update_service.dart';
import 'services/auth_service.dart';
import 'services/auth_admin_service.dart';
import 'services/cookie_isolation.dart';
import 'pages/login_page.dart';
import 'services/proxy_service.dart';

void main() {
  runApp(const TrophyRoomApp());
  // 初始化桌面小组件（不阻塞 UI）
  WidgetUpdater.init();
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
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      final loggedIn = await AuthService.isLoggedIn();
      if (!mounted) return;

      Widget? destination;
      if (loggedIn) {
        final creds = await AuthService.loadToken();
        if (creds.token != null && creds.token!.isNotEmpty && creds.username != null && creds.username!.isNotEmpty) {
          final status = await AuthAdminService.getUserStatus(creds.token!);
          if (status == 'pending' && creds.username!.toLowerCase() != 'shinyyann') {
            destination = PendingApprovalPage(username: creds.username!, token: creds.token!);
          }
        }
        destination ??= const HomePage();
      } else {
        destination = const AuthGate();
      }

      // 预拉代理域名列表
      _preloadProxyDomains();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination!,
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
    });
  }

  /// 预拉代理域名列表到缓存（不阻塞 UI）
  void _preloadProxyDomains() {
    ProxyService.fetchDomains().then((domains) {
      BrowserTabPage.proxyDomains = domains;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('proxy_domains_cache', json.encode(domains));
        prefs.setInt('proxy_domains_cache_time', DateTime.now().millisecondsSinceEpoch);
      });
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
              // ── 标题文字 ──
              Opacity(
                opacity: ((t - 0.2) * 4).clamp(0.0, 1.0),
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
              const SizedBox(height: 16),
              // ── Logo 图片 + 轮廓流光 ──
          AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) {
              final t = (_ctrl.value * 2.5) % 1.0;
              return Container(
                constraints: const BoxConstraints(
                  maxWidth: 280,
                  maxHeight: 200,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/logo/logo_yann_design.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
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

/// 登录/注册网关 — 没登录显示登录页，登录后回到首页
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return LoginPage(
      onLoginSuccess: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
    );
  }
}


/// 合并游戏辅助类
class _MergedGame {
  final String source; // 'psn' | 'steam' | 'switch'
  final Map<String, dynamic> data;
  _MergedGame({required this.source, required this.data});
}

/// 提取标准化的末次游玩时间戳（毫秒，越大越近）
int _lastPlayedTimestamp(Map<String, dynamic> data, String source) {
  if (source == 'psn') {
    final lp = data['last_played']?.toString() ?? 
              data['last_play_date']?.toString() ?? '';
    if (lp.isEmpty) return 0;
    try {
      return DateTime.parse(lp).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  } else if (source == 'steam') {
    final rtime = (data['rtime_last_played'] ?? 0) as int;
    return rtime * 1000;
  } else {
    // Switch: last_played 是中文相对时间，如 "1天前"、"2小时前"
    final lp = (data['last_played'] ?? '').toString();
    if (lp.isEmpty) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    // 解析中文相对时间 → 近似时间戳
    final patterns = {
      r'刚刚':                           const Duration(minutes: 1),
      r'(\d+)\s*分钟前': const Duration(minutes: 1),
      r'(\d+)\s*小时前': const Duration(hours: 1),
      r'(\d+)\s*天前':   const Duration(days: 1),
      r'(\d+)\s*周前':   const Duration(days: 7),
      r'(\d+)\s*个月前': const Duration(days: 30),
      r'(\d+)\s*年前':   const Duration(days: 365),
    };
    for (final entry in patterns.entries) {
      final match = RegExp(entry.key).firstMatch(lp);
      if (match != null) {
        int n = 1;
        if (match.groupCount >= 1 && match.group(1) != null) {
          n = int.tryParse(match.group(1)!) ?? 1;
        }
        final dur = entry.value * n;
        return now - dur.inMilliseconds;
      }
    }
    return 0; // 无法解析 → 归零
  }
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentTab = 0;
  String _netStatus = '检测中...';
  bool _netChecked = false;
  late AnimationController _animCtrl;
  late Animation<double> _titleSlide;
  late AnimationController _scanCtrl;
  bool _animDone = false;
  Set<String> _activeEffects = {}; // 全成就特效开关
  Map<String, double> _effectIntensity = {}; // 特效强度
  List<Map<String, dynamic>> _deals = [];
  String _dealsStatus = '';
  String _platform = 'all';
  String _newlowFilter = 'all'; // sub-filter within 新史低: all/psn/steam/switch
  late final WebViewController _psnWebCtrl;
  bool _psnWebLoading = true;
  String _psnId = '';
  String _steamId = '';
  bool _accountsLoaded = false;
  Timer? _pingTimer;
  Timer? _heartbeatTimer;
  bool _backgroundMode = false;

  void _startPing() {
    _pingTimer?.cancel();
    // 首次启动后 5 秒发心跳，之后每 5 分钟一次
    Future.delayed(const Duration(seconds: 5), _doPing);
    _pingTimer = Timer.periodic(const Duration(minutes: 5), (_) => _doPing());
  }

  Future<void> _doPing() async {
    final t = await AuthService.loadToken();
    if (t.token != null && t.token!.isNotEmpty) {
      AuthService.ping(token: t.token!);
    }
  }

  // ═══════════════════════════════════════════════
  // App 生命周期
  // ═══════════════════════════════════════════════

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundMode = true;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _backgroundMode = false;
      _startHeartbeat();
    }
  }

  // ═══════════════════════════════════════════════
  // 心跳（ping auth server，更新在线状态）
  // ═══════════════════════════════════════════════

  void _startHeartbeat() {
    // 心跳已通过 _startPing() 的 5 分钟定时处理，无需额外 heartbeat
  }
  String _error = '';
  Map<String, dynamic>? _cachedHomeData;
  Map<String, dynamic>? _steamData;
  Map<String, dynamic>? _steamBadges;
  bool _steamLoading = false;
  List<SwitchGame> _switchGames = [];
  bool _switchLoaded = false;
  String? _expandedGameId;
  Map<String, List<dynamic>> _gameTrophies = {};
  Map<String, bool> _expandedLoading = {};
  static const _apiBase = 'http://8.153.97.56';

  /// Steam 图片走服务器代理（绕过 GFW）
  static String _proxyImage(String originalUrl) {
    if (originalUrl.isEmpty) return '';
    return '$_apiBase/api/proxy/image?url=${Uri.encodeComponent(originalUrl)}';
  }
  Map<String, List<dynamic>> _steamAchievements = {};
  bool _filterPlaytime = false;  // Steam 只看有游玩时间的
  bool _guideBookmarksExpanded = false;  // 攻略页收藏夹展开
  bool _filter100pct = false;    // Steam 只看全成就的
  bool _summaryExpanded = false; // 汇总卡详情展开
  Map<String, dynamic>? _steamRecentGames;
  // ── Switch 小黑盒 ──
  List<String> _switchAccountIds = [];
  int _switchActiveIndex = 0;
  Map<String, dynamic>? _switchPlayData;
  bool _switchPlayLoading = false;
  String? _switchPlayError;
  // ── PageView 切换 ──
  int _platformTab = 0; // 0=汇总, 1=PSN, 2=Steam
  late final PageController _platformPageCtrl;

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
    _platformPageCtrl = PageController();
    _initPSNWebView();
    // 每隔 5 分钟发一次心跳
    _startPing();
    WidgetsBinding.instance.addObserver(this);
    _checkNetwork();
    _loadAccounts();
    _checkUpdate();
  }

  /// 检查更新
  void _checkUpdate() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final update = await UpdateService.checkUpdate();
      if (!mounted || update == null) return;
      if (!mounted) return;
      _showUpdateDialog(update);
    });
  }

  void _showUpdateDialog(AppUpdateInfo update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        double progress = 0;
        bool downloading = false;
        String status = '发现新版本 ${update.versionName}';
        return StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Text('🚀', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text('发现新版本', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('v${update.versionName}', style: const TextStyle(color: Color(0xFF66C0F4), fontSize: 16)),
              const SizedBox(height: 12),
              if (update.changelog.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(update.changelog,
                    style: TextStyle(fontSize: 13, color: Colors.grey[300], height: 1.5)),
                ),
              const SizedBox(height: 16),
              if (downloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: null, // 不确定进度 → 旋转动画
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66C0F4)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(status,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
              if (!downloading)
                Text(status, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
            actions: [
              TextButton(
                onPressed: downloading ? null : () => Navigator.of(ctx).pop(),
                child: Text('稍后再说', style: TextStyle(color: Colors.grey[500])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66C0F4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: downloading
                    ? null
                    : () {
                        setDialogState(() {
                          downloading = true;
                          status = '正在打开浏览器...';
                        });
                        UpdateService.downloadAndInstall(
                          apkUrl: update.apkUrl,
                        ).then((success) {
                          if (!ctx2.mounted) return;
                          if (success) {
                            Navigator.of(ctx2).pop();
                          } else {
                            final err = UpdateService.getLastError();
                            setDialogState(() {
                              downloading = false;
                              status = err.isNotEmpty ? '下载失败: $err' : '下载失败，请重试';
                            });
                          }
                        });
                      },
                child: Text(downloading ? '正在打开...' : '立即更新'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animCtrl.dispose();
    _scanCtrl.dispose();
    _platformPageCtrl.dispose();
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
    // 1. 优先从服务器拉取实时数据
    try {
      final serverData = await DealsService.fetchAll();
      if (serverData.isNotEmpty) {
        setState(() {
          _deals = serverData;
          _netStatus = '✅ 在线';
          _dealsStatus = '${serverData.length} 款折扣游戏';
          _netChecked = true;
        });
        return;
      }
    } catch (_) {}

    // 备选: 服务器本地数据源（逐个平台抓）
    final platforms = [
      ('steam_deals.json', 'steam'),
      ('psn_hk_deals.json', 'psn'),
      ('nintendo_s_deals.json', 'switch'),
    ];
    List<Map<String, dynamic>> allDeals = [];

    for (final (file, plat) in platforms) {
      try {
        final resp = await http
            .get(Uri.parse('http://8.153.97.56/deals/$file'))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final body = json.decode(resp.body);
          if (body is Map && body['deals'] is List) {
            for (final item in body['deals']) {
              if (item is! Map) continue;
              allDeals.add({
                'img': item['image']?.toString() ?? '',
                'name': item['name']?.toString() ?? '?',
                'price': item['current_price']?.toString() ?? '',
                'original': item['original_price']?.toString() ?? '',
                'discount': item['discount']?.toString() ?? '',
                'platform': plat,
                'url': item['url']?.toString() ?? '',
                'video_url': item['video_url']?.toString() ?? '',
              });
            }
          }
        }
      } catch (_) {}
    }

    if (allDeals.isNotEmpty) {
      setState(() {
        _deals = allDeals;
        _netStatus = '✅ 在线';
        _dealsStatus = '${allDeals.length} 款游戏（在线）';
        _netChecked = true;
      });
      return;
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

  static const _appVersion = 'v80';

  Future<void> _checkChangelog(SharedPreferences prefs, String steam) async {
    final seen = prefs.getString('changelog_seen') ?? '';
    if (seen == _appVersion) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Row(children: [
            const Text('🆕 ', style: TextStyle(fontSize: 22)),
            Text(_appVersion, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ]),
          content: const Text(
            '🎨 重写五种全成就特效 (v45 视觉)\n'
            '🌈 新增七彩粒子 — 铺满卡片呼吸运动\n'
            '💎 棱光升级 — 8 色 SweepGradient 追光\n'
            '✨ 星辉扫光 — 平滑色泽不再跳\n'
            '📊 每个特效独立强度滑块',
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                prefs.setString('changelog_seen', _appVersion);
              },
              child: const Text('知道了', style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final psn = prefs.getString('psn_id') ?? '';
    final steam = prefs.getString('steam_id') ?? '';
    final switchRaw = prefs.getString('switch_token') ?? '';
    final switchIds = switchRaw.isNotEmpty ? switchRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : <String>[];
    // 加载全成就特效偏好
    final effectStr = prefs.getString('platinum_effects');
    final effects = effectStr != null && effectStr.isNotEmpty
        ? effectStr.split(',').toSet()
        : <String>{};
    // 加载特效强度
    final intensityStr = prefs.getString('platinum_intensity');
    final intensity = <String, double>{};
    if (intensityStr != null && intensityStr.isNotEmpty) {
      for (final p in intensityStr.split(',')) {
        final kv = p.split(':');
        if (kv.length == 2) {
          intensity[kv[0]] = double.tryParse(kv[1]) ?? 0.7;
        }
      }
    }

    // 加载本地缓存的 PSN 数据（秒开，v2 格式来自小黑盒）
    final cachedPsn = prefs.getString('cache_psn_data');
    if (cachedPsn != null && psn.isNotEmpty) {
      try {
        final parsed = json.decode(cachedPsn) as Map<String, dynamic>;
        // 兼容性检查：v2 格式必须有 _v 字段
        if (parsed['_v'] == 2) {
          _cachedHomeData = parsed;
        }
        // 旧版本缓存自动丢弃，走全新拉取
      } catch (_) {}
    }
    // 加载本地缓存的 Steam 数据（秒开）
    final cachedSteam = prefs.getString('cache_steam_data');
    bool needSteamRefresh = false;
    if (cachedSteam != null && steam.isNotEmpty) {
      try {
        _steamData = json.decode(cachedSteam) as Map<String, dynamic>;
        // 缓存缺少新字段（头像框等）→ 后台静默刷新
        if (_steamData != null && !_steamData!.containsKey('avatar_frame')) {
          needSteamRefresh = true;
        }
      } catch (_) {}
    }
    setState(() {
      _psnId = psn;
      _steamId = steam;
      _switchAccountIds = switchIds;
      _activeEffects = effects;
      _effectIntensity = intensity;
      _accountsLoaded = true;
    });
    // 检查更新日志
    _checkChangelog(prefs, steam);
    // 如果有 Steam ID，自动拉取 Steam 数据
    if (steam.isNotEmpty && (_steamData == null || needSteamRefresh)) {
      _fetchSteamData();
    }
    // 如果有 PSN ID，自动拉取 PSN 数据
    if (psn.isNotEmpty) {
      _fetchFullPsnData().then((data) {
        if (mounted) {
          setState(() => _cachedHomeData = data);
          _pushWidgetData();
        }
      });
    }
    // 如果有 Switch token，自动拉取游玩数据
    if (_switchAccountIds.isNotEmpty) {
      _fetchSwitchPlayData();
    }
  }



  /// 推送首页数据到桌面小组件
  void _pushWidgetData() {
    final psnData = _cachedHomeData;
    final steamD = _steamData;
    final switchD = _switchPlayData;
    // 统计 PSN 奖杯
    String psnTotal = '-', psnPlat = '-';
    if (psnData != null) {
      // 兼容不同数据源字段名
      final total = psnData['total_trophies'] ?? psnData['total'] ?? psnData['trophy_count'] ?? '';
      final plat = psnData['platinum'] ?? psnData['platinum_count'] ?? '';
      if (total is int || total is String && total.toString().isNotEmpty) {
        psnTotal = total.toString();
        psnPlat = (plat is int ? plat : 0).toString();
      }
    }
    // 统计 Steam
    String steamGames = '-', steamAch = '-';
    if (steamD != null) {
      final games = steamD['games'] as List?;
      if (games != null && games.isNotEmpty) {
        steamGames = games.length.toString();
      }
      // 尝试拼接全成就统计
      final total = steamD['total_achievements'] ?? steamD['achievements_total'] ?? '';
      final unlocked = steamD['unlocked_achievements'] ?? steamD['achievements_unlocked'] ?? '';
      if (total is int && total > 0 && unlocked is int) {
        steamAch = '$unlocked/$total';
      }
    }
    // 统计 Switch
    String switchGames = '-', switchHours = '-';
    if (switchD != null) {
      final games = switchD['games'] as List?;
      if (games != null && games.isNotEmpty) {
        switchGames = games.length.toString();
      }
      final hours = switchD['total_hours'] ?? switchD['playtime_hours'] ?? '';
      if (hours is num && hours > 0) {
        switchHours = hours.toStringAsFixed(0);
      }
    }
    WidgetUpdater.pushHomeData(
      psnTrophies: psnTotal,
      psnPlat: psnPlat,
      steamGames: steamGames,
      steamAchievements: steamAch,
      switchGames: switchGames,
      switchHours: switchHours,
    );
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
        const InfoSummaryPage(),
        _buildGuide(),
        const BrowserTabPage(),
        SettingsPage(
          onSyncCompleted: () {
            _loadAccounts();
          },
          onNpssoChanged: () async {
            await _loadAccounts();
            _loadSwitchGames();
            if (mounted) {
              setState(() { _cachedHomeData = null; });
            }
          },
          onSteamChanged: () async {
            await _loadAccounts();  // 重读 _steamId
            if (mounted) {
              setState(() {
                _steamData = null;
                _steamAchievements.clear();

              });
            }
          },
        ),
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
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: '信息'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '攻略'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: '浏览'),
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
            Text('请先去设置页绑定账号',
              style: TextStyle(fontSize: 16, color: Colors.grey[400])),
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

    return Column(
      children: [
        // ── 页面内容 + 粒子背景 ──
        Expanded(
          child: Builder(builder: (ctx) {
            final hasBoth = _psnId.isNotEmpty && _steamId.isNotEmpty;
            final hasSwitch = _switchAccountIds.isNotEmpty;
            final pages = <Widget>[];
            if (hasBoth) { pages.add(_buildSummaryPage()); pages.add(_buildPsnPage()); pages.add(_buildSteamPage()); }
            else if (_psnId.isNotEmpty) pages.add(_buildPsnPage());
            else if (_steamId.isNotEmpty) pages.add(_buildSteamPage());
            if (hasSwitch) pages.add(_buildSwitchPlayPage());
            final tabCount = pages.length;

            return Stack(children: [
              // 粒子背景
              Builder(builder: (ctx) {
                final both = _psnId.isNotEmpty && _steamId.isNotEmpty;
                final tab = _platformTab;
                final isPsn = both ? (tab == 1) : _psnId.isNotEmpty;
                final isMixed = both && tab == 0;
                final isSwitch = tab == (hasBoth ? 3 : hasSwitch ? (_psnId.isNotEmpty || _steamId.isNotEmpty ? 1 : 0) : 0);
                if (isSwitch) {
                  return const ParticleEngine(config: ParticleConfig(
                    colors: [Color(0xFFE60012), Color(0xFF00A0E9), Color(0xFFFFD700)],
                    mode: ParticleMode.shimmer, count: 60, maxRadius: 3, tailLength: 3));
                }
                return isMixed
                  ? const ParticleEngine(config: ParticleConfig(
                      colors: [Color(0xFF9B59B6), Color(0xFF3A7BD5), Color(0xFFE8D5FF), Color(0xFF8EC8F2)],
                      mode: ParticleMode.shimmer, count: 70, maxRadius: 3.5, tailLength: 4))
                  : isPsn
                    ? const ParticleEngine(config: ParticleConfig(
                        colors: [Color(0xFF9B59B6), Color(0xFF6C3A9E), Color(0xFFD4A5FF)],
                        mode: ParticleMode.rise, count: 55, maxRadius: 3, tailLength: 3))
                    : const ParticleEngine(config: ParticleConfig(
                        colors: [Color(0xFF3A7BD5), Color(0xFF1A5276), Color(0xFF8EC8F2)],
                        mode: ParticleMode.float, count: 60, maxRadius: 3, tailLength: 2));
              }),
              // 深色渐变遮罩
              IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [const Color(0xFF0A0A12).withOpacity(0.4), const Color(0xFF0A0A12).withOpacity(0.85)])))),
              // 页面内容 — 纯滑动，无 Tab 栏
              tabCount > 1
                ? Positioned.fill(child: PageView(
                      controller: _platformPageCtrl,
                      onPageChanged: (i) => setState(() => _platformTab = i),
                      children: pages,
                    ))
                : pages.first,
            ]);
          }),
        ),
      ],
    );
  }

  /// 汇总页 = 统计卡 + 全游戏列表（PSN+Steam合并，按最近活跃排序）
  Widget _buildSummaryPage() {
    final psnData = _cachedHomeData;
    final psnGames = (psnData?['games'] as List?) ?? [];
    final steamData = _steamData;
    final steamGamesRaw = (steamData != null && !steamData.containsKey('error'))
        ? (steamData['games'] as List? ?? [])
        : [];

    // 合并 PSN + Steam 到统一列表，标记来源
    final List<_MergedGame> merged = [];

    for (final g in psnGames) {
      final game = Map<String, dynamic>.from(g as Map);
      merged.add(_MergedGame(source: 'psn', data: game));
    }
    for (final g in steamGamesRaw) {
      final game = Map<String, dynamic>.from(g as Map);
      // 过滤 Steam 软件/工具类（Wallpaper Engine, RPG Maker, 桌面增强等）
      final sName = (game['name'] ?? '').toString().toLowerCase();
      const steamSoftware = [
        'wallpaper engine', 'rpg maker', 'mydockfinder',
        'lossless scaling', 'soundpad', '3dmark',
        'wallpaper', 'desktop', 'benchmark',
      ];
      final isSoftware = steamSoftware.any((kw) => sName.contains(kw));
      if (!isSoftware) {
        merged.add(_MergedGame(source: 'steam', data: game));
      }
    }
    // 合并 Switch 游戏
    final switchGamesForRibbon = (_switchPlayData?['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final g in switchGamesForRibbon) {
      merged.add(_MergedGame(source: 'switch', data: g));
    }

    // 应用筛选（PSN 白金 = 全成就；Switch 无成就系统需排除）
    if (_filterPlaytime || _filter100pct) {
      merged.removeWhere((m) {
        if (_filter100pct) {
          if (m.source == 'steam') {
            // Steam：达成全成就
            final total = _safeInt(m.data['achievements_total']);
            final unlocked = _safeInt(m.data['achievements_unlocked']);
            return total == 0 || unlocked < total;
          } else if (m.source == 'psn') {
            // PSN：有白金 = 等同于全成就
            return (m.data['platinum'] ?? 0) == 0;
          } else {
            // Switch：没有成就/奖杯系统，全成就模式下移除
            return true;
          }
        }
        if (_filterPlaytime) {
          // 有游玩数据模式：只过滤 Steam 无时长的
          if (m.source != 'steam') return false;
          return (m.data['playtime_forever'] ?? 0) == 0;
        }
        return false;
      });
    }

    // 排序：谁最近玩过谁在最上边（看 last_played）
    merged.sort((a, b) {
      final tA = _lastPlayedTimestamp(a.data, a.source);
      final tB = _lastPlayedTimestamp(b.data, b.source);
      if (tA > 0 && tB > 0) return tB.compareTo(tA);
      if (tA > 0) return -1;
      if (tB > 0) return 1;
      // 都没时间戳 → 有游玩/奖杯记录的优先
      final pA = _safeInt(a.data['playtime_forever']);
      final pB = _safeInt(b.data['playtime_forever']);
      if (pA > 0 && pB > 0) return pB - pA;
      if (pA > 0) return -1;
      if (pB > 0) return 1;
      final trA = _safeInt(a.data['platinum']) + _safeInt(a.data['gold']);
      final trB = _safeInt(b.data['platinum']) + _safeInt(b.data['gold']);
      if (trA > 0 && trB > 0) return trB - trA;
      if (trA > 0) return -1;
      if (trB > 0) return 1;
      return 0;
    });

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _buildSummaryCard(),

        // 筛选条（汇总页始终可见）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            _filterChip('全部', !_filter100pct && !_filterPlaytime, () {
              setState(() { _filter100pct = false; _filterPlaytime = false; });
            }),
            const SizedBox(width: 6),
            _filterChip('全成就', _filter100pct, () {
              setState(() { _filter100pct = !_filter100pct; _filterPlaytime = false; });
            }),
            const SizedBox(width: 6),
            _filterChip('有数据', _filterPlaytime, () {
              setState(() { _filterPlaytime = !_filterPlaytime; _filter100pct = false; });
            }),
            const Spacer(),
            if (_filter100pct || _filterPlaytime)
              Text('已筛选', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),

        // ── 全游戏列表（合并排序） ──
        if (merged.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('🎮 所有游戏 (${merged.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          ...merged.map((m) {
            if (m.source == 'psn') {
              final gameId = m.data['game_id']?.toString() ?? '';
              final isExpanded = _expandedGameId == gameId;
              return _buildExpandableGameCard(m.data, isExpanded: isExpanded);
            } else if (m.source == 'switch') {
              return _buildSwitchCompactCard(m.data);
            } else {
              return _buildCompactSteamCard(m.data);
            }
          }),
        ],
      ],
    );
  }

  /// 🎨 最近游戏封面横幅轮播（Netflix+Pulse 风格）
  /// Steam 游戏卡（紧凑版 — 用于汇总页，点击弹窗看成就）
  Widget _buildCompactSteamCard(Map<String, dynamic> game) {
    final name = (game['name'] ?? '???').toString();
    final playtime = _safeInt(game["playtime_forever"]);
    final iconUrl = game['img_icon_url']?.toString() ?? '';
    final headerUrl = game['header_image']?.toString() ?? '';
    final coverUrl = iconUrl.isNotEmpty ? iconUrl : headerUrl;
    final achTotal = game['achievements_total'] as int? ?? 0;
    final achUnlocked = game['achievements_unlocked'] as int? ?? 0;
    final appId = (game['app_id'] ?? '').toString();
    final cr = achTotal > 0 ? (achUnlocked / achTotal) : 0.0;

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (appId.isNotEmpty) ? () => _toggleSteamAchievements(appId) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
              // 50x50 图标
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50, height: 50,
                  child: coverUrl.isNotEmpty
                      ? Image.network(_proxyImage(coverUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _steamPlaceholderIcon())
                      : _steamPlaceholderIcon(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(SteamClient.translateGameName(name),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.access_time, size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('${playtime ~/ 60}h', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    if (achTotal > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.emoji_events, size: 13, color: Color(0xFF66C0F4)),
                      const SizedBox(width: 3),
                      Text('$achUnlocked/$achTotal', style: const TextStyle(fontSize: 12, color: Color(0xFF66C0F4))),
                  ],
                ]),
                if (achTotal > 0) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: cr, minHeight: 3,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66C0F4)),
                    ),
                  ),
                ],
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Steam', style: TextStyle(fontSize: 9, color: Color(0xFF66C0F4))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _steamPlaceholderIcon() {
    return Container(
      color: Colors.grey[850],
      child: const Icon(Icons.sports_esports, size: 24, color: Colors.grey),
    );
  }

  /// Switch 游戏紧凑卡（汇总页）
  Widget _buildSwitchCompactCard(Map<String, dynamic> game) {
    final name = (game['name'] ?? '???').toString();
    final hours = (game['total_hours'] as num?)?.toDouble() ?? 0;
    final coverUrl = game['cover_url']?.toString() ?? '';
    final lastPlayed = game['last_played'] ?? '';

    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFE60012).withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSwitchGameDetail(game),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50, height: 50,
                child: coverUrl.isNotEmpty
                    ? Image.network(coverUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _steamPlaceholderIcon())
                    : _steamPlaceholderIcon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('${hours.toStringAsFixed(1)}h', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  if (lastPlayed.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.history, size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Flexible(child: Text(lastPlayed.toString(), style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE60012).withOpacity(0.2), borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Switch', style: TextStyle(fontSize: 9, color: Color(0xFFE60012))),
            ),
          ]),
        ),
      ),
    );
  }



  /// 主页汇总卡（PSN + Steam 合体）
  Widget _buildSummaryCard() {
    // PSN 统计
    final psnData = _cachedHomeData;
    int psnTrophies = 0, psnPlatinum = 0, psnGold = 0;
    if (psnData != null) {
      psnTrophies = _safeInt(psnData["total_trophies"]);
      psnPlatinum = _safeInt(psnData["platinum"]);
      psnGold = _safeInt(psnData["gold"]);
    }

    // Steam 统计
    int steamGames = 0, steamAchUnlocked = 0, steamAchTotal = 0, steamPlaytime = 0;
    int steam100pct = 0; // 全成就游戏数
    if (_steamData != null && !_steamData!.containsKey('error')) {
      final games = _steamData!['games'] as List? ?? [];
      steamGames = games.length;
      for (final g in games) {
        int t = _safeInt(g["playtime_forever"]);
        steamPlaytime += t;
        int aTotal = _safeInt(g["achievements_total"]);
        int aUnlocked = _safeInt(g["achievements_unlocked"]);
        if (t > 0) steamAchUnlocked += aUnlocked;
        steamAchTotal += aTotal;
        if (aTotal > 0 && aUnlocked >= aTotal) steam100pct++;
      }
    }

    // Switch 统计
    final switchData = _switchPlayData;
    int switchGames = 0;
    double switchHours = 0;
    String switchPrice = '0';
    if (switchData != null && !switchData.containsKey('error')) {
      switchGames = switchData['total_games'] ?? (switchData['games'] as List?)?.length ?? 0;
      switchHours = (switchData['total_hours'] as num?)?.toDouble() ?? 0;
      switchPrice = (switchData['total_price'] ?? '0').toString();
    }

    // 全平台总时长（PSN + Steam + Switch）
    double totalAllHours = steamPlaytime / 60.0 + switchHours;
    if (psnData != null) {
      final psnGamesForTime = (psnData['games'] as List?) ?? [];
      for (final g in psnGamesForTime) {
        final pd = g['play_duration'];
        if (pd == null) continue;
        if (pd is num) {
          totalAllHours += pd.toDouble() / 60.0;
        } else {
          // ISO 8601: PT23H30M15S → 23.5h
          final s = pd.toString();
          final h = RegExp(r'(\d+)H').firstMatch(s);
          final m = RegExp(r'(\d+)M').firstMatch(s);
          if (h != null) totalAllHours += double.tryParse(h.group(1)!) ?? 0;
          if (m != null) totalAllHours += (double.tryParse(m.group(1)!) ?? 0) / 60.0;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.purple.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _statTile('🏆', 'PSN 奖杯', '$psnTrophies', const Color(0xFF4ECDC4)),
                _statTile('👑', '白金', '$psnPlatinum', const Color(0xFFB8D8D8)),
                _statTile('🎮', 'Steam 游戏', '$steamGames', const Color(0xFF66C0F4)),
                _statTile('🏅', 'Steam 成就', '$steamAchUnlocked / $steamAchTotal', const Color(0xFFFFD700)),
              ],
            ),
            if (switchGames > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                _statTile('🕹️', 'Switch 游戏', '$switchGames', const Color(0xFFE60012)),
                _statTile('⏱️', '总时长', '${totalAllHours.toStringAsFixed(0)}h', const Color(0xFF00A0E9)),
                _statTile('💰', 'Switch游戏价值', '¥$switchPrice', const Color(0xFFFFD700)),
                const Expanded(child: SizedBox()),
              ]),
            ],
            const SizedBox(height: 4),
            // 展开/收起按钮
            GestureDetector(
              onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_summaryExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: Colors.grey[500]),
                Text(_summaryExpanded ? '收起' : '展开详情', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ]),
            ),
            // 展开详情
            if (_summaryExpanded) ...[
              const SizedBox(height: 10),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              _buildSummaryDetail(psnData, _steamData, _switchPlayData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryDetail(Map<String, dynamic>? psnData, Map<String, dynamic>? steamData, Map<String, dynamic>? switchData) {
    final psnGames = (psnData?['games'] as List?) ?? [];
    final steamGamesRaw = (_steamData != null && !_steamData!.containsKey('error'))
        ? (_steamData!['games'] as List? ?? []).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    // 过滤 Steam 软件/工具类
    final steamGames = steamGamesRaw.where((g) {
      final sName = (g['name'] ?? '').toString().toLowerCase();
      const sw = ['wallpaper engine', 'rpg maker', 'mydockfinder', 'lossless scaling', 'soundpad', '3dmark'];
      return !sw.any((kw) => sName.contains(kw));
    }).toList();

    final switchGames = (switchData?['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final switchTotalHours = (switchData?['total_hours'] as num?)?.toDouble() ?? 0;
    final switchTotalPrice = switchData?['total_price'] ?? '0';

    // PSN 白金游戏
    final platinumGames = psnGames.where((g) => (g['platinum'] ?? 0) > 0).toList();
    final psnPlatinumCount = psnData?['platinum'] ?? platinumGames.length;
    // Steam 全成就游戏
    final perfectGames = steamGames.where((g) {
      int t = _safeInt(g["achievements_total"]);
      int u = _safeInt(g["achievements_unlocked"]);
      return t > 0 && u >= t;
    }).toList();

    // PSN 金银铜统计
    int totalGold = 0, totalSilver = 0, totalBronze = 0;
    for (final g in psnGames) {
      totalGold += (g['gold'] ?? 0) as int;
      totalSilver += (g['silver'] ?? 0) as int;
      totalBronze += (g['bronze'] ?? 0) as int;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── PSN 奖杯分布 ──
      if (psnGames.isNotEmpty) ...[
        Text('🏆 PSN 奖杯分布', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[300])),
        SizedBox(height: 6),
        Row(children: [
          _miniStat('👑', '白金', psnPlatinumCount, const Color(0xFFB8D8D8)),
          _miniStat('🥇', '金', totalGold, const Color(0xFFFFD700)),
          _miniStat('🥈', '银', totalSilver, const Color(0xFFC0C0C0)),
          _miniStat('🥉', '铜', totalBronze, const Color(0xFFCD7F32)),
        ]),
        if (platinumGames.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showAllGamesPopup('🏆 PSN 白金游戏', platinumGames.cast<Map<String, dynamic>>(), 'psn'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFB8D8D8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB8D8D8).withOpacity(0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('👑 白金游戏 (${platinumGames.length})', style: TextStyle(fontSize: 12, color: const Color(0xFFB8D8D8).withOpacity(0.9))),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 14, color: const Color(0xFFB8D8D8).withOpacity(0.5)),
              ]),
            ),
          ),
        ],
      ],

      // ── Steam 全成就 ──
      if (steamGames.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('🎮 Steam 全成就', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[300])),
        SizedBox(height: 6),
        if (perfectGames.isEmpty)
          Text('暂无全成就游戏', style: TextStyle(fontSize: 11, color: Colors.grey[600]))
        else
          GestureDetector(
            onTap: () => _showAllGamesPopup('⭐ Steam 全成就游戏', perfectGames.cast<Map<String, dynamic>>(), 'steam'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('⭐ 全成就游戏 (${perfectGames.length})', style: TextStyle(fontSize: 12, color: const Color(0xFFFFD700).withOpacity(0.9))),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 14, color: const Color(0xFFFFD700).withOpacity(0.5)),
              ]),
            ),
          ),
      ],

      // ── Switch 游玩概览 ──
      if (switchGames.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('🕹️ Switch 游玩概览', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[300])),
        const SizedBox(height: 6),
        Row(children: [
          _miniStat('🎮', '游戏', switchGames.length, const Color(0xFFE60012)),
          _miniStat('⏱️', '总时长', switchTotalHours.toInt(), const Color(0xFF00A0E9)),
          _miniStat('💰', '价值 ¥', int.tryParse(switchTotalPrice.toString()) ?? 0, const Color(0xFFFFD700)),
        ]),
      ],
    ]);
  }

  /// 🏆 弹出全部游戏列表（白金/全成就）
  void _showAllGamesPopup(String title, List<Map<String, dynamic>> games, String source) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Icon(Icons.close, color: Colors.grey[500], size: 20),
          ),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: games.length,
            itemBuilder: (_, i) {
              final g = games[i];
              final name = source == 'psn'
                  ? (g['title'] ?? g['name'] ?? '?').toString()
                  : SteamClient.translateGameName((g['name'] ?? '???').toString());
              final sub = source == 'psn'
                  ? '👑 白金 | 🥇${g['gold'] ?? 0} 🥈${g['silver'] ?? 0} 🥉${g['bronze'] ?? 0}'
                  : '⭐ ${g['achievements_unlocked'] ?? 0}/${g['achievements_total'] ?? 0} 成就';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  )),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statTile(String icon, String label, String count, Color color) {
    return Expanded(
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ]),
    );
  }

  Widget _miniStat(String icon, String label, int count, Color color) {
    return Expanded(
      child: Column(children: [
        Text('$icon $count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? Colors.purple[700] : Colors.grey[850],
          border: Border.all(color: active ? Colors.purple[400]! : Colors.grey[700]!, width: 0.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.grey[500])),
      ),
    );
  }

  Widget _buildPlatformTabs() {
    final hasBoth = _psnId.isNotEmpty && _steamId.isNotEmpty;
    final tabs = <String>[];
    if (hasBoth) { tabs.add('📊 汇总'); }
    if (_psnId.isNotEmpty) { tabs.add('🏆 PSN'); }
    if (_steamId.isNotEmpty) { tabs.add('🎮 Steam'); }
    if (_switchAccountIds.isNotEmpty) { tabs.add('🎮 Switch'); }

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) => _platformTabBtn(tabs[i], i)),
      ),
    );
  }

  Widget _platformTabBtn(String label, int idx) {
    final active = _platformTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _platformPageCtrl.animateToPage(idx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic);
          setState(() => _platformTab = idx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.purple[700] : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? Colors.white : Colors.grey[500])),
        ),
      ),
    );
  }

  Widget _buildPsnPage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _cachedHomeData != null
          ? Future.value(_cachedHomeData)
          : _fetchFullPsnData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _cachedHomeData == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final effectiveData = (snapshot.hasData && !snapshot.hasError)
            ? snapshot.data : (_cachedHomeData ?? snapshot.data);
        if (snapshot.hasError || !snapshot.hasData) {
          if (effectiveData == null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text('加载失败: ${snapshot.error ?? "未知错误"}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ]),
            );
          }
        }
        final data = effectiveData!;
        final psnId = data['psn_id']?.toString() ?? '';
        final nickname = data['nickname']?.toString() ?? psnId;
        final avatar = data['avatar']?.toString() ?? '';
        final level = data['level']?.toString() ?? '?';
        final platinum = data['platinum'] ?? 0;
        final gold = data['gold'] ?? 0;
        final silver = data['silver'] ?? 0;
        final bronze = data['bronze'] ?? 0;
        final totalGames = data['total_games'] ?? 0;
        final totalHours = data['total_hours'] ?? 0;
        final totalTrophies2 = data['total_trophies'] ?? 0;
        final completionRate = data['completion_rate'] ?? 0;
        final tPlatinum = (platinum as num).toInt();
        final tGold = (gold as num).toInt();
        final tSilver = (silver as num).toInt();
        final tBronze = (bronze as num).toInt();
        final tTotalTrophies = (totalTrophies2 as num).toInt();
        final games = data['games'] as List<dynamic>? ?? [];
        final hasData = psnId.isNotEmpty;

        return RefreshIndicator(
          color: Colors.purple[300],
          onRefresh: () async {
            _expandedGameId = null;
            _gameTrophies.clear();
            _expandedLoading.clear();
            _cachedHomeData = null;
            final data = await _fetchFullPsnData();
            setState(() => _cachedHomeData = data);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hasData) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2D1B69)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      // PSN 头像
                      if (avatar.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.network(avatar, width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.person, color: Colors.grey))),
                          ),
                        ),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        if (nickname != psnId)
                          Text(psnId, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('Lv $level', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                    ]),
                    const SizedBox(height: 16),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: 0.75, minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _trophyStat('🏆', '$tPlatinum', '白金', Colors.cyan[300]!),
                      _trophyStat('🥇', '$tGold', '金', Colors.amber[400]!),
                      _trophyStat('🥈', '$tSilver', '银', Colors.grey[400]!),
                      _trophyStat('🥉', '$tBronze', '铜', Colors.orange[400]!),
                    ]),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _statItem('🎮', '$totalGames', '游戏'),
                        _statItem('⏱️', '${totalHours}h', '总时长'),
                        _statItem('🏆', '$tTotalTrophies', '奖杯'),
                        _statItem('📊', '$tPlatinum', '白金'),
                      ])),
                  ]),
                ),
                const SizedBox(height: 20),
              ],
              if (hasData)
                Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: Text('📋 我的游戏 (${games.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              if (!hasData)
                Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text("数据加载失败", style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("请检查网络连接，在「设置」页绑定 PSN 账号", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentTab = 3),
                    icon: Icon(Icons.settings, size: 18, color: Colors.purple[300]),
                    label: Text("前往设置", style: TextStyle(color: Colors.purple[300]))),
                ]))),
              if (games.isEmpty && hasData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.games_outlined, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text(_error.isNotEmpty ? _error : '暂无游戏数据', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                )
              else
                ...games.map((g) {
                  final game = Map<String, dynamic>.from(g as Map);
                  final gameId = game['game_id']?.toString() ?? '';
                  final isExpanded = _expandedGameId == gameId;
                  return _buildExpandableGameCard(game, isExpanded: isExpanded);
                }),
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

  Widget _fallbackAvatar(String avatar, double size) {
    if (avatar.isNotEmpty) {
      return Image.network(_proxyImage(avatar), width: size, height: size, fit: BoxFit.cover);
    }
    return Container(width: size, height: size, color: Colors.grey[850],
      child: const Icon(Icons.person, size: 28, color: Colors.grey));
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
    final playtime = game['playtime_desc']?.toString() ?? '';
    final lastPlay = game['last_play_date']?.toString() ?? '';

    final hasPlatinum = (platinum as num) > 0;
    final cardChild = Column(
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
                                          : platform == 'PS3'
                                              ? Colors.blueGrey[800]
                                              : platform == 'PS Vita' || platform == 'PSV'
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
                        // Playtime
                        if (playtime.isNotEmpty)
                          Row(children: [
                            Icon(Icons.timer_outlined, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(playtime, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                            if (lastPlay.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.history, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(child: Text(lastPlay, style: TextStyle(fontSize: 10, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                            ],
                          ]),
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
    );

    final showPlatinumEffect = hasPlatinum;

    if (showPlatinumEffect) {
      return EffectCardWrapper(
        effects: _activeEffects,
        intensity: _effectIntensity,
        child: Card(
          color: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          child: cardChild as Widget,
        ),
      );
    }

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
      child: cardChild as Widget,
    );
  }

  Widget _buildTrophyRow(Map<String, dynamic> trophy) {
    final type = trophy['type']?.toString().toLowerCase() ?? '';
    final name = trophy['name']?.toString() ?? '';
    final description = trophy['description']?.toString() ?? '';
    final earned = trophy['earned'] == true;
    final iconUrl = trophy['icon_url']?.toString() ?? '';
    final isPlatinum = type == 'platinum';

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
          // Trophy icon — 优先官网图，兜底用 TrophyIcon 手绘
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
                errorBuilder: (_, __, ___) => TrophyIcon(type: type, size: 28).builder(
                  earned ? null : Colors.grey[700]!,
                  earned ? null : BlendMode.saturation,
                ),
              ),
            )
          else
            TrophyIcon(
              type: type,
              size: 28,
              opacity: earned ? 1.0 : 0.35,
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
    // 优先 psnine_id（心得查得到），否则用小黑盒 id
    final trophyId = (trophy['psnine_id']?.toString().isNotEmpty == true
        ? trophy['psnine_id']?.toString()
        : trophy['id']?.toString()) ?? '';

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

      // 从 psn_cid (NPWR50887_00) 提取数字 ID (50887) 给 psnine 用
      final gameNum = RegExp(r'(\d+)').firstMatch(gameId)?.group(1);

      // 小黑盒 + psnine 并行拉取，保证 psnine_id 在显示前就位
      final xhhFuture = _fetchXhhTrophies(gameId);
      final psnineFuture = (gameNum != null)
          ? _fetchPsnineTrophies(gameNum)
          : Future.value(<Map<String, dynamic>>[]);

      final results = await Future.wait([xhhFuture, psnineFuture]);
      var trophies = results[0] as List<Map<String, dynamic>>;
      final psnineList = results[1] as List<Map<String, dynamic>>;

      // 用 psnine 数据按名匹配，注入 psnine_id + 覆盖日文名
      if (psnineList.isNotEmpty) {
        final psnineByName = <String, Map<String, dynamic>>{};
        for (final pt in psnineList) {
          final name = (pt['name'] ?? '').toString().trim();
          if (name.isNotEmpty) psnineByName[name] = pt;
        }
        int matched = 0;
        for (final t in trophies) {
          final xName = (t['name'] ?? '').toString().trim();
          final matchedPsnine = psnineByName[xName];
          if (matchedPsnine != null) {
            t['psnine_id'] = matchedPsnine['id']?.toString() ?? '';
            matched++;
          }
        }
        // 未完全匹配时按序号兜底（不同语言的情况，如命运石之门）
        if (matched < trophies.length && psnineList.length == trophies.length) {
          for (int i = 0; i < trophies.length; i++) {
            final t = trophies[i];
            if (!t.containsKey('psnine_id') || (t['psnine_id'] ?? '').toString().isEmpty) {
              final pt = psnineList[i];
              t['psnine_id'] = pt['id']?.toString() ?? '';
              matched++;
            }
            // 覆盖日文名为中文
            final xName = (t['name'] ?? '').toString();
            final pName = (psnineList[i]['name'] ?? '').toString();
            if (_isJapaneseName(xName) && !_isJapaneseName(pName)) {
              t['name'] = pName;
              t['description'] = psnineList[i]['description']?.toString() ?? t['description'];
            }
          }
        }
        print('[PsnineID] matched $matched/${trophies.length}');
      } else {
        // 小黑盒失败 → psnine 兜底（此时 psnineList 来自 _fetchPsnineTrophies 的错误捕获，为空）
        // 兜底重试：直接调 psnine
        if (trophies.isEmpty && gameNum != null) {
          try {
            final psnine = PsnineClient(_psnId);
            trophies = await psnine
                .fetchGameTrophies(gameNum)
                .timeout(const Duration(seconds: 8));
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _gameTrophies[gameId] = trophies;
          _expandedLoading[gameId] = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchXhhTrophies(String gameId) async {
    try {
      final xhh = XhhPsnClient(_psnId);
      final raw = await xhh.fetchGameTrophies(gameId)
          .timeout(const Duration(seconds: 8));
      final rawList = (raw['list'] as List?) ?? [];
      return rawList.map((t) {
        final tMap = t as Map<String, dynamic>;
        return {
          'id': tMap['t_id']?.toString() ?? '',
          'name': tMap['trophy_name']?.toString() ?? '',
          'description': tMap['trophy_desc']?.toString() ?? '',
          'type': tMap['type']?.toString() ?? 'bronze',
          'icon_url': tMap['trophy_icon']?.toString() ?? '',
          'earned': tMap['finish'] == 1,
          'earned_date': tMap['earned_time']?.toString() ?? '',
          'earned_timestamp': tMap['earned_timestamp'] ?? 0,
          'earned_rate': (tMap['earned_rate'] ?? 0).toString(),
        };
      }).toList();
    } catch (e) {
      print('[XHH trophies] failed: $e');
      return [];
    }
  }

  /// 检测奖杯名是否含日文假名（不含中文汉字的纯日文）
  bool _isJapaneseName(String s) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').hasMatch(s);
  }

  Future<List<Map<String, dynamic>>> _fetchPsnineTrophies(String gameNum) async {
    try {
      // 走服务器代理（国内手机直连 psnine 可能超时）
      final url = 'http://8.153.97.56/api/psn_game_detail?game_id=$gameNum&uid=$_psnId';
      final resp = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final trophies = (data['trophies'] as List?) ?? [];
        return trophies.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('[Psnine proxy] failed: $e');
    }
    // 兜底：直连 psnine
    try {
      final psnine = PsnineClient(_psnId);
      return await psnine.fetchGameTrophies(gameNum)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      print('[Psnine direct] failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchFullPsnData() async {
    if (_psnId.isEmpty || _accountsLoaded == false) {
      return {'psn_id': '', 'games': []};
    }

    // 1. 小黑盒 PSN API 主力数据源
    try {
      final xhh = XhhPsnClient(_psnId);
      final data = await xhh.fetchAll().timeout(const Duration(seconds: 12));
      if (data['games'] is List && (data['games'] as List).isNotEmpty) {
        print('[PSN XHH] ✅ ${(data['games'] as List).length} games, ${data['total_hours']}h');
        _cachedHomeData = data;
        _savePsnCache(data);
        return data;
      }
    } catch (e) {
      print('[PSN XHH] failed: $e');
    }

    return {'psn_id': _psnId, 'error': '加载失败', 'games': []};
  }

  /// 缓存数据到服务器
  Future<void> _savePsnCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      data['_v'] = 2;
      await prefs.setString('cache_psn_data', json.encode(data));
    } catch (_) {}
  }

  Future<void> _saveSteamCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_steam_data', json.encode(data));
    } catch (_) {}
  }

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

  /// Steam 游戏名称中文化
  static final Map<String, String> _steamGameNameMap = {
    'ELDEN RING': '艾尔登法环',
    'Cyberpunk 2077': '赛博朋克 2077',
    'Monster Hunter Wilds': '怪物猎人 荒野',
    'Monster Hunter World': '怪物猎人 世界',
    'Monster Hunter Rise': '怪物猎人 崛起',
    'Red Dead Redemption 2': '荒野大镖客 救赎2',
    'Grand Theft Auto V': '给他爱5',
    'Baldur\'s Gate 3': '博德之门3',
    'Black Myth: Wukong': '黑神话 悟空',
    'Stellar Blade': '剑星',
    'Persona 5 Royal': '女神异闻录5 皇家版',
    'Persona 4 Golden': '女神异闻录4 黄金版',
    'NieR: Automata': '尼尔 机械纪元',
    'Hades': '哈迪斯',
    'Hades II': '哈迪斯2',
    'Hollow Knight': '空洞骑士',
    'Celeste': '蔚蓝',
    'Stardew Valley': '星露谷物语',
    'The Witcher 3': '巫师3',
    'Dark Souls III': '黑暗之魂3',
    'Sekiro': '只狼',
    'God of War': '战神',
    'Horizon Zero Dawn': '地平线 零之黎明',
    'Horizon Forbidden West': '地平线 西之绝境',
    'Ghost of Tsushima': '对马岛之魂',
    'Spider-Man Remastered': '漫威蜘蛛侠 重置版',
    'Spider-Man Miles Morales': '漫威蜘蛛侠 迈尔斯',
    'Final Fantasy VII Remake Intergrade': '最终幻想7 重制版 Intergrade',
    'Final Fantasy XV': '最终幻想15',
    'Final Fantasy XIV': '最终幻想14',
    'Terraria': '泰拉瑞亚',
    'Stray': '流浪猫',
    'Disco Elysium': '极乐迪斯科',
    'Portal 2': '传送门2',
    'Half-Life 2': '半条命2',
    'Left 4 Dead 2': '求生之路2',
    'Team Fortress 2': '军团要塞2',
    'Counter-Strike 2': '反恐精英2',
    'Dota 2': '刀塔2',
    'Path of Exile 2': '流放之路2',
    'Warframe': '星际战甲',
    'Destiny 2': '命运2',
    'Palworld': '幻兽帕鲁',
    'Valheim': '英灵神殿',
    'Satisfactory': '幸福工厂',
    'Factorio': '异星工厂',
    'RimWorld': '边缘世界',
    'Dyson Sphere Program': '戴森球计划',
    'Warhammer: Vermintide 2': '战锤：末日鼠疫2',
    'Oxygen Not Included': '缺氧',
    'Wallpaper Engine': '壁纸引擎',
    'Sid Meier Civilization VI': '文明6',
    'Sid Meier\'s Civilization VI': '文明6',
    'Sid Meiers Civilization VI': '文明6',
    'Among Us': '太空狼人杀',
    'Phasmophobia': '恐鬼症',
    'Risk of Rain 2': '雨中冒险2',
    'Dead Cells': '死亡细胞',
    'Slay the Spire': '杀戮尖塔',
    'Vampire Survivors': '吸血鬼幸存者',
    'Brotato': '土豆兄弟',
    'Cuphead': '茶杯头',
    'Deep Rock Galactic': '深岩银河',
    'Battlefield 1': '战地1',
    'Battlefield V': '战地5',
    'Battlefield 4': '战地4',
    'The Binding of Isaac Rebirth': '以撒的结合 重生',
    'The Binding of Isaac': '以撒的结合',
    'Don\'t Starve Together': '饥荒 联机版',
    'Don\'t Starve': '饥荒',
    'This War of Mine': '这是我的战争',
    'Frostpunk': '冰汽时代',
    'Divinity Original Sin 2': '神界 原罪2',
    'Metro Exodus': '地铁 离去',
    'Subnautica': '深海迷航',
    'Sid Meier\'s Civilization V': '文明5',
    'Cities: Skylines': '城市 天际线',
  };

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

  /// 从服务器获取 Steam 数据
  Future<Map<String, dynamic>> _fetchSteamData() async {
    if (_steamId.isEmpty) return {};
    setState(() => _steamLoading = true);
    try {
      final client = SteamClient(_steamId);
      final profile = await client.fetchProfile();
      final gamesData = await client.fetchGames();
      final result = {
        ...profile,
        ...gamesData,
        'platform': 'steam',
      };
      setState(() {
        _steamData = result;
        _steamLoading = false;
      });
      _pushWidgetData();
      // 存本地缓存
      _saveSteamCache(result);
      // 后台拉取最近游玩
      _loadSteamRecentOnly();
      // 后台拉取徽章
      _fetchSteamBadges();
      return result;
    } catch (e) {
      print('[Steam] fetch error: $e');
      setState(() {
        _steamData = {'error': e.toString()};
        _steamLoading = false;
      });
      return {};
    }
  }

  Future<void> _fetchSteamBadges() async {
    if (_steamId.isEmpty) return;
    try {
      final url = '$_apiBase/api/steam/badges?steamid=$_steamId';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic> && data['badges'] != null) {
          setState(() => _steamBadges = data);
        }
      }
    } catch (e) {
      print('[Steam badges] fetch error: $e');
    }
  }

  Widget _buildSteamPage() {
    if (_steamId.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sports_esports, size: 64, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text('未绑定 Steam 账号', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('去设置页输入你的 Steam ID', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => setState(() => _currentTab = 3),
          icon: Icon(Icons.settings, size: 18, color: Colors.blue[300]),
          label: Text("前往设置", style: TextStyle(color: Colors.blue[300]))),
      ]));
    }
    if (_steamLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_steamData == null) {
      _fetchSteamData();
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_steamData!.containsKey('error')) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.warning_amber, size: 48, color: Colors.orange[300]),
        const SizedBox(height: 12),
        Text('Steam 数据加载失败', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
        const SizedBox(height: 8),
        Text('请确保服务器已配置 Steam API Key', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]));
    }
    final data = _steamData!;
    final name = data['name'] ?? 'Unknown';
    final avatar = data['avatar'] ?? '';
    final avatarFrame = (data['avatar_frame'] as Map<String, dynamic>?) ?? {};
    final avatarFrameUrl = avatarFrame['image']?.toString() ?? '';
    final animatedAvatar = (data['animated_avatar'] as Map<String, dynamic>?) ?? {};
    final animatedAvatarUrl = animatedAvatar['image']?.toString() ?? '';
    final profileBg = (data['profile_background'] as Map<String, dynamic>?) ?? {};
    final profileBgUrl = profileBg['image']?.toString() ?? '';
    final profileBgMovie = profileBg['movie_mp4_small']?.toString() ?? '';
    final level = data['level'] ?? 0;
    final gameCount = data['game_count'] ?? 0;
    final games = data['games'] as List? ?? [];
    int totalPlaytime = 0, gamesWithTime = 0;
    for (final g in games) {
      final t = _safeInt(g["playtime_forever"]);
      totalPlaytime += t;
      if (t > 0) gamesWithTime++;
    }

    return RefreshIndicator(
      color: const Color(0xFF66C0F4),
      onRefresh: () async {
        setState(() { _steamData = null; _steamAchievements.clear(); _steamRecentGames = null; });
        await _fetchSteamData();
      },
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Steam 档案卡
        _buildSteamProfileCard(avatar, avatarFrameUrl, animatedAvatarUrl, profileBgUrl, profileBgMovie, name, level, _steamId, gameCount, totalPlaytime, gamesWithTime),

        const SizedBox(height: 16),

        // ── Steam 徽章 ──
        if (_steamBadges != null && (_steamBadges!['badges'] as List?)!.isNotEmpty)
          _buildSteamBadgesCard(),

        const SizedBox(height: 12),

        // ── Steam 最近游玩 ──
        _buildSteamRecentSection(),

        const SizedBox(height: 16),

        // 筛选条
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            _filterChip('全部', !_filter100pct && !_filterPlaytime, () {
              setState(() { _filter100pct = false; _filterPlaytime = false; });
            }),
            const SizedBox(width: 6),
            _filterChip('全成就', _filter100pct, () {
              setState(() { _filter100pct = !_filter100pct; _filterPlaytime = false; });
            }),
            const SizedBox(width: 6),
            _filterChip('有数据', _filterPlaytime, () {
              setState(() { _filterPlaytime = !_filterPlaytime; _filter100pct = false; });
            }),
            const Spacer(),
            if (_filter100pct || _filterPlaytime)
              Text('已筛选: ${_filteredGames(games).length} 款', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),

        if (games.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text('📋 Steam 游戏 (${_filteredGames(games).length}${_filterPlaytime ? " | 有数据" : _filter100pct ? " | 全成就" : ""})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
        ..._filteredGames(games).map((g) => _buildSteamGameCard(Map<String, dynamic>.from(g as Map))),
      ]),
    );
  }

  /// Steam 档案卡（头像 + 统计）
  /// Steam 官方头像框颜色 (基于等级) — 备用，当无点数商店框时使用
  static List<Color> _steamAvatarFrame(int level) {
    if (level >= 200) return [const Color(0xFFD4AF37), const Color(0xFFF2E6B6), const Color(0xFFC8A42E)];
    if (level >= 100) return [const Color(0xFFCB3850), const Color(0xFFE8758A), const Color(0xFFA82A40)];
    if (level >= 50)  return [const Color(0xFF70489A), const Color(0xFF9B6FBF), const Color(0xFF522F7A)];
    if (level >= 40)  return [const Color(0xFFC46A32), const Color(0xFFE8985A), const Color(0xFFA0522A)];
    if (level >= 30)  return [const Color(0xFFBAA03B), const Color(0xFFDCC66A), const Color(0xFF8B7A2A)];
    if (level >= 20)  return [const Color(0xFF5C8A47), const Color(0xFF82B268), const Color(0xFF3E6A2E)];
    if (level >= 10)  return [const Color(0xFF42748F), const Color(0xFF669BB8), const Color(0xFF2C5068)];
    return [const Color(0xFF5D5D5D), const Color(0xFF8A8A8A), const Color(0xFF3D3D3D)];
  }

  Widget _buildSteamProfileCard(String avatar, String avatarFrameUrl, String animatedAvatarUrl, String profileBgUrl, String profileBgMovie, String name, int level, String steamId, int gameCount, int totalPlaytime, int gamesWithTime) {
    final avatarSize = 56.0;
    final hasFrame = avatarFrameUrl.isNotEmpty;
    final hasBg = profileBgUrl.isNotEmpty;
    final framePadding = hasFrame ? 14.0 : 6.0;
    final containerSize = avatarSize + framePadding + 4;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Steam 个人资料背景（视频动画 + 静态兜底） ──
          if (hasBg)
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [
                    const Color(0xFF0D1B2A).withOpacity(0.55),
                    const Color(0xFF0D1B2A).withOpacity(0.2),
                    const Color(0xFF0D1B2A).withOpacity(0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(rect),
                blendMode: BlendMode.darken,
                child: profileBgMovie.isNotEmpty
                    ? _SteamBgVideo(videoUrl: profileBgMovie, fallbackImageUrl: profileBgUrl)
                    : Image.network(profileBgUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
          // 无背景时的默认渐变
          if (!hasBg)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A3A5C), Color(0xFF0D1B2A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          // 内容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (avatar.isNotEmpty)
            // ── Steam 头像 + 点数商店头像框 ──
            SizedBox(
              width: containerSize,
              height: containerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 头像 — 动画头像优先（Steam Points Shop 动态头像 GIF）
                  ClipOval(
                    child: animatedAvatarUrl.isNotEmpty
                        ? Image.network(_proxyImage(animatedAvatarUrl), width: avatarSize, height: avatarSize,
                            fit: BoxFit.cover, gaplessPlayback: true,
                            errorBuilder: (_,__,___) => _fallbackAvatar(avatar, avatarSize))
                        : Image.network(_proxyImage(avatar), width: avatarSize, height: avatarSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => _fallbackAvatar(avatar, avatarSize)),
                  ),
                  // 点数商店头像框（叠在头像上面，比头像大一圈露出装饰边）
                  if (hasFrame)
                    Image.network(
                      _proxyImage(avatarFrameUrl),
                      width: containerSize,
                      height: containerSize,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
              if (level > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF66C0F4), Color(0xFF3A7BD5)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Lv.$level', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text('Steam ID: $steamId', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('🎮', '$gameCount', '游戏'),
            _statItem('⏱️', '${(totalPlaytime / 60).toStringAsFixed(1)} h', '时长'),
            _statItem('✅', '$gamesWithTime', '玩过'),
          ])),
      ],
    ), // Column
  ), // Padding
  ], // Stack children
), // Stack
); // Container
  }

  /// Steam 最近游玩
  Widget _buildSteamBadgesCard() {
    final badges = (_steamBadges!['badges'] as List).cast<Map<String, dynamic>>();
    final level = _steamBadges!['level'] ?? '?';
    final totalXp = _steamBadges!['total_xp'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF0D1F35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF66C0F4).withAlpha(60)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            const Icon(Icons.workspace_premium, color: Color(0xFF66C0F4), size: 20),
            const SizedBox(width: 8),
            const Text('Steam 徽章', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const Spacer(),
            Text('Lv.$level · ${_formatNumber(totalXp)} XP', style: TextStyle(fontSize: 12, color: Colors.blue[200])),
          ]),
        ),
        // Badge grid - horizontal scroll
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            itemCount: badges.length,
            itemBuilder: (ctx, i) {
              final b = badges[i];
              final icon = (b['icon'] as String?) ?? '';
              final name = (b['name_zh'] as String?) ?? (b['name'] as String?) ?? '';
              final lv = b['level'] ?? 0;
              final isGame = b['type'] == 'game';

              return GestureDetector(
                onTap: () => _showBadgeDetail(b),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(children: [
                    // Icon
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: isGame
                            ? const LinearGradient(colors: [Color(0xFF2A3F5F), Color(0xFF1A2F4F)])
                            : const LinearGradient(colors: [Color(0xFF3D5A3A), Color(0xFF2D4A2A)]),
                        border: Border.all(color: (isGame ? const Color(0xFF66C0F4) : const Color(0xFF90EE90)).withAlpha(40)),
                      ),
                      child: icon.isNotEmpty
                          ? Padding(padding: const EdgeInsets.all(4), child: Image.network(icon, fit: BoxFit.contain))
                          : Icon(isGame ? Icons.sports_esports : Icons.emoji_events, color: Colors.grey[600], size: 28),
                    ),
                    const SizedBox(height: 4),
                    // Name (Chinese)
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.grey[300])),
                    // Level
                    Text('Lv.$lv', style: TextStyle(fontSize: 9, color: Colors.blue[300], fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showBadgeDetail(Map<String, dynamic> badge) {
    final icon = (badge['icon'] as String?) ?? '';
    final name = (badge['name_zh'] as String?) ?? (badge['name'] as String?) ?? '';
    final nameEn = (badge['name'] as String?) ?? '';
    final lv = badge['level'] ?? 0;
    final lvName = (badge['level_name'] as String?) ?? '';
    final xp = badge['xp'] ?? 0;
    final unlocked = (badge['unlocked'] as String?) ?? '';
    final playtime = (badge['playtime'] as String?) ?? '';
    final isGame = badge['type'] == 'game';
    final cards = (badge['cards'] as List?)?.cast<String>() ?? [];
    final desc = (badge['desc_zh'] as String?) ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1B2838), Color(0xFF0F1923)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF66C0F4).withAlpha(50)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header: icon + name
            Row(children: [
              // Badge icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: isGame
                        ? [const Color(0xFF2A3F5F), const Color(0xFF1A2F4F)]
                        : [const Color(0xFF3D5A3A), const Color(0xFF2D4A2A)],
                  ),
                  border: Border.all(color: (isGame ? const Color(0xFF66C0F4) : const Color(0xFF90EE90)).withAlpha(80)),
                ),
                child: icon.isNotEmpty
                    ? Padding(padding: const EdgeInsets.all(6), child: Image.network(icon, fit: BoxFit.contain))
                    : Icon(isGame ? Icons.sports_esports : Icons.emoji_events, size: 32, color: Colors.grey[500]),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Chinese name
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                if (name != nameEn && nameEn.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2),
                    child: Text(nameEn, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                if (desc.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
              ])),
            ]),

            const SizedBox(height: 16),
            // Divider
            Container(height: 1, color: Colors.white.withAlpha(15)),
            const SizedBox(height: 12),

            // Badge info grid
            Row(children: [
              _badgeStatCol('等级', 'Lv.$lv', const Color(0xFF66C0F4)),
              _badgeStatCol('名称', lvName, const Color(0xFF90EE90)),
              _badgeStatCol('经验值', _formatNumber(xp), const Color(0xFFFFD700)),
            ]),

            if (unlocked.isNotEmpty || playtime.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white.withAlpha(15)),
              const SizedBox(height: 12),
              if (unlocked.isNotEmpty)
                _detailRow(Icons.lock_open, '解锁时间', unlocked),
              if (playtime.isNotEmpty)
                _detailRow(Icons.timer, '游玩时长', playtime),
            ],

            // Card images
            if (cards.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withAlpha(15)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.style, size: 16, color: Colors.blue[300]),
                const SizedBox(width: 6),
                Text('卡牌 (${cards.length}张)', style: TextStyle(fontSize: 13, color: Colors.blue[200])),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cards.length,
                  itemBuilder: (_, i) => Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                      color: const Color(0xFF1A2A3F),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(cards[i], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(foregroundColor: Colors.blue[300]),
                child: const Text('关闭'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _badgeStatCol(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      const SizedBox(height: 4),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
    ]));
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[300]))),
      ]),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1).replaceAll(r'.0', '')}k';
    }
    return n.toString();
  }

  Widget _buildSteamRecentSection() {
    if (_steamRecentGames == null) return const SizedBox.shrink();
    final recent = _steamRecentGames!['games'] as List? ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2838), Color(0xFF0F1922)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF66C0F4).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history, size: 16, color: Color(0xFF66C0F4)),
          const SizedBox(width: 6),
          Text('最近游玩 (${recent.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
        const SizedBox(height: 10),
        ...recent.take(5).map((g) {
          if (g is! Map) return const SizedBox.shrink();
          final appId = g['appid'] ?? '';
          final rName = SteamClient.translateGameName(g['name']?.toString() ?? '???');
          final playtime2weeks = (g['playtime_2weeks'] ?? 0) as int;
          final playtimeForever = _safeInt(g["playtime_forever"]);
          final rIcon = g['img_icon_url']?.toString() ?? '';
          final iconFull = rIcon.isNotEmpty
              ? 'https://media.steampowered.com/steamcommunity/public/images/apps/$appId/$rIcon'
              : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40, height: 40,
                  child: iconFull.isNotEmpty
                      ? Image.network(_proxyImage(iconFull), fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(color: Colors.grey[850], child: Icon(Icons.sports_esports, size: 18, color: Colors.grey[700])))
                      : Container(color: Colors.grey[850], child: Icon(Icons.sports_esports, size: 18, color: Colors.grey[700])),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('两周内 ${playtime2weeks ~/ 60}h · 总计 ${playtimeForever ~/ 60}h',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ]),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  void _loadSteamRecentOnly() async {
    if (_steamRecentGames != null || _steamId.isEmpty) return;
    try {
      final client = SteamClient(_steamId);
      final recent = await client.fetchRecentGames();
      if (mounted) {
        setState(() { _steamRecentGames = recent; });
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// Steam 游戏过滤
  /// 安全转换数值（防服务器返回字符串崩掉）
  static int _safeInt(dynamic val) {
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    if (val is num) return val.toInt();
    return 0;
  }

  List<dynamic> _filteredGames(List<dynamic> games) {
    if (_filterPlaytime) {
      return games.where((g) => _safeInt(g['playtime_forever']) > 0).toList();
    }
    if (_filter100pct) {
      return games.where((g) {
        int total = _safeInt(g['achievements_total']);
        int unlocked = _safeInt(g['achievements_unlocked']);
        return total > 0 && unlocked >= total;
      }).toList();
    }
    return games;
  }

  Widget _buildSteamGameCard(Map<String, dynamic> game) {
    final appId = game['app_id'] ?? '';
    final name = (game['name'] ?? '???').toString();
    final playtime = _safeInt(game['playtime_forever']);
    final imgUrl = game['header_image'] ?? game['img_icon_url'] ?? '';
    final achTotal = _safeInt(game['achievements_total']);
    final achUnlocked = _safeInt(game['achievements_unlocked']);
    final cr = achTotal > 0 ? (achUnlocked / achTotal) : 0.0;
    final isPerfect = achTotal > 0 && achUnlocked >= achTotal;

    final card = Card(
      color: const Color(0xFF16202E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isPerfect ? 12 : 12),
        side: BorderSide(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _toggleSteamAchievements(appId.toString()),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imgUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: double.infinity, height: 87,
                color: Colors.grey[900],
                child: Image.network(_proxyImage(imgUrl), fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(
                    color: Colors.grey[850],
                    child: Center(child: Icon(Icons.sports_esports, size: 32, color: Colors.grey[700])))),
              ),
            ),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(SteamClient.translateGameName(name),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey[500]), const SizedBox(width: 4),
                Text('${playtime ~/ 60}h', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                if (achTotal > 0) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.emoji_events, size: 13, color: const Color(0xFF66C0F4)), const SizedBox(width: 4),
                  Text('$achUnlocked/$achTotal', style: TextStyle(fontSize: 12, color: const Color(0xFF66C0F4))),
                ],
              ]),
              if (achTotal > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: cr, minHeight: 3,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66C0F4)),
                  ),
                ),
              ],
            ])),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
          ])),
        ]),
      ),
    );

    return isPerfect
        ? EffectCardWrapper(effects: _activeEffects, intensity: _effectIntensity, child: card)
        : card;
  }

  Widget _buildSteamAchievementList(List<dynamic> achievements) {
    if (achievements.isEmpty) {
      return Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('该游戏无成就', style: TextStyle(fontSize: 13, color: Colors.grey[600]))));
    }
    final unlocked = achievements.where((a) => a['achieved'] == true).length;
    return Padding(padding: const EdgeInsets.all(8), child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [
        Icon(Icons.emoji_events, size: 14, color: const Color(0xFF66C0F4)), const SizedBox(width: 6),
        Text('$unlocked / ${achievements.length}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        const Spacer(),
        Text('${(unlocked / achievements.length * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: const Color(0xFF66C0F4))),
      ])),
      ClipRRect(borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(value: unlocked / achievements.length, minHeight: 4,
          backgroundColor: Colors.white.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66C0F4)))),
      const SizedBox(height: 8),
      ...achievements.map((ach) {
        final achieved = ach['achieved'] == true;
        final displayName = SteamClient.translateAchievement(ach['display_name'] ?? ach['api_name'] ?? '');
        final desc = SteamClient.translateDescription(ach['description'] ?? '');
        final achIcon = achieved ? (ach['icon'] ?? '') : (ach['icon_gray'] ?? '');
        final globalPct = (ach['global_pct'] ?? 0).toDouble();
        final unlockTs = achieved ? (ach['unlock_time'] as int? ?? 0) : 0;
        final unlockDate = unlockTs > 0
            ? DateTime.fromMillisecondsSinceEpoch(unlockTs * 1000)
            : null;
        final unlockStr = unlockDate != null
            ? '${unlockDate.year}-${unlockDate.month.toString().padLeft(2, '0')}-${unlockDate.day.toString().padLeft(2, '0')}'
            : '';
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Row(children: [
          // 成就图标
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: achIcon.isNotEmpty
              ? Image.network(_proxyImage(achIcon), width: 36, height: 36, fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => _achPlaceholder(achieved))
              : _achPlaceholder(achieved),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayName, style: TextStyle(fontSize: 13, color: achieved ? Colors.grey[200] : Colors.grey[500], fontWeight: FontWeight.w600)),
            if (desc.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (unlockStr.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today, size: 10, color: Colors.grey[600]),
                const SizedBox(width: 3),
                Text(unlockStr, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ])),
          ])),
          if (globalPct > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(children: [
                Text('${globalPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: globalPct < 5 ? const Color(0xFFFFD700) : globalPct < 20 ? const Color(0xFF4ECDC4) : Colors.grey[500])),
                Text('全球', style: TextStyle(fontSize: 8, color: Colors.grey[600])),
              ]),
            ),
        ]));
      }),
    ]));
  }

  /// 成就图标占位
  Widget _achPlaceholder(bool achieved) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: achieved ? const Color(0xFF1A3A5C) : Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(achieved ? Icons.emoji_events : Icons.lock_outline,
        size: 16, color: achieved ? const Color(0xFF66C0F4) : Colors.grey[700]),
    );
  }

  /// Steam 成就弹窗 — 全量列表可滚动
  void _toggleSteamAchievements(String appId) async {
    // 获取游戏名
    String gameName = appId;
    if (_steamData != null) {
      final games = _steamData!['games'] as List? ?? [];
      for (final g in games) {
        if (g['app_id']?.toString() == appId) {
          gameName = SteamClient.translateGameName((g['name'] ?? appId).toString());
          break;
        }
      }
    }

    // 弹出底部加载弹窗（由弹窗自己判断有无成就）
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SteamAchievementSheet(
        steamId: _steamId,
        appId: appId,
        gameName: gameName,
        proxyImage: _proxyImage,
      ),
    );
  }

  String _translateSteamGameName(String name) {
    return SteamClient.translateGameName(name);
  }

  /// ───── Switch 家长控制 ─────

  List<Map<String, dynamic>> _allSwitchAccounts = [];

  Future<void> _fetchSwitchPlayData() async {
    if (_switchAccountIds.isEmpty) return;
    setState(() { _switchPlayLoading = true; _switchPlayError = null; });

    // 从服务器拉取所有账号（含新发现的）并更新本地列表
    try {
      final mainId = _switchAccountIds.join(',');
      final accounts = await SwitchClient.fetchAllAccounts(mainId);
      if (accounts.isEmpty) throw Exception('未找到 Switch 数据');

      // 更新本地 account_id 列表
      final newIds = accounts.map((a) => a['account_id'] as String).toList();
      if (newIds.join(',') != _switchAccountIds.join(',')) {
        _switchAccountIds = newIds;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('switch_token', newIds.join(','));
        if (_switchActiveIndex >= newIds.length) _switchActiveIndex = 0;
      }

      setState(() {
        _allSwitchAccounts = accounts;
        _switchPlayData = accounts[_switchActiveIndex.clamp(0, accounts.length - 1)];
        _switchPlayLoading = false;
      });
      _pushWidgetData();
    } catch (e) {
      setState(() {
        _switchPlayLoading = false;
        _switchPlayError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _buildSwitchPlayPage() {
    if (_switchPlayLoading && _switchPlayData == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE60012)));
    }

    if (_switchPlayError != null && _switchPlayData == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFE60012)),
          const SizedBox(height: 12),
          Text('加载失败', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 4),
          Text(_switchPlayError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchSwitchPlayData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE60012), foregroundColor: Colors.white),
          ),
        ]),
      ));
    }

    final data = _switchPlayData;
    if (data == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.sports_esports, size: 64, color: Color(0xFFE60012)),
        const SizedBox(height: 12),
        const Text('Nintendo Switch', style: TextStyle(color: Colors.white70, fontSize: 18)),
        const SizedBox(height: 8),
        Text('请先在设置页填写小黑盒用户 ID', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ]));
    }

    final games = (data['games'] as List? ?? []).cast<Map<String, dynamic>>();
    final totalHours = (data['total_hours'] as num?)?.toDouble() ?? 0;
    final userName = (data['user_name'] ?? 'Nintendo Switch').toString();
    final totalGamePrice = (data['total_price'] ?? '0').toString();
    final lastUpdate = (data['last_update'] ?? '').toString();
    final region = (data['region'] ?? '').toString();
    final showSwitch = _allSwitchAccounts.length > 1;

    return Column(children: [
      // 多账号切换器
      if (showSwitch)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.swap_horiz, size: 18, color: Colors.white38),
            const SizedBox(width: 4),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _switchActiveIndex.clamp(0, _allSwitchAccounts.length - 1),
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: List.generate(_allSwitchAccounts.length, (i) {
                    final a = _allSwitchAccounts[i];
                    var n = (a['user_name'] ?? '').toString();
                    if (n.isEmpty || n == '玩家None') n = '账号 ${i+1}';
                    return DropdownMenuItem(value: i, child: Text(n, style: const TextStyle(fontSize: 13)));
                  }),
                  onChanged: (i) {
                    if (i != null && i < _allSwitchAccounts.length) {
                      setState(() { _switchActiveIndex = i; _switchPlayData = _allSwitchAccounts[i]; });
                    }
                  },
                ),
              ),
            ),
          ]),
        ),
      // 主内容
      Expanded(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 头图卡片 ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE60012), Color(0xFF8B0000)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: data['avatar'] != null ? NetworkImage(data['avatar'] as String) : null,
                child: data['avatar'] == null ? const Icon(Icons.sports_esports, size: 28, color: Colors.white) : null,
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                if (region.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(region, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ),
              ])),
              if (lastUpdate.isNotEmpty)
                Text(lastUpdate, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 12),
          // ── 统计卡片 ──
          Row(children: [
            _switchStatCard('🎮', '${games.length}', '游戏数量'),
            const SizedBox(width: 8),
            _switchStatCard('⏱️', '${totalHours.toStringAsFixed(0)}h', '总时长'),
            const SizedBox(width: 8),
            _switchStatCard('💰', '¥$totalGamePrice', '游戏价值'),
          ]),
          const SizedBox(height: 16),
          // ── 游戏封面网格 ──
          if (games.isNotEmpty) ...[
            const Text('🎮 游戏库', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: games.length,
              itemBuilder: (ctx, i) {
                final g = games[i];
                final name = g['name'] ?? '???';
                final hours = (g['total_hours'] as num?)?.toDouble() ?? 0;
                final coverUrl = g['cover_url'] ?? '';
                return GestureDetector(
                  onTap: () => _showSwitchGameDetail(g),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: coverUrl.isNotEmpty
                              ? Image.network(coverUrl, width: double.infinity, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.white.withOpacity(0.05), child: const Icon(Icons.sports_esports, size: 32, color: Colors.white24)))
                              : Container(color: Colors.white.withOpacity(0.05), child: const Icon(Icons.sports_esports, size: 32, color: Colors.white24)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('${hours.toStringAsFixed(0)}h', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('暂无游戏数据', style: TextStyle(color: Colors.grey[600], fontSize: 14))),
            ),
        ],
      )),
    ]);
  }

  Widget _switchStatCard(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ]),
      ),
    );
  }

  void _showSwitchGameDetail(Map<String, dynamic> game) {
    final name = game['name'] ?? '???';
    final hours = (game['total_hours'] as num?)?.toDouble() ?? 0;
    final recentHours = (game['recent_hours'] as num?)?.toDouble() ?? 0;
    final lastPlayed = game['last_played'] ?? '';
    final coverUrl = game['cover_url'] ?? '';
    final bannerUrl = game['banner_url'] ?? '';
    final hasBanner = bannerUrl.isNotEmpty;
    final headerUrl = hasBanner ? bannerUrl : coverUrl;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 头图 — hasBanner 时用 banner，Switch 用封面放大
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: headerUrl.isNotEmpty
                  ? Container(
                      color: const Color(0xFF1A1D21),
                      child: Image.network(headerUrl,
                          width: double.infinity,
                          height: hasBanner ? 140 : 180,
                          fit: hasBanner ? BoxFit.cover : BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                              height: hasBanner ? 140 : 180,
                              color: const Color(0xFFE60012).withOpacity(0.2))))
                  : Container(height: 140, color: const Color(0xFFE60012).withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // 标题（Switch 用头图展示封面后不需要重复封面）
                if (hasBanner) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (coverUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(coverUrl, width: 72, height: 72, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    if (coverUrl.isNotEmpty) const SizedBox(width: 14),
                    Expanded(
                      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
                // 游戏名（Switch 无 banner 时）
                if (!hasBanner)
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                // 时长标签
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE60012), Color(0xFF8B0000)]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${hours.toStringAsFixed(1)} 小时', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  if (recentHours > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00A0E9), Color(0xFF0080CC)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('最近 ${recentHours.toStringAsFixed(1)}h', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                ]),
                const SizedBox(height: 20),
                // 详细数据
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    _switchDetailRow('🎮 总游玩时长', '${hours.toStringAsFixed(1)} 小时'),
                    if (recentHours > 0) _switchDetailRow('🕐 最近两周', '${recentHours.toStringAsFixed(1)} 小时'),
                    if (lastPlayed.isNotEmpty) _switchDetailRow('📅 最后游玩', lastPlayed),
                  ]),
                ),
                const SizedBox(height: 16),
                // 关闭按钮
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                    child: const Text('关闭'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _switchDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        const SizedBox(width: 8),
        Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  /// ───── 旧 Switch 游戏库（折扣页）─────
  Future<void> _loadSwitchGames() async {
    final games = await SwitchService.loadGames(_psnId);
    setState(() {
      _switchGames = games;
      _switchLoaded = true;
    });
  }

  /// 添加 Switch 游戏对话框
  void _showAddSwitchGameDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('添加 Switch 游戏', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入游戏名称',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF0A0A12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE60012)),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                await SwitchService.addGame(_psnId,
                  SwitchGame(name: name, addedAt: DateTime.now()));
                _loadSwitchGames();
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 记录游玩时长对话框
  void _showSwitchTimeDialog(int index) {
    final game = _switchGames[index];
    final hourCtrl = TextEditingController(text: game.hoursPlayed.toString());
    final minCtrl = TextEditingController(text: game.minutesPlayed.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(game.name,
          style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hourCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '小时',
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF0A0A12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '分钟',
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF0A0A12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE60012)),
            onPressed: () async {
              final h = int.tryParse(hourCtrl.text.trim()) ?? 0;
              final m = int.tryParse(minCtrl.text.trim()) ?? 0;
              await SwitchService.updatePlayTime(_psnId, index, h, m);
              _loadSwitchGames();
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteSwitchGame(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('删除游戏',
          style: TextStyle(color: Colors.white)),
        content: Text('确定删除「${_switchGames[index].name}」？',
          style: TextStyle(color: Colors.grey[400])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SwitchService.removeGame(_psnId, index);
      _loadSwitchGames();
    }
  }

  /// 从索尼 API 获取精确游玩时间并合并到 psnine 数据中（不覆盖奖杯状态）
  Widget _buildDeals() {
    List<Map<String, dynamic>> filtered;
    if (_platform == 'newlow') {
      filtered = _deals
          .where((g) => g['discount']?.toString().contains('新史低') == true)
          .toList();
      if (_newlowFilter != 'all') {
        filtered = filtered
            .where((g) =>
                g['platform']?.toString().toLowerCase() == _newlowFilter)
            .toList();
      }
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
        // 新史低子分类
        if (_platform == 'newlow')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'psn', 'steam', 'switch'].map((p) {
                  final active = _newlowFilter == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                          p == 'all' ? '全部' : p.toUpperCase(),
                          style: TextStyle(fontSize: 12,
                              color: active ? Colors.white : Colors.grey)),
                      selected: active,
                      onSelected: (_) =>
                          setState(() => _newlowFilter = p),
                      selectedColor: Colors.deepOrange[700],
                      backgroundColor: Colors.grey[850],
                      labelStyle: const TextStyle(fontSize: 12),
                      visualDensity: VisualDensity.compact,
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
              Text(
                _dealsStatus == '刷新中...'
                    ? _dealsStatus
                    : _platform == 'newlow'
                        ? '📉 ${_newlowFilter == "all" ? "全部" : _newlowFilter.toUpperCase()} ${filtered.length} 款史低'
                        : _platform == 'all'
                            ? '全部 ${_deals.length} 款折扣'
                            : '${_platform.toUpperCase()} ${filtered.length} 款折扣',
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
                    final nameCn = g['name_cn']?.toString() ?? '';
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
                                    ? Image.network(_proxyImage(imgUrl),
                                        fit: BoxFit.contain,
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
                                  Text(nameCn.isNotEmpty ? nameCn : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  if (nameCn.isNotEmpty && nameCn != name)
                                    Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500])),
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
    Color bg;
    Color fg = Colors.white;
    switch (text.toUpperCase()) {
      case 'PSN':
        bg = const Color(0xFF003791);  // 索尼蓝
        break;
      case 'STEAM':
        bg = const Color(0xFF1B2838);  // Steam 深蓝
        fg = const Color(0xFF66C0F4);  // Steam 亮蓝文字
        break;
      case 'SWITCH':
        bg = const Color(0xFFE60012);  // 任天堂红
        break;
      default:
        bg = Colors.grey[700]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: fg)),
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
        // ── ★ 收藏夹（可点击展开/收起） ──
        FutureBuilder<List<Bookmark>>(
          future: BookmarkService.load(),
          builder: (context, snapshot) {
            final bookmarks = snapshot.data ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(children: [
                // 标题栏（可点击）
                InkWell(
                  onTap: () => setState(() => _guideBookmarksExpanded = !_guideBookmarksExpanded),
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
                        Icon(_guideBookmarksExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                            color: Colors.grey[500], size: 20),
                      ],
                    ),
                  ),
                ),
                // 展开内容
                if (_guideBookmarksExpanded) ...[
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
                                  backgroundColor: const Color(0xFF1A1A2E),
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
        // ── 攻略卡片：宝可梦殿堂 ──
        _guideCard(
          icon: '🐉',
          title: '宝可梦殿堂',
          subtitle: '图鉴 / 队伍 / 闪符 / 配队 / 闪值排行',
          color: const Color(0xFFE53935),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PokedexPage()),
            );
          },
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        // 默认占位提示
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
        insetPadding: const EdgeInsets.all(0),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple[800]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _GameDetailCard(game: game),
            ),
          ),
        ),
      ),
    );
  }
}

/// 全屏视频播放器
void showVideoPlayer(BuildContext context, String videoUrl, String title) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _VideoPlayerPage(
        videoUrl: videoUrl,
        title: title,
      ),
    ),
  );
}

/// Full-screen video player page
class _VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  const _VideoPlayerPage({required this.videoUrl, required this.title});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _initialized
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_controller),
                      _PlayPauseOverlay(controller: _controller),
                    ],
                  ),
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text('加载视频中...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  const _PlayPauseOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: controller.value.isPlaying
          ? const SizedBox.shrink()
          : const Icon(Icons.play_circle_fill,
              size: 64, color: Colors.white70),
    );
  }
}

/// 解析心得内容中的 HTML 链接和纯文本 URL 为 RichText 可点击 span
InlineSpan _parseHtmlLinks(String text, BuildContext context) {
  final spans = <InlineSpan>[];
  // 一次性匹配：HTML <a> 链接 或 纯文本 URL
  final combinedPattern = RegExp(
    r'<a\s+href="(https?://[^"]+)"[^>]*>([^<]+)</a>'
    r'|'
    r'(https?://[^\s<>"]+)',
  );

  int lastEnd = 0;
  for (final match in combinedPattern.allMatches(text)) {
    // 链接前的普通文本
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }

    final htmlUrl = match.group(1);
    if (htmlUrl != null) {
      // HTML <a> 标签链接
      final url = htmlUrl;
      final label = match.group(2)!;
      spans.add(TextSpan(
        text: label,
        style: const TextStyle(
            color: Colors.lightBlue, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    BrowserPage(initialUrl: url, initialTitle: label),
              ),
            );
          },
      ));
    } else {
      // 纯文本 URL
      final url = match.group(3)!;
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
            color: Colors.lightBlue, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    BrowserPage(initialUrl: url, initialTitle: url),
              ),
            );
          },
      ));
    }
    lastEnd = match.end;
  }

  // 剩余文本
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }

  return TextSpan(children: spans);
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
      List<Map<String, dynamic>> tips = [];
      // 1. 服务器代理优先（国内手机直连 psnine 可能超时）
      try {
        final proxyUrl = 'http://8.153.97.56/api/psnine_tips?trophy_id=${widget.trophyId}';
        final resp = await http.get(Uri.parse(proxyUrl))
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          tips = (data['tips'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        }
      } catch (_) {}
      // 2. 服务器没返回则直连 psnine
      if (tips.isEmpty) {
        final psnine = PsnineClient('');
        tips = await psnine.fetchTrophyTips(widget.trophyId);
      }
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

/// Steam 背景视频播放器（点数商店动态背景） 
class _SteamBgVideo extends StatefulWidget {
  final String videoUrl;
  final String fallbackImageUrl;
  const _SteamBgVideo({required this.videoUrl, required this.fallbackImageUrl});

  @override
  State<_SteamBgVideo> createState() => _SteamBgVideoState();
}

class _SteamBgVideoState extends State<_SteamBgVideo> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _ctrl.setLooping(true);
          _ctrl.setVolume(0);
          _ctrl.play();
        }
      }).catchError((_) {
        if (mounted) setState(() => _ready = true); // will show fallback
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // 视频未准备好时显示静态图
      return Image.network(widget.fallbackImageUrl, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    if (!_ctrl.value.isInitialized) {
      // 初始化失败 → 显示静态图兜底
      return Image.network(widget.fallbackImageUrl, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _ctrl.value.size.width,
        height: _ctrl.value.size.height,
        child: VideoPlayer(_ctrl),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final VoidCallback? onNpssoChanged;
  final VoidCallback? onSteamChanged;
  final VoidCallback? onSyncCompleted;

  const SettingsPage({super.key, this.onNpssoChanged, this.onSteamChanged, this.onSyncCompleted});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _psnCtrl = TextEditingController();
  final TextEditingController _steamCtrl = TextEditingController();
  final TextEditingController _steamKeyCtrl = TextEditingController();
  final TextEditingController _switchCtrl = TextEditingController();
  String _savedPsnId = '';
  String _savedSteamId = '';
  String _savedSwitchToken = '';
  bool _loaded = false;
  bool _steamKeyVerified = false;
  bool _accountsExpanded = false;  // 账号设置展开
  bool _effectsExpanded = false;   // 全成就特效展开
  Set<String> _activeEffects = {}; // 当前启用的特效
  Map<String, double> _effectIntensity = {}; // 特效强度

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
      _savedSwitchToken = prefs.getString('switch_token') ?? '';
      _psnCtrl.text = _savedPsnId;
      _steamCtrl.text = _savedSteamId;
      _switchCtrl.text = _savedSwitchToken;
      // 加载特效偏好
      final effectStr = prefs.getString('platinum_effects');
      _activeEffects = effectStr != null && effectStr.isNotEmpty
          ? effectStr.split(',').toSet()
          : <String>{};
      // 加载特效强度
      final intensityStr = prefs.getString('platinum_intensity');
      final intensity = <String, double>{};
      if (intensityStr != null && intensityStr.isNotEmpty) {
        for (final p in intensityStr.split(',')) {
          final kv = p.split(':');
          if (kv.length == 2) {
            intensity[kv[0]] = double.tryParse(kv[1]) ?? 0.7;
          }
        }
      }
      _effectIntensity = intensity;
      _loaded = true;
    });
  }

  /// 绑定后自动同步到云端
  Future<void> _autoSync() async {
    final t = await AuthService.loadToken();
    if (t.token == null || t.token!.isEmpty) return;
    await AuthService.syncUpload(token: t.token!);
  }

  void _toggleEffect(String key) async {
    final updated = Set<String>.from(_activeEffects);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    setState(() => _activeEffects = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('platinum_effects', updated.join(','));
    widget.onSyncCompleted?.call();
  }

  void _setEffectIntensity(String key, double v) async {
    setState(() => _effectIntensity[key] = v);
    final prefs = await SharedPreferences.getInstance();
    final parts = _effectIntensity.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(2)}').toList();
    await prefs.setString('platinum_intensity', parts.join(','));
    widget.onSyncCompleted?.call();
  }

  Widget _buildEffectTile(String key, String title, String subtitle) {
    final isOn = _activeEffects.contains(key);
    final intensity = _effectIntensity[key] ?? 0.7;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _toggleEffect(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isOn ? Colors.amber.withOpacity(0.4) : Colors.grey[800]!),
            color: isOn ? Colors.amber.withOpacity(0.06) : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Switch(
                value: isOn,
                onChanged: (_) => _toggleEffect(key),
                activeColor: Colors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 13, color: isOn ? Colors.amber[200] : Colors.grey[400])),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ]),
              ),
            ]),
            if (isOn)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 8, top: 4),
                child: Row(children: [
                  Text('强度', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  Expanded(
                    child: Slider(
                      value: intensity,
                      onChanged: (v) => _setEffectIntensity(key, v),
                      min: 0.0, max: 1.0,
                      activeColor: Colors.amber,
                      inactiveColor: Colors.grey[700],
                    ),
                  ),
                  Text('${(intensity * 100).round()}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Future<void> _bindPsn() async {
    final id = _psnCtrl.text.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('psn_id', id);
    setState(() => _savedPsnId = id);
    await _autoSync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PSN 账号已绑定（已同步云端）')),
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
    await _autoSync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Steam 账号已绑定（已同步云端）')),
      );
    }
    widget.onSteamChanged?.call();
  }

  Future<void> _bindSwitch() async {
    final rawIds = _switchCtrl.text.trim();
    if (rawIds.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('switch_token', rawIds);
    setState(() => _savedSwitchToken = rawIds);
    await _autoSync();
    if (mounted) {
      final count = rawIds.split(',').length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已绑定 $count 个 Switch 账号')));
    }
    widget.onSteamChanged?.call();
  }

  Future<void> _setSteamKey() async {
    final key = _steamKeyCtrl.text.trim();
    if (key.isEmpty) return;
    try {
      final result = await SteamClient.setApiKey(key);
      setState(() => _steamKeyVerified = result['verified'] == true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            _steamKeyVerified
                ? 'Steam API Key 验证成功 ✅ (${result['test_name'] ?? ''})'
                : 'Key 已保存但验证失败: ${result['error'] ?? '未知'}',
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }

  /// 从存储字符串解析特效集合
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('psn_id');
    await prefs.remove('steam_id');
    await prefs.remove('switch_token');
    setState(() {
      _savedPsnId = '';
      _savedSteamId = '';
      _savedSwitchToken = '';
      _psnCtrl.clear();
      _steamCtrl.clear();
      _switchCtrl.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已退出登录')),
      );
    }
  }

  /// TrophyRoom 账号状态卡（管理员显示服务器统计）
  Widget _buildAccountStatus() {
    return FutureBuilder<({String? token, String? username})>(
      future: AuthService.loadToken(),
      builder: (ctx, snap) {
        final data = snap.data;
        final token = data?.token;
        final uname = data?.username;
        final isLoggedIn = token != null && token.isNotEmpty && uname != null && uname.isNotEmpty;
        final isAdmin = isLoggedIn && uname!.toLowerCase() == 'shinyyann';

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLoggedIn
                      ? [const Color(0xFF1A1A3E), const Color(0xFF0F0C29)]
                      : [const Color(0xFF2A1A1A), const Color(0xFF1A1A2E)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLoggedIn ? Colors.purple.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isLoggedIn ? Colors.purple[800] : Colors.grey[800],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: GestureDetector(
                  onLongPress: () {
                    if (isAdmin) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminPanelPage(),
                        ),
                      );
                    }
                  },
                  child: Center(
                    child: Text(
                      isLoggedIn ? (uname![0].toUpperCase()) : '?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: isLoggedIn ? Colors.white : Colors.grey[500]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? uname! : '未登录',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: isLoggedIn ? Colors.white : Colors.grey[400]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoggedIn ? '✅ 云端同步' : '⚠️ 仅本地数据',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (isLoggedIn)
                TextButton(
                  onPressed: () => _syncNow(token!),
                  child: const Text('同步', style: TextStyle(fontSize: 13)),
                ),
              if (isLoggedIn)
                TextButton(
                  onPressed: () async {
                    final ok = await WidgetUpdater.debugPush();
                    if (mounted) {
                      final prefs = await SharedPreferences.getInstance();
                      final psn = prefs.getString('widget_psn') ?? '?';
                      final steam = prefs.getString('widget_steam') ?? '?';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok
                          ? '✅ 已推送 · PSN=$psn'
                          : '❌ 推送失败')),
                      );
                    }
                  },
                  child: const Text('刷组件', style: TextStyle(fontSize: 13, color: Colors.orangeAccent)),
                ),
              if (!isLoggedIn)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                    );
                  },
                  child: const Text('登录', style: TextStyle(fontSize: 13, color: Colors.blueAccent)),
                ),
            ],
          ),
        ),
        if (isAdmin) _buildAdminPanel(),
      ],
    );
      },
    );
  }

  /// 管理员面板（仅 shinyyann 可见）
  Widget _buildAdminPanel() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.loadToken().then((t) {
        if (t.token == null || t.token!.isEmpty) return null;
        return AuthService.syncDownload(token: t.token!);
      }),
      builder: (ctx, snap) {
        final admin = snap.data?['_admin'] as Map<String, dynamic>?;
        if (admin == null) {
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber[300])),
                const SizedBox(width: 8),
                Text('加载服务器统计...',
                  style: TextStyle(fontSize: 12, color: Colors.amber[300])),
              ],
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text('服务器统计',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const Spacer(),
                  Text('仅你可见',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _adminStat('总用户', '${admin['total_users'] ?? '?'}', Icons.people),
                  const SizedBox(width: 16),
                  _adminStat('在线', '${admin['online_users'] ?? '?'}', Icons.wifi_tethering),
                  const SizedBox(width: 16),
                  _adminStat('已同步', '${admin['total_data_count'] ?? '?'}', Icons.cloud_done),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('进入管理面板',
                      style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminPanelPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _adminStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.amber[300]),
            const SizedBox(height: 4),
            Text(value,
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  /// 手动同步
  Future<void> _syncNow(String token) async {
    final msg = ScaffoldMessenger.of(context);
    try {
      final ok = await AuthService.syncUpload(token: token);
      if (!ok) {
        msg.showSnackBar(const SnackBar(content: Text('同步失败: 网络错误')));
        return;
      }
      final remote = await AuthService.syncDownload(token: token);
      if (remote != null) {
        await AuthService.applyRemoteData(remote);
        setState(() {
          _savedPsnId = remote['psn_id']?.toString() ?? _savedPsnId;
          _savedSteamId = remote['steam_id']?.toString() ?? _savedSteamId;
          if (remote['switch_token'] is String) {
            final st = (remote['switch_token'] as String).trim();
            if (st.isNotEmpty) {
              _savedSwitchToken = st;
            }
          }
        });
        // 通知父级重新加载 Switch 数据
        if (widget.onSyncCompleted != null) {
          widget.onSyncCompleted!();
        }
      }
      msg.showSnackBar(const SnackBar(content: Text('✅ 同步完成')));
    } catch (e) {
      msg.showSnackBar(SnackBar(content: Text('同步失败: $e')));
    }
  }

  /// 退出 TrophyRoom 账号
  Future<void> _authLogout() async {
    await CookieIsolation.onUserSwitch();
    await AuthService.logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已退出账号')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  void dispose() {
    _psnCtrl.dispose();
    _steamCtrl.dispose();
    _steamKeyCtrl.dispose();
    _switchCtrl.dispose();
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
        // ── 👤 我的账号 ──
        _buildAccountStatus(),
        const SizedBox(height: 24),

        // ── 🔑 账号设置（可点击展开/收起） ──
        InkWell(
          onTap: () => setState(() => _accountsExpanded = !_accountsExpanded),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.purple, size: 20),
                const SizedBox(width: 10),
                Text('账号设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[100])),
                const Spacer(),
                Icon(_accountsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[500], size: 24),
              ],
            ),
          ),
        ),

        if (_accountsExpanded) ...[
          const SizedBox(height: 24),
          Text('PSN 🎮',
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
        SizedBox(height: 24),
        Text('Nintendo Switch 🎮',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[300]),
        ),
        const SizedBox(height: 4),
        Text('填入小黑盒账号 ID，多个用逗号分隔',
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _switchCtrl,
                decoration: InputDecoration(
                  hintText: '如: abc123, xyz456',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: _bindSwitch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE60012),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('绑定'),
            ),
          ],
        ),
        if (_savedSwitchToken.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Row(children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
              SizedBox(width: 6),
              Expanded(child: Text('已绑定 ${_savedSwitchToken.split(',').length} 个账号: $_savedSwitchToken',
                style: TextStyle(fontSize: 13, color: Colors.green[400]),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        const SizedBox(height: 4),
        Text('获取方式：小黑盒 App→我的→右上角分享→复制链接里的 account_id',
          style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        SizedBox(height: 24),
        // ── Steam API Key (服务器配置，无需用户填写) ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(Icons.cloud_done, size: 16, color: Colors.green[400]),
            const SizedBox(width: 6),
            Text('Steam API 已由服务器配置',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
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
        ],  // closes _accountsExpanded

        const SizedBox(height: 16),
        // ── 全成就特效 ──
        InkWell(
          onTap: () => setState(() => _effectsExpanded = !_effectsExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 18, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text('全成就特效', style: TextStyle(fontSize: 14, color: Colors.grey[300])),
              ),
              Text(
                _activeEffects.isEmpty ? '关闭' : '${_activeEffects.length}个启用',
                style: TextStyle(fontSize: 12, color: _activeEffects.isEmpty ? Colors.grey[600] : Colors.amber[300]),
              ),
              const SizedBox(width: 8),
              Icon(_effectsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20, color: Colors.grey[500]),
            ]),
          ),
        ),
        if (_effectsExpanded) ...[
          const SizedBox(height: 8),
          _buildEffectTile('shimmer', '✨ 星辉闪烁', '金色微光粒子在卡片中漂浮'),
          _buildEffectTile('sweep', '🌊 流光扫描', '对角线光条周期性扫过'),
          _buildEffectTile('prism', '💎 钻石棱光', '8色追光边框互相追逐'),
          _buildEffectTile('ember', '🔥 余烬微光', '底部升起橙红色余烬'),
          _buildEffectTile('pulse', '🎯 白金脉冲', '中心向外扩散白金光环'),
          _buildEffectTile('particles', '🌈 七彩粒子', '呼吸粒子铺满卡片缓慢运动'),
        ],

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
    final nameCn = game['name_cn']?.toString() ?? '';
    final description = game['description']?.toString() ?? '';
    final imgUrl = game['img']?.toString() ?? '';
    final plat = game['platform']?.toString() ?? '';
    final price = game['price']?.toString() ?? '';
    final original = game['original']?.toString() ?? '';
    final disc = game['discount']?.toString() ?? '';
    final rating = game['rating']?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 封面大图（叠加播放按钮）
          if (imgUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(_HomePageState._proxyImage(imgUrl), height: 200,
                      width: double.infinity, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200, color: Colors.grey[850],
                        child: Icon(Icons.videogame_asset, size: 60,
                            color: Colors.grey[600]),
                      )),
                  // 播放按钮
                  GestureDetector(
                    onTap: () {
                      final videoUrl = game['video_url']?.toString() ?? '';
                      if (videoUrl.isNotEmpty) {
                        showVideoPlayer(context, videoUrl,
                            nameCn.isNotEmpty ? nameCn : name);
                      } else {
                        final url = game['url']?.toString() ?? '';
                        if (url.isNotEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BrowserPage(
                                initialUrl: url,
                                initialTitle: nameCn.isNotEmpty ? nameCn : name,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 游戏名（优先显示中文名）
                Text(nameCn.isNotEmpty ? nameCn : name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (nameCn.isNotEmpty && nameCn != name)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(name,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ),
                // 官方介绍
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[300],
                            height: 1.5)),
                  ),
                ],
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
                // 关闭按钮
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
                const SizedBox(height: 8),
                // 底部留白
                const SizedBox(height: 16),
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
// ============================================================
// Steam 成就弹窗（底部可滚动全量列表）
// ============================================================
class _SteamAchievementSheet extends StatefulWidget {
  final String steamId;
  final String appId;
  final String gameName;
  final String Function(String) proxyImage;

  const _SteamAchievementSheet({
    required this.steamId,
    required this.appId,
    required this.gameName,
    required this.proxyImage,
  });

  @override
  State<_SteamAchievementSheet> createState() => _SteamAchievementSheetState();
}

class _SteamAchievementSheetState extends State<_SteamAchievementSheet> {
  bool _loading = true;
  String? _error;
  List<dynamic> _achievements = [];
  int _unlocked = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = SteamClient(widget.steamId);
      final result = await client.fetchAchievements(widget.appId);
      setState(() {
        _achievements = (result['achievements'] as List?) ?? [];
        _unlocked = _achievements.where((a) => a['achieved'] == true).length;
        _loading = false;
      });
      // 回写统计数据到父级缓存
      final count = result['total'] ?? _achievements.length;
      final unlocked = result['unlocked'] ?? _unlocked;
      (context as Element).visitAncestorElements((el) {
        if (el.widget is Scaffold) return false;
        return true;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _friendlyError(String errMsg) {
    if (errMsg.contains('privacy') || errMsg.contains('403')) {
      return 'Steam 隐私限制：请在 Steam 网页版将「游戏详情」设为公开';
    } else if (errMsg.contains('400') || errMsg.contains('no stats')) {
      return '该游戏暂无成就数据';
    } else if (errMsg.contains('timeout') || errMsg.contains('超时')) {
      return '网络超时，请检查连接后重试';
    } else {
      return '加载失败：$errMsg';
    }
  }

  Widget _achPlaceholder(bool achieved) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: achieved ? const Color(0xFF1A3A5C) : Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(achieved ? Icons.emoji_events : Icons.lock_outline,
        size: 16, color: achieved ? const Color(0xFF66C0F4) : Colors.grey[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121926),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // 拖拽条
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
            child: Row(children: [
              const Icon(Icons.emoji_events, color: Color(0xFF66C0F4), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.gameName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          // 内容区
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF66C0F4)))
            : _error != null
              ? _buildErrorView(scrollController)
              : _buildAchievementList(scrollController),
          ),
        ]),
      ),
    );
  }

  Widget _buildErrorView(ScrollController scrollController) {
    return ListView(controller: scrollController, padding: const EdgeInsets.all(20), children: [
      Icon(Icons.warning_amber_rounded, size: 48, color: Colors.grey[600]),
      const SizedBox(height: 16),
      Text(_friendlyError(_error!), textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 14)),
      const SizedBox(height: 16),
      Center(child: ElevatedButton.icon(
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('重试'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66C0F4),
          foregroundColor: Colors.white,
        ),
        onPressed: _fetch,
      )),
    ]);
  }

  Widget _buildAchievementList(ScrollController scrollController) {
    if (_achievements.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
        const SizedBox(height: 12),
        Text('暂无成就数据', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
      ]));
    }
    final total = _achievements.length;
    final cr = total > 0 ? _unlocked / total : 0.0;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 统计条
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Text('$_unlocked / $total', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            const SizedBox(width: 8),
            Text('${(cr * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, color: Color(0xFF66C0F4), fontWeight: FontWeight.bold)),
            const Spacer(),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: cr, minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66C0F4)),
              ),
            )),
          ]),
        ),
        // 全量成就列表
        ..._achievements.map((ach) {
          final achieved = ach['achieved'] == true;
          final displayName = SteamClient.translateAchievement(ach['display_name'] ?? ach['api_name'] ?? '');
          final desc = SteamClient.translateDescription(ach['description'] ?? '');
          final achIcon = achieved ? (ach['icon'] ?? '') : (ach['icon_gray'] ?? '');
          final globalPct = (ach['global_pct'] ?? 0).toDouble();
          final unlockTs = achieved ? (ach['unlock_time'] as int? ?? 0) : 0;
          final unlockDate = unlockTs > 0
              ? DateTime.fromMillisecondsSinceEpoch(unlockTs * 1000)
              : null;
          final unlockStr = unlockDate != null
              ? '${unlockDate.year}-${unlockDate.month.toString().padLeft(2, '0')}-${unlockDate.day.toString().padLeft(2, '0')}'
              : '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: achIcon.isNotEmpty
                  ? Image.network(widget.proxyImage(achIcon), width: 36, height: 36, fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => _achPlaceholder(achieved))
                  : _achPlaceholder(achieved),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(displayName, style: TextStyle(fontSize: 13, color: achieved ? Colors.grey[200] : Colors.grey[500], fontWeight: FontWeight.w600)),
                if (desc.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (unlockStr.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('🔓 $unlockStr', style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
              ])),
              if (globalPct > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(children: [
                    Text('${globalPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: globalPct < 5 ? const Color(0xFFFFD700) : globalPct < 20 ? const Color(0xFF4ECDC4) : Colors.grey[500])),
                    Text('全球', style: TextStyle(fontSize: 8, color: Colors.grey[600])),
                  ]),
                ),
            ]),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

// Trigger build Sun May  3 20:14:20 CST 2026
// trigger 1777813344
