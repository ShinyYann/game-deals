import 'package:flutter/material.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';

class PokopiaPokedexPage extends StatefulWidget {
  const PokopiaPokedexPage({super.key});
  @override
  State<PokopiaPokedexPage> createState() => _PokopiaPokedexPageState();
}

class _PokopiaPokedexPageState extends State<PokopiaPokedexPage> {
  List<PokopiaPokemon> _allPokemon = [];
  List<PokopiaPokemon> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Set<String> _filteredHabitats = {};
  String? _selectedHabitat;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final pokes = await PokopiaService.fetchPokemon();
    if (mounted) {
      setState(() {
        _allPokemon = pokes;
        _filtered = pokes;
        _filteredHabitats = pokes.map((p) => p.habitat).where((h) => h.isNotEmpty).toSet();
        _loading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _allPokemon.where((p) {
        if (q.isNotEmpty && !p.name.toLowerCase().contains(q) && !p.habitat.toLowerCase().contains(q)) return false;
        if (_selectedHabitat != null && !p.habitat.contains(_selectedHabitat!)) return false;
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宝可梦图鉴')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)]),
        ),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '搜索宝可梦...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, color: Colors.white38), onPressed: () { _searchCtrl.clear(); })
                        : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                // Habitat filters
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _habitatChip(null, '全部'),
                      ..._filteredHabitats.take(15).map((h) => _habitatChip(h, h)),
                    ],
                  ),
                ),
                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text('共 ${_filtered.length} 只', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                // Grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, childAspectRatio: 0.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) => _PokemonCard(pokemon: _filtered[i]),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _habitatChip(String? habitat, String label) {
    final active = _selectedHabitat == habitat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () { setState(() { _selectedHabitat = active ? null : habitat; }); _onSearch(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: active ? const Color(0xFF7C4DFF) : Colors.white.withOpacity(0.08),
          ),
          child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white60, fontSize: 12)),
        ),
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final PokopiaPokemon pokemon;
  const _PokemonCard({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.06),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sprite
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.network(pokemon.spriteUrl, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, color: Colors.white24, size: 36)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                color: Colors.black26,
              ),
              child: Text(pokemon.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PokemonDetailPage(pokemon: pokemon)));
  }
}

class _PokemonDetailPage extends StatelessWidget {
  final PokopiaPokemon pokemon;
  const _PokemonDetailPage({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)]),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Big sprite
              Hero(
                tag: 'pokemon_${pokemon.id}',
                child: Image.network(pokemon.spriteUrl, height: 200, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon, size: 100, color: Colors.white24)),
              ),
              const SizedBox(height: 24),
              _infoRow('栖息地', pokemon.habitat),
              _infoRow('出没时间', pokemon.time),
              _infoRow('天气条件', pokemon.weather),
              _infoRow('特长', pokemon.ability),
              if (pokemon.pokopiaId.isNotEmpty) _infoRow('Pokopia 编号', pokemon.pokopiaId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
