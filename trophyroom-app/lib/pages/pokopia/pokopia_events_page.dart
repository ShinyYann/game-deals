import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pokopia_models.dart';
import 'pokopia_service.dart';

class PokopiaEventsPage extends StatefulWidget {
  const PokopiaEventsPage({super.key});
  @override
  State<PokopiaEventsPage> createState() => _PokopiaEventsPageState();
}

class _PokopiaEventsPageState extends State<PokopiaEventsPage> {
  List<PokopiaEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final events = await PokopiaService.fetchEvents();
    if (mounted) setState(() { _events = events; _loading = false; });
  }

  String _badge(PokopiaEvent e) {
    if (e.startDatetime.isEmpty) return '';
    try {
      final dt = DateTime.parse(e.startDatetime.replaceAll('Z', '+09:00'));
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative && diff.inDays.abs() <= 7) return '进行中';
      if (diff.isNegative) return '已结束';
      return '倒计时 ${diff.inDays + 1} 天';
    } catch (_) {
      return '';
    }
  }

  Color _badgeColor(String badge) {
    if (badge == '进行中') return Colors.greenAccent;
    if (badge.startsWith('倒计时')) return Colors.orangeAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('活动日历')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A3E), Color(0xFF0D1B2A)]),
        ),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
            ? const Center(child: Text('暂无活动', style: TextStyle(color: Colors.white54)))
            : RefreshIndicator(
                onRefresh: _load,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: _events.length,
                  itemBuilder: (context, i) => _EventCard(event: _events[i], badge: _badge(_events[i]), badgeColor: _badgeColor(_badge(_events[i]))),
                ),
              ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final PokopiaEvent event;
  final String badge;
  final Color badgeColor;
  const _EventCard({required this.event, required this.badge, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.06),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: event.cover.isNotEmpty
                ? Image.network(event.cover, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderCover())
                : _placeholderCover(),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    if (badge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.4)),
                        ),
                        child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple.shade800, Colors.indigo.shade900]),
      ),
      child: const Center(child: Icon(Icons.event, color: Colors.white24, size: 40)),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white24))),
            const SizedBox(height: 16),
            if (event.cover.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(event.cover, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            const SizedBox(height: 16),
            Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (badge.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor.withOpacity(0.4))),
                child: Text(badge, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            if (event.url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(event.url);
                    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('查看详情'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
