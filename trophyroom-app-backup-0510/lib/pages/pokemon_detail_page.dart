/// 宝可梦详情页

import 'package:flutter/material.dart';

class PokemonDetailPage extends StatelessWidget {
  final Map<String, dynamic> pokemon;
  final String sprite;

  const PokemonDetailPage({
    super.key,
    required this.pokemon,
    required this.sprite,
  });

  @override
  Widget build(BuildContext context) {
    final ndex = (pokemon['ndex'] as int?) ?? 0;
    final nameZh = (pokemon['name_zh'] ?? '??').toString();
    final nameEn = (pokemon['name_en'] ?? '').toString();
    final nameJp = (pokemon['name_jp'] ?? '').toString();
    final types = <String>[];
    if (pokemon['type'] is List) {
      types.addAll((pokemon['type'] as List).cast<String>());
    }
    final type2 = (pokemon['type2'] ?? '').toString();
    if (type2.isNotEmpty) types.add(type2);

    final species = (pokemon['species'] ?? '').toString();
    final height = (pokemon['height'] ?? '-').toString();
    final weight = (pokemon['weight'] ?? '-').toString();
    final ability1 = (pokemon['ability1'] ?? '-').toString();
    final ability2 = (pokemon['ability2'] ?? '').toString();
    final abilityHidden = (pokemon['ability_hidden'] ?? '').toString();
    final egg1 = (pokemon['egg_group1'] ?? '').toString();
    final egg2 = (pokemon['egg_group2'] ?? '').toString();
    final color = (pokemon['color'] ?? '').toString();
    final catchRate = (pokemon['catch_rate'] ?? '-').toString();
    final expYield = (pokemon['exp_yield'] ?? '-').toString();
    final genderDiff = pokemon['gender_diff'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text('#${ndex.toString().padLeft(3, '0')} $nameZh'),
        backgroundColor: const Color(0xFF1A1A2E),
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
                  Image.network(sprite, width: 120, height: 120, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.catching_pokemon, color: Colors.grey[700], size: 64)),
                  const SizedBox(height: 8),
                  Text(nameZh,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (nameEn.isNotEmpty)
                    Text(nameEn,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  if (nameJp.isNotEmpty)
                    Text(nameJp,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  // 属性标签
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: types.map((t) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _typeColor(t).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _typeColor(t).withOpacity(0.5)),
                      ),
                      child: Text(t,
                          style: TextStyle(color: _typeColor(t), fontWeight: FontWeight.bold, fontSize: 14)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 基础数据 ──
            _section('基础数据', [
              _row('分类', '$species 宝可梦'),
              _row('身高', '${height}m'),
              _row('体重', '${weight}kg'),
              _row('颜色', color),
              if (genderDiff) _row('性别差异', '有'),
            ]),

            // ── 对战数据 ──
            _section('对战数据', [
              _row('特性', ability1 + (ability2.isNotEmpty ? ' / $ability2' : '')),
              if (abilityHidden.isNotEmpty) _row('隐藏特性', abilityHidden),
              _row('捕捉率', catchRate),
              _row('基础经验', expYield),
            ]),

            // ── 培育数据 ──
            _section('培育数据', [
              if (egg1.isNotEmpty) _row('蛋群', egg1 + (egg2.isNotEmpty ? ' / $egg2' : '')),
            ]),
          ],
        ),
      ),
    );
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
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber[300])),
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
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
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
