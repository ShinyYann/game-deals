import 'package:flutter/material.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';
import 'pokopia_events_page.dart';
import 'pokopia_news_page.dart';
import 'pokopia_pokedex_page.dart';
import 'pokopia_habitats_page.dart';
import 'pokopia_characters_page.dart';
import 'pokopia_towns_page.dart';
import 'pokopia_guides_page.dart';

/// Gradient color schemes for the 8 feature cards
const List<List<Color>> _cardGradients = [
  [Color(0xFF7C4DFF), Color(0xFF448AFF)], // 紫蓝 - 活动
  [Color(0xFFFF6E40), Color(0xFFFFAB40)], // 橙黄 - 情报
  [Color(0xFF00E676), Color(0xFF00BCD4)], // 青绿 - 宝可梦
  [Color(0xFF76FF03), Color(0xFF00E676)], // 绿 - 栖息地
  [Color(0xFFFF4081), Color(0xFFFF6E40)], // 粉橙 - 物品
  [Color(0xFF448AFF), Color(0xFF7C4DFF)], // 蓝紫 - 角色
  [Color(0xFF18FFFF), Color(0xFF448AFF)], // 青蓝 - 城镇
  [Color(0xFFFFD740), Color(0xFFFF6E40)], // 黄橙 - 攻略
];

const List<IconData> _cardIcons = [
  Icons.event, Icons.article, Icons.pets, Icons.nature,
  Icons.chair, Icons.people, Icons.location_city, Icons.book,
];

const List<String> _cardLabels = [

class PokopiaHomePage extends StatefulWidget {
  const PokopiaHomePage({super.key});
  @override
  State<PokopiaHomePage> createState() => _PokopiaHomePageState();
}

class _PokopiaHomePageState extends State<PokopiaHomePage> {
  PokopiaSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final s = await PokopiaService.fetchSummary();
    if (mounted) setState(() { _summary = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pokopia 宝可梦绘', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A), Color(0xFF1B2838)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                // Hero banner
                SliverToBoxAdapter(child: _buildHeroBanner()),
                // Counts row
                SliverToBoxAdapter(child: _buildCountRow()),
                // Feature cards grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FeatureCard(index: index),
                      childCount: _cardLabels.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF1A237E)]),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10, top: -10,
            child: Icon(Icons.auto_awesome, size: 100, color: Colors.white.withOpacity(0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pokopia', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('宝可梦 · 慢生活 · 沙盒', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 12),
                Text('攻略·图鉴·活动 一站式查询', style: TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountRow() {
    if (_loading || _summary == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    final c = _summary!.counts;
    final items = [
      ('活动', c['events'] ?? 0), ('宝可梦', c['pokemon'] ?? 0),
      ('栖息地', c['habitats'] ?? 0), ('攻略', c['guides'] ?? 0),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((e) => _CountChip(label: e.$1, count: e.$2)).toList(),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  const _CountChip({required this.label, required this.count});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final int index;
  const _FeatureCard({required this.index});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Widget page;
        switch (index) {
          case 0: page = const PokopiaEventsPage(); break;
          case 1: page = const PokopiaNewsPage(); break;
          case 2: page = const PokopiaPokedexPage(); break;
          case 3: page = const PokopiaHabitatsPage(); break;
          case 4:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('物品图鉴即将上线'), duration: Duration(seconds: 1)),
            );
            return;
          case 5: page = const PokopiaCharactersPage(); break;
          case 6: page = const PokopiaTownsPage(); break;
          case 7: page = const PokopiaGuidesPage(); break;
          default: return;
        }
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: _cardGradients[index],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _cardGradients[index][0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8, bottom: -8,
              child: Icon(_cardIcons[index], size: 64, color: Colors.white.withOpacity(0.10)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(_cardIcons[index], color: Colors.white, size: 28),
                  const Spacer(),
                  Text(
                    _cardLabels[index],
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
