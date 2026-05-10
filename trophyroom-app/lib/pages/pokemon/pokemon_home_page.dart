/// 🐉 宝可梦攻略入口 — 卡片导航页
import 'package:flutter/material.dart';
import 'pokedex_grid_page.dart';
import 'pokemon_news_page.dart';
import 'pokemon_events_page.dart';
import 'pokemon_gifts_page.dart';
import 'pokemon_shiny_page.dart';

class PokemonHomePage extends StatelessWidget {
  const PokemonHomePage({super.key});

  static const _cards = <_MenuCard>[
    _MenuCard(title: '全图鉴', subtitle: '搜索/筛选/详情', icon: Icons.menu_book, color: Color(0xFFE53935)),
    _MenuCard(title: '宝可梦新闻', subtitle: '52Pokemon 最新资讯', icon: Icons.newspaper, color: Color(0xFF2196F3)),
    _MenuCard(title: '近期活动', subtitle: '即将到来的活动', icon: Icons.event, color: Color(0xFF9C27B0)),
    _MenuCard(title: '活动赠送', subtitle: '神秘礼物信息', icon: Icons.card_giftcard, color: Color(0xFFFF9800)),
    _MenuCard(title: '我的闪光', subtitle: '已拥有的异色宝可梦', icon: Icons.auto_awesome, color: Color(0xFF00BCD4)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('🐉 宝可梦'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Icon(Icons.catching_pokemon, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('宝可梦攻略站',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('图鉴 · 新闻 · 活动 · 闪光收集',
                        style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 20),
            // 功能卡片
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _cards.length,
                itemBuilder: (_, i) => _buildCard(context, _cards[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _MenuCard card) {
    return GestureDetector(
      onTap: () {
        final pages = <Widget>[
          const PokedexGridPage(),
          const PokemonNewsPage(),
          const PokemonEventsPage(),
          const PokemonGiftsPage(),
          const PokemonShinyPage(),
        ];
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => pages[_cards.indexOf(card)]),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card.color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: card.color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: card.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(card.icon, color: card.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(card.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(card.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _MenuCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _MenuCard({required this.title, required this.subtitle, required this.icon, required this.color});
}
