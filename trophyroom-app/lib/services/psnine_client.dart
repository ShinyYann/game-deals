import 'package:http/http.dart' as http;

class PsnineClient {
  final String psnId;
  final String? npsso;
  final String? oauthUid;

  PsnineClient(this.psnId, {this.npsso, this.oauthUid});

  /// 从 psnine 抓取 PSN 概要数据
  Future<Map<String, dynamic>> fetchProfile() async {
    final html = await _fetch('https://www.psnine.com/psnid/$psnId');
    return {
      'psn_id': psnId,
      'platinum': _findInt(html, r'<span class="text-platinum">白(\d+)'),
      'gold': _findInt(html, r'<span class="text-gold">金(\d+)'),
      'silver': _findInt(html, r'<span class="text-silver">银(\d+)'),
      'bronze': _findInt(html, r'<span class="text-bronze">铜(\d+)'),
      'level': _findInt(html, r'Lv\s*(\d+)'),
      'total_games': _findInt(html, r'(\d+)<em>总游戏'),
      'perfect_games': _findInt(html, r'(\d+)<em>完美数'),
      'total_trophies': _findInt(html, r'(\d+)<em>总奖杯'),
      'completion_rate': _find(html, r'([\d.]+)<em>完成率'),
      'total_points': _findInt(html, r'总点数[：:]\s*(\d+)'),
      'platform': 'psn',
    };
  }

  /// 从 psnine 抓取游戏列表（含封面、完成率、游玩时间）
  Future<List<Map<String, dynamic>>> fetchGames() async {
    final html = await _fetch(
        'https://www.psnine.com/psnid/$psnId/psngame');

    // 额外拉取主页获取游玩时间
    final profileHtml =
        await _fetch('https://www.psnine.com/psnid/$psnId');
    final playTimes = <String, String>{};
    final ptRegex = RegExp(
        r'psngame/(\d+)\?psnid=' + RegExp.escape(psnId));
    final ptMatches = ptRegex.allMatches(profileHtml);
    for (final m in ptMatches) {
      final gid = m.group(1)!;
      final after = profileHtml.substring(
          m.start, (m.start + 2000).clamp(0, profileHtml.length));
      final ptM = RegExp(r'<td[^>]*class="twoge h-p"[^>]*>([^<]+)<em>总耗时')
          .firstMatch(after);
      if (ptM != null) {
        playTimes[gid] = ptM.group(1)!.trim();
      }
    }

    final games = <Map<String, dynamic>>[];
    final trRegex = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true);
    final trMatches = trRegex.allMatches(html);
    for (final trm in trMatches) {
      final tr = trm.group(1)!;
      final gidM = RegExp(
              r'psngame/(\d+)\?psnid=' + RegExp.escape(psnId))
          .firstMatch(tr);
      if (gidM == null) continue;
      final gid = gidM.group(1)!;

      final gnameM = RegExp(r'alt="([^"]+)"').firstMatch(tr);
      final gname = gnameM != null ? gnameM.group(1)! : 'Unknown';

      final coverM = RegExp(
              r'<img[^>]*src="([^"]+\.(?:playstation|psnobj)[^"]*)"[^>]*width="(?:91|50)"')
          .firstMatch(tr);
      final cover = coverM?.group(1);

      final rateM =
          RegExp(r'(\d+)%</div></div>').firstMatch(tr);
      final rate =
          rateM != null ? int.tryParse(rateM.group(1)!) ?? 0 : 0;

      final pt = RegExp(r'text-platinum[^>]*>白(\d+)').firstMatch(tr);
      final gd = RegExp(r'text-gold[^>]*>金(\d+)').firstMatch(tr);
      final sv = RegExp(r'text-silver[^>]*>银(\d+)').firstMatch(tr);
      final bz = RegExp(r'text-bronze[^>]*>铜(\d+)').firstMatch(tr);

      games.add({
        'game_id': gid,
        'name': gname,
        'cover_url': cover,
        'completion_rate': rate,
        'platinum': pt != null ? int.tryParse(pt.group(1)!) ?? 0 : 0,
        'gold': gd != null ? int.tryParse(gd.group(1)!) ?? 0 : 0,
        'silver': sv != null ? int.tryParse(sv.group(1)!) ?? 0 : 0,
        'bronze': bz != null ? int.tryParse(bz.group(1)!) ?? 0 : 0,
        'play_time': playTimes[gid],
      });
    }

    return games;
  }

  /// 合并 profile + games 为统一格式
  Future<Map<String, dynamic>> fetchFullData() async {
    final profile = await fetchProfile();
    final games = await fetchGames();
    profile['games'] = games;
    profile['psn_data_source'] = 'psnine.com';
    return profile;
  }

  // ─── 内部工具方法 ───

  Future<String> _fetch(String url) async {
    final resp = await http
        .get(Uri.parse(url), headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Referer': 'https://www.psnine.com/',
        })
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode >= 400) {
      throw Exception('psnine HTTP ${resp.statusCode} for $url');
    }
    return resp.body;
  }

  int _findInt(String html, String pattern) {
    final m = RegExp(pattern).firstMatch(html);
    if (m == null) return 0;
    final val = int.tryParse(m.group(1) ?? '0');
    return val ?? 0;
  }

  String? _find(String html, String pattern) {
    final m = RegExp(pattern).firstMatch(html);
    return m?.group(1);
  }
}
