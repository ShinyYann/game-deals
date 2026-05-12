import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';

class PokopiaGuidesPage extends StatefulWidget {
  const PokopiaGuidesPage({super.key});
  @override
  State<PokopiaGuidesPage> createState() => _PokopiaGuidesPageState();
}

class _PokopiaGuidesPageState extends State<PokopiaGuidesPage> {
  List<PokopiaGuide> _guides = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final g = await PokopiaService.fetchGuides();
    if (mounted) setState(() { _guides = g; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('攻略技巧')),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)])),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: _guides.length,
                itemBuilder: (context, i) => _GuideCard(guide: _guides[i]),
              ),
            ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final PokopiaGuide guide;
  const _GuideCard({required this.guide});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(context),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withOpacity(0.06)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: guide.cover.isNotEmpty
              ? Image.network(guide.cover, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(guide.title.replaceAll('《宝可梦Pokopia》', ''), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(children: [
                  Icon(Icons.open_in_new, color: Colors.white38, size: 12),
                  const SizedBox(width: 4),
                  Text('游民星空', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.deepOrange.shade900])),
    child: const Center(child: Icon(Icons.menu_book, color: Colors.white24, size: 32)),
  );

  void _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(guide.link);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
