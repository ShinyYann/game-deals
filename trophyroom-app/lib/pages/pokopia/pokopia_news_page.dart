import 'package:flutter/material.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';

class PokopiaNewsPage extends StatefulWidget {
  const PokopiaNewsPage({super.key});
  @override
  State<PokopiaNewsPage> createState() => _PokopiaNewsPageState();
}

class _PokopiaNewsPageState extends State<PokopiaNewsPage> {
  List<PokopiaNews> _news = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final n = await PokopiaService.fetchNews();
    if (mounted) setState(() { _news = n; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('最新情报')),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)])),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _news.length,
                itemBuilder: (context, i) => _NewsCard(news: _news[i]),
              ),
            ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final PokopiaNews news;
  const _NewsCard({required this.news});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withOpacity(0.06)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 100, height: 80,
              child: news.cover.isNotEmpty
                ? Image.network(news.cover, width: 100, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.indigo.shade900, child: const Icon(Icons.article, color: Colors.white24)))
                : Container(color: Colors.indigo.shade900, child: const Icon(Icons.article, color: Colors.white24)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(news.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                if (news.startDatetime.isNotEmpty)
                  Text(news.startDatetime.substring(0, 10), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: Colors.white24),
          ),
        ]),
      ),
    );
  }
}
