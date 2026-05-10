/// 🐉 宝可梦图鉴 — 全图鉴 + 区域分类筛选
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'enhanced_pokemon_detail_page.dart';

const String _apiBase = 'http://8.153.97.56/api/poke';

/// 地区编号范围
const _regions = <_Region>[
  _Region('全部', 0, 9999),
  _Region('关都', 1, 151),
  _Region('城都', 152, 251),
  _Region('丰缘', 252, 386),
  _Region('神奥', 387, 493),
  _Region('合众', 494, 649),
  _Region('卡洛斯', 650, 721),
  _Region('阿罗拉', 722, 809),
  _Region('伽勒尔', 810, 898),
  _Region('洗翠', 899, 905),
  _Region('帕底亚', 906, 1010),
];

class _Region {
  final String name;
  final int start;
  final int end;
  const _Region(this.name, this.start, this.end);
}

class PokedexGridPage extends StatefulWidget {
  const PokedexGridPage({super.key});
  @override
  State<PokedexGridPage> createState() => _PokedexGridPageState();
}

class _PokedexGridPageState extends State<PokedexGridPage> {
  List<Map<String, dynamic>> _pokemon = [];
  bool _loading = true;
  String? _error;
  int _total = 0;
  String _search = '';
  int _regionIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$_apiBase/pokedex'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = jsonDecode(res.body);
      final rawList = data['pokemon'] as List? ?? [];
      _total = (data['meta'] as Map?)?['count'] ?? rawList.length;
      _pokemon = rawList.cast<Map<String, dynamic>>()
        ..sort((a, b) {
          final na = (a['ndex'] as num?)?.toInt() ?? 0;
          final nb = (b['ndex'] as num?)?.toInt() ?? 0;
          return na.compareTo(nb);
        });
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _pokemon;
    // 区域筛选
    if (_regionIndex > 0) {
      final r = _regions[_regionIndex];
      list = list.where((p) {
        final ndex = (p['ndex'] as num?)?.toInt() ?? 0;
        return ndex >= r.start && ndex <= r.end;
      }).toList();
    }
    // 搜索
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) {
        final zh = (p['name_zh'] ?? '').toString();
        final en = (p['name_en'] ?? '').toString();
        final ndex = (p['ndex'] as int?) ?? 0;
        return zh.contains(q) || en.toLowerCase().contains(q) || ndex.toString() == q;
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: Text('${_regions[_regionIndex].name}图鉴'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('${_filtered.length} 只',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索宝可梦名或编号...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF252540),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // 地区筛选标签
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _regions.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _regionIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _regionIndex == i
                          ? const Color(0xFFE53935)
                          : const Color(0xFF252540),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _regions[i].name,
                      style: TextStyle(
                        fontSize: 12,
                        color: _regionIndex == i ? Colors.white : Colors.grey[400],
                        fontWeight: _regionIndex == i ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 内容
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE53935)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('加载失败', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text('没有找到「$_search」',
            style: TextStyle(color: Colors.grey[500])),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) => _pokemonCard(context, list[i]),
    );
  }

  Widget _pokemonCard(BuildContext context, Map<String, dynamic> p) {
    final ndex = (p['ndex'] as int?) ?? 0;
    final name = (p['name_zh'] ?? '??').toString();
    final types = _parseTypes(p);
    final ndexStr = ndex.toString().padLeft(3, '0');
    final sprite =
        'https://assets.pokemon.com/assets/cms2/img/pokedex/full/$ndexStr.png';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EnhancedPokemonDetailPage(ndex: p['ndex'] as int, initialShiny: false),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _typeColor(types.isNotEmpty ? types[0] : '').withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('#${ndex.toString().padLeft(3, '0')}',
                style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            Image.network(
              sprite, width: 60, height: 60,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.catching_pokemon, color: Colors.grey[700], size: 32),
            ),
            Text(name,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (types.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: types.map((t) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _typeColor(t).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t, style: TextStyle(color: _typeColor(t), fontSize: 8)),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _parseTypes(Map<String, dynamic> p) {
    final types = <String>[];
    if (p['type'] is List) types.addAll((p['type'] as List).cast<String>());
    final type2 = (p['type2'] ?? '').toString();
    if (type2.isNotEmpty) types.add(type2);
    return types;
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
