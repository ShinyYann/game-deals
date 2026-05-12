import 'package:flutter/material.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';

class PokopiaCharactersPage extends StatefulWidget {
  const PokopiaCharactersPage({super.key});
  @override
  State<PokopiaCharactersPage> createState() => _PokopiaCharactersPageState();
}

class _PokopiaCharactersPageState extends State<PokopiaCharactersPage> {
  List<PokopiaCharacter> _chars = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final c = await PokopiaService.fetchCharacters();
    if (mounted) setState(() { _chars = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('角色档案')),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)])),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chars.length,
              itemBuilder: (context, i) => _CharCard(char: _chars[i]),
            ),
      ),
    );
  }
}

class _CharCard extends StatelessWidget {
  final PokopiaCharacter char;
  const _CharCard({required this.char});

  final List<Color> _gradients = const [
    [Color(0xFF7C4DFF), Color(0xFF448AFF)],
    [Color(0xFFFF6E40), Color(0xFFFFAB40)],
    [Color(0xFF00E676), Color(0xFF00BCD4)],
    [Color(0xFF76FF03), Color(0xFF00E676)],
    [Color(0xFFFF4081), Color(0xFFFF6E40)],
    [Color(0xFF18FFFF), Color(0xFF448AFF)],
    [Color(0xFFFFD740), Color(0xFFFF6E40)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = char.name.hashCode % _gradients.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: _gradients[idx]),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(char.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(char.role, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4)),
      ]),
    );
  }
}
