import 'package:flutter/material.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';

class PokopiaHabitatsPage extends StatefulWidget {
  const PokopiaHabitatsPage({super.key});
  @override
  State<PokopiaHabitatsPage> createState() => _PokopiaHabitatsPageState();
}

class _PokopiaHabitatsPageState extends State<PokopiaHabitatsPage> {
  List<PokopiaHabitat> _habitats = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); _searchCtrl.addListener(_onSearch); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final h = await PokopiaService.fetchHabitats();
    if (mounted) setState(() { _habitats = h; _loading = false; });
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) { _load(); return; }
    PokopiaService.fetchHabitats(query: q).then((h) {
      if (mounted) setState(() => _habitats = h);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('栖息地')),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)])),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '搜索栖息地...', hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true, fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 1.3, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: _habitats.length,
                  itemBuilder: (context, i) => _HabitatCard(habitat: _habitats[i]),
                ),
              ),
            ]),
      ),
    );
  }
}

class _HabitatCard extends StatelessWidget {
  final PokopiaHabitat habitat;
  const _HabitatCard({required this.habitat});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A2E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white24))),
            const SizedBox(height: 16),
            Text(habitat.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('建造要求：${habitat.requirements}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (habitat.pokemon.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('出现宝可梦（${habitat.pokemon.length} 只）', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4, runSpacing: 4,
                children: habitat.pokemon.take(20).map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
          ]),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [Color(0xFF1B5E20).withOpacity(0.6), Color(0xFF004D40).withOpacity(0.4)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.nature, color: Color(0xFF69F0AE), size: 20),
            const Spacer(),
            Text('#${habitat.id}', style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ]),
          const Spacer(),
          Text(habitat.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(habitat.requirements, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (habitat.pokemon.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.pets, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text('${habitat.pokemon.length} 只', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ],
        ]),
      ),
    );
  }
}
