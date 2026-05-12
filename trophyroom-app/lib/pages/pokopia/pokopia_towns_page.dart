import 'package:flutter/material.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';

class PokopiaTownsPage extends StatefulWidget {
  const PokopiaTownsPage({super.key});
  @override
  State<PokopiaTownsPage> createState() => _PokopiaTownsPageState();
}

class _PokopiaTownsPageState extends State<PokopiaTownsPage> {
  List<PokopiaTown> _towns = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final t = await PokopiaService.fetchTowns();
    if (mounted) setState(() { _towns = t; _loading = false; });
  }

  final _gradients = [
    [const Color(0xFFFF6E40), const Color(0xFFD84315)],
    [const Color(0xFF0288D1), const Color(0xFF01579B)],
    [const Color(0xFF558B2F), const Color(0xFF33691E)],
    [const Color(0xFF7B1FA2), const Color(0xFF4A148C)],
    [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('城镇巡礼')),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)])),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _towns.length,
              itemBuilder: (context, i) => _TownCard(town: _towns[i], colors: _gradients[i % _gradients.length]),
            ),
      ),
    );
  }
}

class _TownCard extends StatelessWidget {
  final PokopiaTown town;
  final List<Color> colors;
  const _TownCard({required this.town, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(town.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(town.sub, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        Text(town.desc, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
