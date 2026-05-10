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
    bool includeName = true;
    String method = ''; // e.g., 蛋孵化, 野外捕捉
    String extra = '';  // custom text

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(
              'https://assets.pokemon.com/assets/cms2/img/pokedex/full/$padded.png',
              height: 32, width: 32)),
            const SizedBox(width: 8),
            Text('$name ✨', style: const TextStyle(color: Colors.white, fontSize: 18)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('获得方式', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                // Method chips
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _noteChip('蛋孵化', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                  _noteChip('野外捕捉', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                  _noteChip('连锁捕捉', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                  _noteChip('交换获得', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                  _noteChip('活动赠送', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                  _noteChip('太晶团体战', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                  _noteChip('DLC领取', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                  _noteChip('随机遭遇', method, (v) => setDialogState(() => method = v == method ? '' : v)),
                ]),
                const SizedBox(height: 12),
                // Include name toggle
                Row(children: [
                  SizedBox(
                    height: 24, width: 24,
                    child: Checkbox(
                      value: includeName,
                      onChanged: (v) => setDialogState(() => includeName = v ?? true),
                      fillColor: WidgetStateProperty.all(Colors.amberAccent),
                      checkColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('备注包含宝可梦名字', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                // Extra note
                const Text('自定义附言', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '比如: 跟随我3年了\n或者: 第1560次孵蛋出的',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0D0D1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                // Preview
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amberAccent.withAlpha(40)),
                  ),
                  child: Text(
                    _buildShinyNotePreview(name, method, extra, includeName, noteCtrl.text),
                    style: TextStyle(color: Colors.amberAccent[200], fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('预览', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                final finalNote = _buildShinyNote(name, method, extra, includeName, noteCtrl.text);
                _addPokemon(ndex, name, finalNote);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
              child: const Text('确认添加', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteChip(String label, String selected, void Function(String) onTap) {
    final isSelected = label == selected;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amberAccent.withAlpha(60) : Colors.amberAccent.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amberAccent : Colors.amberAccent.withAlpha(40),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.amber : Colors.amberAccent,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _buildShinyNote(String name, String method, String extra, bool includeName, String custom) {
    final parts = <String>[];
    if (includeName) parts.add(name);
    if (method.isNotEmpty) parts.add(method);
    if (custom.isNotEmpty) parts.add(custom);
    return parts.join(' · ');
  }

  String _buildShinyNotePreview(String name, String method, String extra, bool includeName, String custom) {
    return _buildShinyNote(name, method, extra, includeName, custom);
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
