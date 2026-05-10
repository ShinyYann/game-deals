import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PokemonShinyPage extends StatefulWidget {
  const PokemonShinyPage({super.key});

  @override
  State<PokemonShinyPage> createState() => _PokemonShinyPageState();
}

class _PokemonShinyPageState extends State<PokemonShinyPage> {
  List<Map<String, dynamic>> _shinyCollection = [];
  bool _loading = true;
  final _apiBase = 'http://8.153.97.56/api/poke/';

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('shiny_collection') ?? '[]';
    setState(() {
      _shinyCollection = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  Future<void> _saveCollection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shiny_collection', jsonEncode(_shinyCollection));
  }

  void _removePokemon(int index) {
    setState(() => _shinyCollection.removeAt(index));
    _saveCollection();
  }

  String _shinySpriteUrl(int ndex) {
    return 'http://8.153.97.56/api/poke/sprite/shiny/$ndex';
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        List<Map<String, dynamic>> searchResults = [];
        bool searching = false;

        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Handle bar
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('添加闪光', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '输入宝可梦中文名搜索...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: searching ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ) : null,
                    filled: true,
                    fillColor: const Color(0xFF2A2A3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) async {
                    if (v.isEmpty) { setDialogState(() { searchResults = []; }); return; }
                    setDialogState(() { searching = true; });
                    try {
                      final uri = Uri.parse('http://8.153.97.56/api/poke/search?q=${Uri.encodeComponent(v)}');
                      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
                      final data = jsonDecode(resp.body);
                      searchResults = (data['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                    } catch (_) { searchResults = []; }
                    setDialogState(() { searching = false; });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: searchResults.isEmpty
                    ? Center(child: Text(searchCtrl.text.isEmpty ? '输入中文名搜索宝可梦' : '未找到', style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (ctx, i) {
                          final p = searchResults[i];
                          final ndex = p['ndex'];
                          final name = p['name_zh'] ?? '?';
                          final en = p['name_en'] ?? '';
                          final padded = (ndex ?? 0).toString().padLeft(3, '0');
                          final alreadyOwned = _shinyCollection.any((sp) => sp['ndex'] == ndex);
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'https://assets.pokemon.com/assets/cms2/img/pokedex/full/$padded.png',
                                height: 40, width: 40,
                                errorBuilder: (_, __, ___) => const SizedBox(height: 40, width: 40),
                              ),
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: Text('#$ndex $en', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            trailing: alreadyOwned
                              ? Icon(Icons.check_circle, color: Colors.green[400], size: 22)
                              : TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx2);
                                    _showLocationNoteDialog(ndex, name, padded);
                                  },
                                  child: const Text('添加', style: TextStyle(color: Colors.amberAccent)),
                                ),
                          );
                        },
                      ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  void _showLocationNoteDialog(int ndex, String name, String padded) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(
            'https://assets.pokemon.com/assets/cms2/img/pokedex/full/$padded.png',
            height: 32, width: 32)),
          const SizedBox(width: 8),
          Text('$name ✨', style: const TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择或输入获得来源', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            // Predefined options
            Wrap(spacing: 8, runSpacing: 4, children: [
              _noteChip('野外捕捉', noteCtrl),
              _noteChip('活动赠送', noteCtrl),
              _noteChip('蛋孵化', noteCtrl),
              _noteChip('交换获得', noteCtrl),
              _noteChip('连锁捕捉', noteCtrl),
              _noteChip('太晶团体战', noteCtrl),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '手动输入来源...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true, fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              _addPokemon(ndex, name, noteCtrl.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
            child: const Text('确认添加', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _noteChip(String label, TextEditingController ctrl) {
    return GestureDetector(
      onTap: () => ctrl.text = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amberAccent.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent.withAlpha(60)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
      ),
    );
  }

  void _addPokemon(int ndex, String name, String location) {
    if (_shinyCollection.any((p) => p['ndex'] == ndex)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已存在！'), duration: Duration(seconds: 1)));
      return;
    }
    setState(() {
      _shinyCollection.add({
        'ndex': ndex,
        'name_zh': name,
        'location': location,  // 获得地点/来源备注
        'added_at': DateTime.now().toIso8601String(),
      });
    });
    _saveCollection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ 闪光收藏', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.amberAccent),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F0F23),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shinyCollection.isEmpty
              ? _buildEmptyState()
              : _buildShinyList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '还没有收集到闪光呢~',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 添加你的第一只闪光',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加闪光'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShinyList() {
    return RefreshIndicator(
      onRefresh: _loadCollection,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _shinyCollection.length,
        itemBuilder: (ctx, i) {
          final pokemon = _shinyCollection[i];
          final ndex = pokemon['ndex'] as int? ?? 0;
          final name = pokemon['name_zh'] as String? ?? '#$ndex';

          return Dismissible(
            key: Key('shiny_$ndex'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
            onDismissed: (_) => _removePokemon(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade800.withAlpha(60), width: 1),
              ),
              child: Row(
                children: [
                  // Shiny sprite
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _shinySpriteUrl(ndex),
                      height: 52,
                      width: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, _) => Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((pokemon['location'] ?? '').isNotEmpty)
                          Text(
                            pokemon['location'].toString(),
                            style: TextStyle(color: Colors.grey[500], fontSize: 9),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '#$ndex',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: () => _removePokemon(i),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close, color: Colors.grey[600], size: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
