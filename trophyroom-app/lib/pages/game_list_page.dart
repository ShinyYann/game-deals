import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'game_detail_page.dart';

class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  List<Map<String, dynamic>> _games = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final psnId = prefs.getString('psn_id') ?? '';

      if (psnId.isEmpty) {
        setState(() {
          _loading = false;
          _error = '请先在设置页绑定 PSN 账号';
        });
        return;
      }

      final resp = await http
          .get(Uri.parse('http://8.153.97.56/api/psn_games?uid=$psnId'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List) {
          setState(() {
            _games = data.cast<Map<String, dynamic>>();
            _loading = false;
          });
        } else if (data is Map && data['error'] != null) {
          setState(() {
            _error = data['error'].toString();
            _loading = false;
          });
        } else {
          setState(() {
            _error = '数据格式错误';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = '请求失败: ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(_error, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchGames,
            ),
          ],
        ),
      );
    }

    if (_games.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text('暂无游戏数据', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGames,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _games.length,
          itemBuilder: (ctx, i) {
            final g = _games[i];
            return _GameCard(
              gameId: g['game_id']?.toString() ?? '',
              name: g['name']?.toString() ?? 'Unknown',
              coverUrl: g['cover_url']?.toString(),
              completionRate: (g['completion_rate'] ?? 0).toDouble(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameDetailPage(
                      gameId: g['game_id']?.toString() ?? '',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String gameId;
  final String name;
  final String? coverUrl;
  final double completionRate;
  final VoidCallback onTap;

  const _GameCard({
    required this.gameId,
    required this.name,
    this.coverUrl,
    required this.completionRate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[850]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[850],
                child: coverUrl != null && coverUrl!.isNotEmpty
                    ? Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.videogame_asset,
                              size: 36, color: Colors.grey[600]),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.videogame_asset,
                            size: 36, color: Colors.grey[600]),
                      ),
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completionRate / 100,
                            backgroundColor: Colors.grey[800],
                            color: Colors.purple[300],
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${completionRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: completionRate >= 100
                              ? Colors.green[400]
                              : Colors.grey[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
