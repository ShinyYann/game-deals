import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/type_chart.dart';

class EnhancedPokemonDetailPage extends StatefulWidget {
  final int ndex;
  final bool initialShiny;

  const EnhancedPokemonDetailPage({
    super.key,
    required this.ndex,
    this.initialShiny = false,
  });

  @override
  State<EnhancedPokemonDetailPage> createState() => _EnhancedPokemonDetailPageState();
}

class _EnhancedPokemonDetailPageState extends State<EnhancedPokemonDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _isShiny = false;
  bool _isMega = false;
  Map<String, dynamic>? _pokemonData;
  List<Map<String, dynamic>> _evoChain = [];
  Map<String, dynamic>? _description;

  final _apiBase = 'http://8.153.97.56/api/poke/';

  // Known mega-capable pokemon
  static const _megaCapable = {
    3, 6, 9, 15, 18, 65, 80, 94, 115, 127, 130, 142, 150, 181, 208,
    212, 214, 229, 248, 254, 257, 260, 282, 302, 303, 306, 308, 310,
    319, 323, 334, 354, 359, 362, 373, 376, 380, 381, 383, 384, 428,
    445, 448, 460, 475, 531,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isShiny = widget.initialShiny;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load pokemon data directly from the single pokemon endpoint
      final resp = await _httpGet('pokemon/${widget.ndex}');
      final data = jsonDecode(resp) as Map<String, dynamic>;
      setState(() => _pokemonData = data);

      // Load evolution chain
      try {
        final evoResp = await _httpGet('evolution/${widget.ndex}');
        final evoData = jsonDecode(evoResp);
        _evoChain = (evoData['chain'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } catch (_) {}

      // Load base stats (种族值)
      try {
        final statsResp = await _httpGet('base_stats/single/${widget.ndex}');
        final statsData = jsonDecode(statsResp) as Map<String, dynamic>;
        data.addAll(statsData); // merge into main pokemonData
      } catch (_) {}

      // Load description
      try {
        final descResp = await _httpGet('description/${widget.ndex}');
        final descData = jsonDecode(descResp);
        final descStr = descData['description']?.toString() ?? '';
        final gameStr = descData['game']?.toString() ?? '';
        _description = {'description': descStr, 'game': gameStr};
      } catch (_) {}

      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<String> _httpGet(String path) async {
    final uri = Uri.parse('$_apiBase$path');
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    return resp.body;
  }

  String _spriteUrl({bool shiny = false, bool mega = false}) {
    final padded = widget.ndex.toString().padLeft(3, '0');
    if (mega) {
      return 'https://assets.pokemon.com/assets/cms2/img/pokedex/full/${padded}_f2.png';
    }
    if (shiny) {
      return 'http://8.153.97.56/api/poke/sprite/shiny/${widget.ndex}';
    }
    return 'https://assets.pokemon.com/assets/cms2/img/pokedex/full/$padded.png';
  }

  bool get _hasMega => _megaCapable.contains(widget.ndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          _pokemonData != null ? (_pokemonData!['name_zh'] ?? 'Pokémon #${widget.ndex}').toString() : '#${widget.ndex}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Shiny toggle
          IconButton(
            icon: Icon(
              _isShiny ? Icons.star : Icons.star_border,
              color: _isShiny ? Colors.amberAccent : Colors.grey,
            ),
            tooltip: '闪光形态',
            onPressed: () => setState(() => _isShiny = !_isShiny),
          ),
          // Mega toggle
          if (_hasMega)
            IconButton(
              icon: Text('M', style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isMega ? Colors.purpleAccent : Colors.grey,
              )),
              tooltip: 'Mega进化',
              onPressed: () => setState(() => _isMega = !_isMega),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header image + info
                _buildHeader(),
                // TabBar
                Container(
                  color: const Color(0xFF1A1A2E),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.amberAccent,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.amberAccent,
                    tabs: const [
                      Tab(icon: Icon(Icons.bar_chart, size: 18), text: '能力'),
                      Tab(icon: Icon(Icons.local_fire_department, size: 18), text: '相性'),
                      Tab(icon: Icon(Icons.loop, size: 18), text: '进化'),
                      Tab(icon: Icon(Icons.menu_book, size: 18), text: '图鉴'),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsTab(),
                      _buildEffectivenessTab(),
                      _buildEvolutionTab(),
                      _buildDescriptionTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final pkm = _pokemonData;
    if (pkm == null) return const SizedBox(height: 200);

    final nameZh = pkm['name_zh']?.toString() ?? '';
    final nameEn = pkm['name_en']?.toString() ?? '';
    final nameJp = pkm['name_jp']?.toString() ?? '';
    final type = pkm['type']?.toString() ?? '';
    final type2 = pkm['type2']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTypeColor(type).withAlpha(60),
            type2.isNotEmpty ? _getTypeColor(type2).withAlpha(40) : const Color(0xFF1A1A2E),
            const Color(0xFF1A1A2E),
          ],
        ),
      ),
      child: Column(children: [
        // Main sprite
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _spriteUrl(shiny: _isShiny, mega: _isMega),
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, _) => Image.network(
              _spriteUrl(shiny: false, mega: false),
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(height: 120),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Names
        Text(
          nameZh,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Opacity(
          opacity: 0.7,
          child: Text(
            '$nameEn  $nameJp'.trim(),
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ),
        const SizedBox(height: 4),
        // Types
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [type, if (type2.isNotEmpty) type2].map((t) {
            if (t.isEmpty) return const SizedBox();
            final color = _getTypeColor(t);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(180),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(typeIcons[t] ?? '', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList(),
        ),
        if (_isShiny || _isMega)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isShiny)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('✨ 闪光', style: TextStyle(fontSize: 11, color: Colors.amberAccent)),
                  ),
                if (_isShiny && _isMega) const SizedBox(width: 6),
                if (_isMega)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('⚡ Mega', style: TextStyle(fontSize: 11, color: Colors.purpleAccent)),
                  ),
              ],
            ),
          ),
      ]),
    );
  }

  // ───────── Tab 1: 能力(Base Stats) ─────────

  Widget _buildStatsTab() {
    final pkm = _pokemonData;
    if (pkm == null) return _emptyTab('数据加载中...');

    final stats = <String, int>{
      'HP': _safeInt(pkm['hp']),
      '攻击': _safeInt(pkm['attack']),
      '防御': _safeInt(pkm['defense']),
      '特攻': _safeInt(pkm['sp_attack']),
      '特防': _safeInt(pkm['sp_defense']),
      '速度': _safeInt(pkm['speed']),
    };

    final total = stats.values.fold(0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Stat bars
        ...stats.entries.map((e) => _buildStatBar(e.key, e.value, total)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amberAccent.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('种族值总和: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text('$total', style: TextStyle(color: Colors.amberAccent[200], fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 16),
        // Info grid
        _buildInfoGrid(pkm),
      ]),
    );
  }

  Widget _buildStatBar(String label, int value, int total) {
    final maxVal = 255;
    final ratio = (value / maxVal).clamp(0.0, 1.0);
    Color barColor;
    if (ratio >= 0.7) {
      barColor = Colors.green;
    } else if (ratio >= 0.4) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: 30,
          child: Text('$value', style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 10,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildInfoGrid(Map<String, dynamic> pkm) {
    final height = pkm['height']?.toString() ?? '';
    final weight = pkm['weight']?.toString() ?? '';
    final abilities = pkm['abilities'] as List? ?? [];
    final eggGroups = pkm['egg_groups'] as List? ?? [];
    final captureRate = pkm['capture_rate']?.toString() ?? '';
    final exp100 = pkm['exp_100']?.toString() ?? '';
    final evYield = pkm['ev_yield'] as List? ?? [];

    final infoItems = <MapEntry<String, String>>[
      MapEntry('身高', height.isNotEmpty ? '${height}m' : '-'),
      MapEntry('体重', weight.isNotEmpty ? '${weight}kg' : '-'),
      MapEntry('特性', abilities.isNotEmpty ? abilities.join(', ') : '-'),
      MapEntry('蛋群', eggGroups.isNotEmpty ? eggGroups.join(', ') : '-'),
      MapEntry('捕获率', captureRate.isNotEmpty ? captureRate : '-'),
      MapEntry('100级经验', exp100.isNotEmpty ? exp100 : '-'),
      MapEntry('努力值', evYield.isNotEmpty ? evYield.join(', ') : '-'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('基础信息', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...infoItems.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(item.key, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                Expanded(child: Text(item.value, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ───────── Tab 2: 属性相性 ─────────

  Widget _buildEffectivenessTab() {
    final pkm = _pokemonData;
    if (pkm == null) return _emptyTab('加载中...');

    // 服务端返回 type: ['电'] 是数组，需要解包
    List<String> typesList = [];
    final t1 = pkm['type'];
    if (t1 is List && t1.isNotEmpty) {
      typesList.add(t1.first.toString());
    } else if (t1 != null && t1.toString().isNotEmpty) {
      typesList.add(t1.toString());
    }
    final t2 = pkm['type2'];
    if (t2 is List && t2.isNotEmpty) {
      typesList.add(t2.first.toString());
    } else if (t2 != null && t2.toString().isNotEmpty) {
      typesList.add(t2.toString());
    }

    if (typesList.isEmpty) return _emptyTab('暂无属性数据');

    final effectiveness = TypeEffectiveness(typesList);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2x
          if (effectiveness.superEffective.isNotEmpty) ...[
            const Text('🟢 效果绝佳 (2x)', style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4,
              children: effectiveness.superEffective.map((t) => _typeChip(t, Colors.greenAccent)).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // 0.5x
          if (effectiveness.notVeryEffective.isNotEmpty) ...[
            const Text('🟡 效果不好 (0.5x)', style: TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4,
              children: effectiveness.notVeryEffective.map((t) => _typeChip(t, Colors.orangeAccent)).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // 0.25x
          if (effectiveness.quarterEffect.isNotEmpty) ...[
            const Text('🟠 效果极差 (0.25x)', style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4,
              children: effectiveness.quarterEffect.map((t) => _typeChip(t, Colors.deepOrangeAccent)).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // 0x
          if (effectiveness.noEffect.isNotEmpty) ...[
            const Text('🔴 没有效果 (0x)', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4,
              children: effectiveness.noEffect.map((t) => _typeChip(t, Colors.redAccent)).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // 1x
          const Text('⬜ 普通效果 (1x)', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            effectiveness.normalEffect.isEmpty ? '无' : effectiveness.normalEffect.join(' · '),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type, Color accent) {
    final color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(100), width: 0.5),
      ),
      child: Text(
        '$type ${typeIcons[type] ?? ''}',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ───────── Tab 3: 进化链 ─────────

  Widget _buildEvolutionTab() {
    if (_evoChain.isEmpty) {
      return _buildSimpleEvo();
    }

    // Try to build a visual chain from the server data
    return _buildServerEvoChain();
  }

  Widget _buildSimpleEvo() {
    // Fallback: show basic evolutions from pokemon data
    final pkm = _pokemonData;
    if (pkm == null) return _emptyTab('加载中...');

    final evolvesFrom = pkm['evolves_from'] as int?;
    final evolvesTo = pkm['evolves_to'] as List? ?? <int>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (evolvesFrom != null)
          _buildEvoNode(evolvesFrom, '进化自', isCurrent: false)
        else
          _buildEvoNone(),
        const SizedBox(height: 20),
        _buildEvoNode(widget.ndex, '当前', isCurrent: true),
        if (evolvesTo.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...evolvesTo.map((e) => _buildEvoNode(e, '进化成', isCurrent: false)),
        ] else
          const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildServerEvoChain() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        ..._evoChain.asMap().entries.map((entry) {
          final i = entry.key;
          final node = entry.value;
          final isCurrent = node['ndex'] == widget.ndex;
          final trigger = node['trigger']?.toString() ?? '';
          final minLevel = node['min_level']?.toString() ?? '';
          final item = node['item']?.toString() ?? '';

          String condition = '';
          if (minLevel.isNotEmpty) {
            condition = 'Lv.$minLevel进化';
          } else if (trigger == 'trade') {
            condition = '通信交换';
          } else if (trigger == 'use-item' && item.isNotEmpty) {
            condition = item;
          } else if (trigger == 'time-of-day') {
            condition = node['time_of_day'] == 'day' ? '白天' : '夜晚';
          } else if (item.isNotEmpty) {
            condition = '使用${item}';
          } else if (trigger.isNotEmpty) {
            condition = trigger;
          }

          return Column(children: [
            if (i > 0) ...[
              Icon(Icons.arrow_downward, color: Colors.grey[600], size: 20),
              const SizedBox(height: 8),
            ],
            _buildEvoNode(node['ndex'] as int? ?? 0, condition, isCurrent: isCurrent),
          ]);
        }),
      ]),
    );
  }

  Widget _buildEvoNode(int ndex, String label, {bool isCurrent = false}) {
    // Look up the name from _evoChain data or fallback
    String evoName = '#$ndex';
    for (final n in _evoChain) {
      if (n['ndex'] == ndex) {
        evoName = n['name_zh']?.toString() ?? evoName;
        break;
      }
    }
    // Fallback to _getPokemonName if not found in chain
    if (evoName == '#$ndex') {
      evoName = _getPokemonName(ndex);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF2A2A3E) : const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: Colors.amberAccent.withAlpha(80), width: 1.5)
            : null,
      ),
      child: Row(children: [
        // Sprite
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            ndex == widget.ndex
                ? _spriteUrl(shiny: _isShiny)
                : 'https://assets.pokemon.com/assets/cms2/img/pokedex/full/${ndex.toString().padLeft(3, '0')}.png',
            height: 56,
            width: 56,
            errorBuilder: (_, __, ___) => const SizedBox(height: 56, width: 56),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#$ndex',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              Text(
                evoName,
                style: TextStyle(
                  color: isCurrent ? Colors.amberAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.amberAccent.withAlpha(40) : Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isCurrent ? Colors.amberAccent : Colors.grey[400],
                fontSize: 11,
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildEvoNone() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(children: [
        Icon(Icons.block, color: Colors.grey, size: 20),
        SizedBox(width: 8),
        Text('未找到进化信息', style: TextStyle(color: Colors.grey)),
      ]),
    );
  }

  // ───────── Tab 4: 图鉴描述 ─────────

  Widget _buildDescriptionTab() {
    final pkm = _pokemonData;
    if (pkm == null) return _emptyTab('加载中...');

    final species = pkm['species']?.toString() ?? '';
    final desc = _description?['description']?.toString() ?? '';
    final game = _description?['game']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (species.isNotEmpty) ...[
            const Text('分类', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(species, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 16),
          ],
          if (desc.isNotEmpty) ...[
            const Text('图鉴描述', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Text(
                desc,
                style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.5),
              ),
            ),
            if (game.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('来源: $game', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ),
          ] else ...[
            _buildEvoNone(),
          ],
          const SizedBox(height: 20),
          // Basic info from server
          _buildInfoGrid(pkm),
        ],
      ),
    );
  }

  // ───────── Helper ─────────

  Widget _emptyTab(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(msg, style: TextStyle(color: Colors.grey[500])),
      ),
    );
  }

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  Color _getTypeColor(String type) {
    const colors = {
      '普通': Color(0xFFA8A878), '火': Color(0xFFF08030), '水': Color(0xFF6890F0),
      '草': Color(0xFF78C850), '电': Color(0xFFF8D030), '冰': Color(0xFF98D8D8),
      '格斗': Color(0xFFC03028), '毒': Color(0xFFA040A0), '地面': Color(0xFFE0C068),
      '飞行': Color(0xFFA890F0), '超能力': Color(0xFFF85888), '虫': Color(0xFFA8B820),
      '岩石': Color(0xFFB8A038), '幽灵': Color(0xFF705898), '龙': Color(0xFF7038F8),
      '恶': Color(0xFF705848), '钢': Color(0xFFB8B8D0), '妖精': Color(0xFFEE99AC),
    };
    return colors[type] ?? Colors.grey;
  }

  String _getPokemonName(int ndex) {
    if (ndex == widget.ndex && _pokemonData != null) {
      return _pokemonData!['name_zh']?.toString() ?? '#$ndex';
    }
    return '#$ndex';
  }
}
