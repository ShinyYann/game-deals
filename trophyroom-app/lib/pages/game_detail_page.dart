import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GameDetailPage extends StatefulWidget {
  final String gameId;

  const GameDetailPage({super.key, required this.gameId});

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final psnId = prefs.getString('psn_id') ?? '';

      if (psnId.isEmpty) {
        setState(() {
          _loading = false;
          _error = '请先绑定 PSN 账号';
        });
        return;
      }

      final resp = await http
          .get(Uri.parse(
              'http://8.153.97.56/api/psn_game_detail?game_id=${widget.gameId}&uid=$psnId'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic> && data['error'] == null) {
          setState(() {
            _data = data;
            _loading = false;
          });
        } else {
          setState(() {
            _error = data['error']?.toString() ?? '数据加载失败';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = '请求失败: ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _loading = false;
      });
    }
  }

  IconData _trophyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'platinum':
        return Icons.auto_awesome;
      case 'gold':
        return Icons.star;
      case 'silver':
        return Icons.circle;
      case 'bronze':
        return Icons.circle_outlined;
      default:
        return Icons.emoji_events;
    }
  }

  Color _trophyColor(String type) {
    switch (type.toLowerCase()) {
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _data?['name']?.toString() ?? '游戏详情',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(_error,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('重试'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _fetchDetail,
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  void _showTrophyTips(BuildContext context, String trophyId) {
    if (trophyId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TrophyTipsSheet(trophyId: trophyId),
    );
  }

  Widget _buildContent() {
    final data = _data!;
    final name = data['name']?.toString() ?? 'Unknown';
    final coverUrl = data['cover_url']?.toString();
    final difficulty = data['difficulty']?.toString();
    final hoursPlayed = data['hours_played'];
    final completionRate = (data['completion_rate'] ?? 0).toDouble();
    final trophies = data['trophies'] as List? ?? [];

    // Count by type
    int p = 0, g = 0, s = 0, b = 0;
    for (final t in trophies) {
      final type = (t['type'] ?? '').toString().toLowerCase();
      if (type == 'platinum') p++;
      if (type == 'gold') g++;
      if (type == 'silver') s++;
      if (type == 'bronze') b++;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (coverUrl != null && coverUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 220,
              color: Colors.grey[850],
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.videogame_asset,
                      size: 60, color: Colors.grey[600]),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Meta info row
                Row(
                  children: [
                    if (difficulty != null && difficulty.isNotEmpty)
                      _metaChip('🎯 $difficulty', Colors.red[700]!),
                    if (difficulty != null &&
                        difficulty.isNotEmpty &&
                        hoursPlayed != null)
                      const SizedBox(width: 8),
                    if (hoursPlayed != null)
                      _metaChip('⏱ ${hoursPlayed}h', Colors.blue[700]!),
                  ],
                ),
                const SizedBox(height: 12),

                // Completion rate bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: completionRate / 100,
                          backgroundColor: Colors.grey[800],
                          color: completionRate >= 100
                              ? Colors.green[400]
                              : Colors.purple[300],
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${completionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: completionRate >= 100
                            ? Colors.green[400]
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Trophy counts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _trophyCount(Icons.auto_awesome, '白金', p,
                        const Color(0xFFE5E4E2)),
                    _trophyCount(Icons.star, '金', g, const Color(0xFFFFD700)),
                    _trophyCount(Icons.circle, '银', s, const Color(0xFFC0C0C0)),
                    _trophyCount(Icons.circle_outlined, '铜', b,
                        const Color(0xFFCD7F32)),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 12),

                // Trophy list header
                Text(
                  '奖杯列表 (${trophies.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Trophy items
                ...trophies.map((t) => _TrophyItem(
                      name: t['name']?.toString() ?? '',
                      type: t['type']?.toString() ?? 'bronze',
                      unlocked: t['unlocked'] == true,
                      icon: _trophyIcon(t['type']?.toString() ?? ''),
                      color: _trophyColor(t['type']?.toString() ?? ''),
                      earnedDate: t['earned_date']?.toString(),
                      trophyId: t['id']?.toString(),
                      onTipsTap: () => _showTrophyTips(context, t['id']?.toString() ?? ''),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _trophyCount(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, size: 22, color: count > 0 ? color : Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: count > 0 ? color : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _TrophyItem extends StatelessWidget {
  final String name;
  final String type;
  final bool unlocked;
  final IconData icon;
  final Color color;
  final String? earnedDate;
  final String? trophyId;
  final VoidCallback? onTipsTap;

  const _TrophyItem({
    required this.name,
    required this.type,
    required this.unlocked,
    required this.icon,
    required this.color,
    this.earnedDate,
    this.trophyId,
    this.onTipsTap,
  });

  String _typeLabel(String t) {
    switch (t.toLowerCase()) {
      case 'platinum': return '白';
      case 'gold': return '金';
      case 'silver': return '银';
      case 'bronze': return '铜';
      default: return '?';
    }
  }

  Color _typeBadgeColor(String t) {
    switch (t.toLowerCase()) {
      case 'platinum': return const Color(0xFF8098A8);
      case 'gold': return const Color(0xFFDAA520);
      case 'silver': return const Color(0xFF9CA3AF);
      case 'bronze': return const Color(0xFFCD7F32);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = unlocked ? 1.0 : 0.35;
    final typeColor = _typeBadgeColor(type);
    final isPlatinum = type.toLowerCase() == 'platinum';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked
              ? color.withOpacity(0.3)
              : Colors.grey[800]!,
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: opacity,
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: unlocked ? Colors.white : Colors.grey[600],
                  ),
                ),
                if (earnedDate != null && earnedDate!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      earnedDate!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Tips button
          if (trophyId != null && onTipsTap != null)
            GestureDetector(
              onTap: onTipsTap,
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('💡', style: TextStyle(fontSize: 12)),
              ),
            ),
          // Type badge (白金/金/银/铜)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: unlocked
                  ? typeColor.withOpacity(0.3)
                  : Colors.grey[800],
              gradient: isPlatinum && unlocked
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF8098A8),
                        Color(0xFFD0D8E0),
                        Color(0xFF8098A8),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : null,
              borderRadius: BorderRadius.circular(6),
              boxShadow: isPlatinum && unlocked
                  ? [
                      BoxShadow(
                        color: const Color(0x40B2EBF2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              _typeLabel(type),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: unlocked ? Colors.white : Colors.grey[500],
                shadows: isPlatinum && unlocked
                    ? [
                        const Shadow(
                          color: Color(0x60B2EBF2),
                          blurRadius: 3,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyTipsSheet extends StatefulWidget {
  final String trophyId;
  const _TrophyTipsSheet({required this.trophyId});
  @override
  State<_TrophyTipsSheet> createState() => _TrophyTipsSheetState();
}

class _TrophyTipsSheetState extends State<_TrophyTipsSheet> {
  String _tips = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  Future<void> _fetchTips() async {
    try {
      final resp = await http.get(
        Uri.parse('http://8.153.97.56/api/trophy_tips?id=${widget.trophyId}'),
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          _tips = (data['tips'] ?? '').toString();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _tips = '暂无心得数据');
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('💡 奖杯心得',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _tips.isNotEmpty ? _tips : '暂无心得',
                  style: TextStyle(
                    fontSize: 14,
                    color: _tips.isNotEmpty ? Colors.grey[300] : Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
