import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import 'guide_hub_page.dart';

/// 游戏情报站 — 攻略卡片墙 + 白金攻略汇总
class InfoSummaryPage extends StatefulWidget {
  const InfoSummaryPage({super.key});

  @override
  State<InfoSummaryPage> createState() => _InfoSummaryPageState();
}

class _InfoSummaryPageState extends State<InfoSummaryPage> with TickerProviderStateMixin {
  // ── Guide 数据 ──
  List<Map<String, dynamic>> _guideGames = [];
  bool _loadingGuides = true;
  String? _guideError;
  String _selectedPlatform = 'all'; // all | psn | steam | switch

  // (头像/兑换码功能已移除——原数据源停用)
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchGuides();
  }

  // ──────────────────────────── API: 攻略 ────────────────────────────
  Future<void> _fetchGuides() async {
    try {
      final resp = await http
          .get(Uri.parse('http://8.153.97.56/api/guide/my'))
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final games = (data['games'] as List).cast<Map<String, dynamic>>();

        final guideGames = <Map<String, dynamic>>[];
        for (var g in games) {
          if ((g['total_guides'] ?? 0) > 0) {
            guideGames.add(g);
          }
        }

        setState(() {
          _guideGames = guideGames;
          _loadingGuides = false;
        });
      } else {
        setState(() {
          _guideError = '服务器错误: ${resp.statusCode}';
          _loadingGuides = false;
        });
      }
    } catch (e) {
      setState(() {
        _guideError = '加载失败: $e';
        _loadingGuides = false;
      });
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'psn': return PhosphorIconsFill.trophy;
      case 'steam': return PhosphorIconsFill.monitorPlay;
      case 'switch': return PhosphorIconsFill.gameController;
      default: return PhosphorIconsFill.gameController;
    }
  }

  List<Map<String, dynamic>> get _filteredGames {
    if (_selectedPlatform == 'all') return _guideGames;
    return _guideGames.where((g) =>
        (g['platform']?.toString() ?? '') == _selectedPlatform).toList();
  }

  Widget _buildPlatformTabs() {
    final platforms = [
      ('all', '全部', Colors.white70),
      ('psn', 'PSN', const Color(0xFF0070CC)),
      ('steam', 'Steam', const Color(0xFF66C0F4)),
      ('switch', 'Switch', const Color(0xFFE60012)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: platforms.map((p) {
        final key = p.$1;
        final label = p.$2;
        final clr = p.$3;
        final active = _selectedPlatform == key;
        final bg = active ? clr.withAlpha(20) : Colors.grey[850]!;
        final borderClr = active ? clr.withAlpha(60) : Colors.grey[850]!;
        final count = key == 'all' ? _guideGames.length
            : _guideGames.where((g) => (g['platform']?.toString() ?? '') == key).length;
        final icon = _platformIcon(key);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlatform = key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderClr, width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(icon, size: 16, color: active ? clr : Colors.grey[500]),
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(fontSize: 11,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        color: active ? clr : Colors.grey[500])),
                    Text('$count', style: TextStyle(fontSize: 9,
                        color: (active ? clr : Colors.grey[600]!).withAlpha(160))),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList()),
    );
  }



  // ──────────────────────────── 构建 ────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingGuides;

    return Stack(
      children: [
        // 背景渐变
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A12),
                Color(0xFF12121F),
                Color(0xFF0A0A12),
              ],
            ),
          ),
        ),

        if (isLoading)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFA855F7),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '正在加载情报...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
        else
          RefreshIndicator(
            color: const Color(0xFFA855F7),
            backgroundColor: const Color(0xFF1E1E30),
            onRefresh: () async {
              _fetchGuides();
              // wait a bit for both
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
              children: [
                // ─── 页头 ───
                _buildHeader(),

                const SizedBox(height: 8),

                // ─── 平台筛选 ───
                _buildPlatformTabs(),

                const SizedBox(height: 8),

                // ─── 攻略在手 ───
                _buildSection(
                  icon: PhosphorIconsFill.sword,
                  title: '攻略在手',
                  subtitle: '${_filteredGames.length} 款游戏有攻略',
                  color: const Color(0xFF4ECDC4),
                  games: _filteredGames,
                  countField: 'total_guides',
                  countSuffix: '篇攻略',
                  emptyText: '暂无攻略数据',
                  guideError: _guideError,
                ),


              ],
            ),
          ),
      ],
    );
  }

  // ──────────────────────────── 页头 ────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const PhosphorIcon(
              PhosphorIconsFill.broadcast,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '游戏情报站',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '攻略、白金攻略一应俱全',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── 分区 ────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Map<String, dynamic>> games,
    required String countField,
    required String countSuffix,
    required String emptyText,
    String? guideError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分区标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PhosphorIcon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const Spacer(),
              if (games.isNotEmpty)
                PhosphorIcon(
                  PhosphorIconsFill.caretRight,
                  color: Colors.grey[600],
                  size: 14,
                ),
              if (games.isNotEmpty)
                const SizedBox(width: 4),
              if (games.isNotEmpty)
                PhosphorIcon(
                  PhosphorIconsFill.caretRight,
                  color: Colors.grey[700],
                  size: 14,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 卡片横向滚动
        if (guideError != null && games.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _errorCard(guideError),
          )
        else if (games.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _emptyPlaceholder(emptyText),
          )
        else
          SizedBox(
            height: 136,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: games.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildGameCard(
                  game: games[index],
                  countField: countField,
                  countSuffix: countSuffix,
                  color: color,
                );
              },
            ),
          ),
      ],
    );
  }

  // ──────────────────────────── 游戏卡片 ────────────────────────────
  Widget _buildGameCard({
    required Map<String, dynamic> game,
    required String countField,
    required String countSuffix,
    required Color color,
  }) {
    final gameName = game['game_name']?.toString() ?? '未知';
    final info = game['info'] as Map<String, dynamic>?;
    final nameCn = info?['name_cn']?.toString() ?? gameName;
    final count = game[countField] as int? ?? 0;

    // 游戏名取前2个中文/字符作为图标文字
    final displayName = nameCn.length >= 2
        ? nameCn.substring(0, 2)
        : nameCn;

    // 基于名字生成稳定颜色
    final nameHash = gameName.hashCode.abs();
    final hue = nameHash % 360;
    final cardColor = HSLColor.fromAHSL(0.25, hue.toDouble(), 0.7, 0.45).toColor();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GuideHubPage(
              gameName: gameName,
              rawData: game,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withAlpha(12),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            splashColor: color.withAlpha(20),
            highlightColor: color.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 游戏图标 — 用平台 icon + 游戏名字首字
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          cardColor.withAlpha(200),
                          cardColor.withAlpha(100),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: cardColor.withAlpha(80),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withAlpha(40),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _platformIcon(game['platform']?.toString() ?? ''),
                          size: 20,
                          color: Colors.white.withAlpha(220),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 游戏名称
                  Text(
                    nameCn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 数量徽章
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: color.withAlpha(60),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '$count$countSuffix',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────── 错误 / 空状态 ────────────────────────────
  Widget _errorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha(60), width: 0.5),
      ),
      child: Row(
        children: [
          const PhosphorIcon(
            PhosphorIconsFill.warningCircle,
            color: Color(0xFFEF5350),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _loadingGuides = true;
                _guideError = null;
              });
              _fetchGuides();
            },
            child: const PhosphorIcon(
              PhosphorIconsFill.arrowClockwise,
              color: Color(0xFFA855F7),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlaceholder(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(8), width: 0.5),
      ),
      child: Column(
        children: [
          PhosphorIcon(
            PhosphorIconsFill.smileySad,
            color: Colors.grey[600],
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── 分割线 ────────────────────────────
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withAlpha(15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PhosphorIcon(
              PhosphorIconsFill.infinity,
              color: Colors.grey[700],
              size: 14,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withAlpha(15),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildOriginalSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 小标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              PhosphorIcon(icon, color: const Color(0xFFA855F7), size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((e) => _buildCodeCard(e.value, e.key)),
      ],
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> item, int index) {
    final codes = List<String>.from(item['codes'] ?? []);
    final snippet = item['snippet']?.toString() ?? '';
    final link = item['link']?.toString() ?? '';
    final time = item['time']?.toString() ?? '';
    final images = List<String>.from(item['images'] ?? []);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片行
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      width: 100,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        color: Colors.grey[850],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 兑换码
                if (codes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: codes.map((code) {
                      return GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '已复制: $code',
                                style: const TextStyle(fontSize: 12),
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green[800],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[900]!.withAlpha(70),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.green[700]!.withAlpha(120),
                            ),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFF7CFF7C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                // 摘要（可折叠）
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _expandedIndex = _expandedIndex == index ? -1 : index;
                    }),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            snippet,
                            maxLines: _expandedIndex == index ? 20 : 2,
                            overflow: _expandedIndex == index
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (snippet.length > 60)
                          PhosphorIcon(
                            _expandedIndex == index
                                ? PhosphorIconsFill.caretUp
                                : PhosphorIconsFill.caretDown,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                      ],
                    ),
                  ),
                ],
                // 底部：时间 + 链接
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        await launchUrl(Uri.parse(link));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '查看原帖',
                            style: TextStyle(fontSize: 10, color: Colors.blue[400]),
                          ),
                          const SizedBox(width: 2),
                          PhosphorIcon(
                            PhosphorIconsFill.arrowSquareOut,
                            size: 10,
                            color: Colors.blue[400],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
