/// ✨ 我的闪光 — 手动添加已拥有的异色宝可梦
/// 使用 SharedPreferences 持久化存储
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PokemonShinyPage extends StatefulWidget {
  const PokemonShinyPage({super.key});
  @override
  State<PokemonShinyPage> createState() => _PokemonShinyPageState();
}

class _PokemonShinyPageState extends State<PokemonShinyPage> {
  List<Map<String, dynamic>> _shinies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('shiny_collection') ?? '[]';
    setState(() {
      _shinies = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shiny_collection', jsonEncode(_shinies));
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final ndexCtrl = TextEditingController(text: '25');
    final sourceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('添加闪光', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField('全国编号', ndexCtrl, hint: '如 25'),
              const SizedBox(height: 8),
              _inputField('中文名', nameCtrl, hint: '必填'),
              const SizedBox(height: 8),
              _inputField('来源（可选）', sourceCtrl, hint: '孵蛋/遭遇/活动/交换'),
              const SizedBox(height: 8),
              _inputField('备注', noteCtrl, hint: '可选'),
              const SizedBox(height: 8),
              _inputField('获得日期', dateCtrl, hint: 'YYYY-MM-DD'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final ndex = int.tryParse(ndexCtrl.text.trim()) ?? 0;
      setState(() {
        _shinies.add({
          'ndex': ndex,
          'name': nameCtrl.text.trim(),
          'source': sourceCtrl.text.trim(),
          'note': noteCtrl.text.trim(),
          'date': dateCtrl.text.trim(),
          'added': DateTime.now().toIso8601String(),
        });
        _shinies.sort((a, b) => ((a['ndex'] as int?) ?? 0).compareTo((b['ndex'] as int?) ?? 0));
      });
      _save();
    }
  }

  Future<void> _remove(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('删除', style: TextStyle(color: Colors.white)),
        content: Text('删除「${_shinies[index]['name']}」?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _shinies.removeAt(index));
      _save();
    }
  }

  Widget _inputField(String label, TextEditingController ctrl, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF252540),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('✨ 我的闪光'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.amber),
            onPressed: _add,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shinies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text('还没有闪光宝可梦', style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _add,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('添加第一只'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _shinies.length,
                  itemBuilder: (_, i) => _shinyCard(i),
                ),
    );
  }

  Widget _shinyCard(int index) {
    final s = _shinies[index];
    final ndex = (s['ndex'] as int?) ?? 0;
    final name = (s['name'] ?? '??').toString();
    final source = (s['source'] ?? '').toString();
    final note = (s['note'] ?? '').toString();
    final date = (s['date'] ?? '').toString();
    final sprite = ndex > 0
        ? 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$ndex.png'
        : '';

    final shinySprite = ndex > 0
        ? 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$ndex.png'
        : '';

    return Dismissible(
      key: ValueKey('shiny_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => _remove(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.2)),
        ),
        child: Row(children: [
          // 闪光头像
          if (ndex > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                Image.network(sprite, width: 48, height: 48,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48)),
                // 闪光特效遮罩
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (ndex > 0)
                    Text('#${ndex.toString().padLeft(3, '0')} ',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  if (source.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(source, style: TextStyle(color: Colors.amber[200], fontSize: 10)),
                    ),
                  ],
                ]),
                if (note.isNotEmpty || date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    if (date.isNotEmpty)
                      Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    if (note.isNotEmpty && date.isNotEmpty) Text('  ·  ', style: TextStyle(color: Colors.grey[700], fontSize: 10)),
                    if (note.isNotEmpty)
                      Text(note, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                  ]),
                ],
              ],
            ),
          ),
          // ✨ 闪光标志
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
        ]),
      ),
    );
  }
}
