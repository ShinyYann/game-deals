/// 🐉 宝可梦详情页 — 种族值雷达图 + 闪光切换 + 完整数据
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EnhancedPokemonDetailPage extends StatefulWidget {
  final Map<String, dynamic> pokemon;
  final String normalSprite;

  const EnhancedPokemonDetailPage({
    super.key,
    required this.pokemon,
    required this.normalSprite,
  });

  @override
  State<EnhancedPokemonDetailPage> createState() => _EnhancedPokemonDetailPageState();
}

class _EnhancedPokemonDetailPageState extends State<EnhancedPokemonDetailPage> {
  bool _showShiny = false;
  Map<String, int>? _baseStats;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBaseStats();
  }

  Future<void> _fetchBaseStats() async {
    final ndex = (widget.pokemon['ndex'] as int?) ?? 1;
    try {
      final res = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$ndex'),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final stats = <String, int>{};
        for (final s in data['stats']) {
          stats[s['stat']['name']] = s['base_stat'];
        }
        if (mounted) setState(() {
          _baseStats = stats;
          _statsLoading = false;
        });
      } else {
        if (mounted) setState(() => _statsLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pokemon;
    final ndex = (p['ndex'] as int?) ?? 0;
    final nameZh = (p['name_zh'] ?? '??').toString();
    final nameEn = (p['name_en'] ?? '').toString();
    final nameJp = (p['name_jp'] ?? '').toString();
    final types = _parseTypes(p);
    final ndexStr = ndex.toString().padLeft(3, '0');
    final normalSprite = 'https://assets.pokemon.com/assets/cms2/img/pokedex/full/$ndexStr.png';
    final shinySprite = 'https://assets.pokemon.com/assets/cms2/img/pokedex/full/${ndexStr}_f2.png';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text('#${ndex.toString().padLeft(3, '0')} $nameZh'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          // 闪光切换
          IconButton(
            icon: Icon(
              _showShiny ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: _showShiny ? Colors.amber[300] : Colors.grey[600],
            ),
            tooltip: _showShiny ? '普通' : '闪光',
            onPressed: () => setState(() => _showShiny = !_showShiny),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 头像 + 基本 ──
            Center(
              child: Column(
                children: [
                  // 普通/闪光切换（pokemon.com CDN 均有图）
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Image.network(
                      _showShiny ? shinySprite : normalSprite,
                      key: ValueKey(_showShiny),
                      width: 140, height: 140, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.catching_pokemon, color: Colors.grey[700], size: 64),
                    ),
                  ),
                  Text(nameZh, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (nameEn.isNotEmpty) Text(nameEn, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  if (nameJp.isNotEmpty) Text(nameJp, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 10),
                  // 属性标签
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: types.map((t) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: _typeColor(t).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _typeColor(t).withOpacity(0.5)),
                      ),
                      child: Text(t, style: TextStyle(color: _typeColor(t), fontWeight: FontWeight.bold, fontSize: 14)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 种族值雷达图 ──
            _section('种族值', [
              if (_statsLoading)
                const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_baseStats != null)
                _buildStatsRadar()
              else
                const SizedBox(
                  height: 60,
                  child: Center(child: Text('无法获取种族值数据', style: TextStyle(color: Colors.grey))),
                ),
            ]),

            // ── 基础数据 ──
            _section('基础数据', [
              _row('分类', '${(p['species'] ?? '').toString()} 宝可梦'),
              _row('身高', '${p['height'] ?? '-'}m'),
              _row('体重', '${p['weight'] ?? '-'}kg'),
              _row('颜色', p['color']?.toString() ?? '-'),
              if (p['gender_diff'] == true) _row('性别差异', '有'),
              _row('捕捉率', p['catch_rate']?.toString() ?? '-'),
              _row('基础经验', p['exp_yield']?.toString() ?? '-'),
              _row('100级经验', p['lv100_exp']?.toString() ?? '-'),
            ]),

            // ── 对战数据 ──
            _section('对战数据', [
              _row('特性', _abilityStr(p)),
              if ((p['ability_hidden'] ?? '').toString().isNotEmpty)
                _row('隐藏特性', p['ability_hidden'].toString()),
            ]),

            // ── 努力值 ──
            _section('努力值', [
              _row('HP', _evStr(p, 'ev_hp')),
              _row('攻击', _evStr(p, 'ev_atk')),
              _row('防御', _evStr(p, 'ev_def')),
              _row('特攻', _evStr(p, 'ev_spatk')),
              _row('特防', _evStr(p, 'ev_spdef')),
              _row('速度', _evStr(p, 'ev_speed')),
            ]),

            // ── 培育数据 ──
            _section('培育数据', [
              if ((p['egg_group1'] ?? '').toString().isNotEmpty)
                _row('蛋群', p['egg_group1'].toString() +
                    ((p['egg_group2'] ?? '').toString().isNotEmpty ? ' / ${p['egg_group2']}' : '')),
              _row('生蛋分组', '${p['egg_group1'] ?? ''} ${p['egg_group2'] ?? ''}'.trim()),
            ]),
          ],
        ),
      ),
    );
  }

  // ─── 种族值雷达图 ─────────────────────────────────
  Widget _buildStatsRadar() {
    if (_baseStats == null) return const SizedBox.shrink();
    final labels = ['HP', '攻击', '防御', '特攻', '特防', '速度'];
    final keys = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    final values = keys.map((k) => _baseStats![k] ?? 0).toList();
    final total = values.fold(0, (a, b) => a + b);

    return Column(children: [
      // 条形图
      ...List.generate(labels.length, (i) {
        final val = values[i];
        final maxVal = 255.0;
        final pct = (val / maxVal).clamp(0.0, 1.0);
        final color = _statColor(val);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(labels[i],
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              Text('$val', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.grey[850],
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 最高档标志
              if (val > 100) const Icon(Icons.star, color: Colors.amber, size: 12),
            ],
          ),
        );
      }),
      const SizedBox(height: 6),
      Text('种族值总和: $total',
          style: TextStyle(fontSize: 13, color: Colors.amber[300], fontWeight: FontWeight.bold)),
    ]);
  }

  Color _statColor(int val) {
    if (val >= 120) return Colors.red[400]!;
    if (val >= 90) return Colors.orange[400]!;
    if (val >= 60) return Colors.amber[400]!;
    return Colors.grey[400]!;
  }

  // ─── 工具 ─────────────────────────────────────────
  List<String> _parseTypes(Map<String, dynamic> p) {
    final types = <String>[];
    if (p['type'] is List) types.addAll((p['type'] as List).cast<String>());
    final type2 = (p['type2'] ?? '').toString();
    if (type2.isNotEmpty) types.add(type2);
    return types;
  }

  String _abilityStr(Map<String, dynamic> p) {
    final a1 = (p['ability1'] ?? '-').toString();
    final a2 = (p['ability2'] ?? '').toString();
    return a2.isNotEmpty ? '$a1 / $a2' : a1;
  }

  String _evStr(Map<String, dynamic> p, String key) {
    final v = (p[key] as int?) ?? 0;
    return v > 0 ? '$v' : '0';
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber[300])),
          const Divider(color: Colors.grey, height: 20),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    const colors = {
      '一般': Color(0xFFA8A878), '火': Color(0xFFF08030),
      '水': Color(0xFF6890F0), '草': Color(0xFF78C850),
      '电': Color(0xFFF8D030), '冰': Color(0xFF98D8D8),
      '格斗': Color(0xFFC03028), '毒': Color(0xFFA040A0),
      '地面': Color(0xFFE0C068), '飞行': Color(0xFFA890F0),
      '超能力': Color(0xFFF85888), '虫': Color(0xFFA8B820),
      '岩石': Color(0xFFB8A038), '幽灵': Color(0xFF705898),
      '龙': Color(0xFF7038F8), '恶': Color(0xFF705848),
      '钢': Color(0xFFB8B8D0), '妖精': Color(0xFFEE99AC),
    };
    return colors[type] ?? Colors.grey;
  }
}
