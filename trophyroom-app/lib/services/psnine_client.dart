import 'dart:convert';
import 'package:http/http.dart' as http;

class PsnineClient {
  final String psnId;

  PsnineClient(this.psnId);

  /// 从 psnine 抓取 PSN 概要数据 + 游戏列表（一次请求合并）
  Future<Map<String, dynamic>> fetchFullData() async {
    // 一次请求拿游戏列表页（含完成率、封面、奖杯数）
    final html = await _fetch(
        'https://www.psnine.com/psnid/$psnId/psngame');

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

      // 游戏名：从封面图 alt 提取（和封面 URL 共用一个 img 匹配，保证取对）
      String gname = 'Unknown';
      final nameCoverM = RegExp(
              r'<img[^>]*src="([^"]+\.(?:playstation|psnobj)[^"]*)"[^>]*alt="([^"]*)"[^>]*width="(?:91|50)"')
          .firstMatch(tr);
      if (nameCoverM != null) {
        gname = nameCoverM.group(2)!.trim();
      } else {
        // 兜底：从 <a> 链接文本提取
        final aM = RegExp(r'<a[^>]*href="[^"]*psngame/' + RegExp.escape(gid) +
            r'[^>]*>([^<]+)</a>', caseSensitive: false).firstMatch(tr);
        if (aM != null) {
          gname = aM.group(1)!.trim();
        } else {
          // 最终兜底：从任意 alt 提取（排除头像和空值）
          final allAlt = RegExp(r'alt="([^"]+)"').allMatches(tr);
          for (final m in allAlt) {
            final val = m.group(1)!.trim();
            if (val.isNotEmpty && val != '头像' && val.length > 2) {
              gname = val;
              break;
            }
          }
        }
      }

      // 封面
      final coverM = RegExp(
              r'<img[^>]*src="([^"]+\.(?:playstation|psnobj)[^"]*)"[^>]*width="(?:91|50)"')
          .firstMatch(tr);
      final cover = coverM?.group(1);

      // 完成率
      final rateM = RegExp(r'(\d+)%</div></div>').firstMatch(tr);
      final rate = rateM != null ? int.tryParse(rateM.group(1)!) ?? 0 : 0;

      // 各类型奖杯数
      final pt = RegExp(r'text-platinum[^>]*>白(\d+)').firstMatch(tr);
      final gd = RegExp(r'text-gold[^>]*>金(\d+)').firstMatch(tr);
      final sv = RegExp(r'text-silver[^>]*>银(\d+)').firstMatch(tr);
      final bz = RegExp(r'text-bronze[^>]*>铜(\d+)').firstMatch(tr);

      // 平台标识：pf_ps5 / pf_ps4 / pf_psv / pf_ps3 / pf_psp
      String platform = '';
      final pfM = RegExp(r'class="pf_(ps\d+|psv|psp)"', caseSensitive: false).firstMatch(tr);
      if (pfM != null) {
        final p = pfM.group(1)!.toLowerCase();
        if (p == 'ps5') platform = 'PS5';
        else if (p == 'ps4') platform = 'PS4';
        else if (p == 'ps3') platform = 'PS3';
        else if (p == 'psv') platform = 'PS Vita';
        else if (p == 'psp') platform = 'PSP';
      }

      // 游玩时间（从同一页面提取：<td class="twoge h-p">）
      String playTime = '';
      final ptM = RegExp(r'<td[^>]*class="twoge h-p"[^>]*>([^<]+)<em>总耗时')
          .firstMatch(tr);
      if (ptM != null) playTime = ptM.group(1)!.trim();

      games.add({
        'game_id': gid,
        'name': gname,
        'cover_url': cover,
        'completion_rate': rate,
        'platinum': pt != null ? int.tryParse(pt.group(1)!) ?? 0 : 0,
        'gold': gd != null ? int.tryParse(gd.group(1)!) ?? 0 : 0,
        'silver': sv != null ? int.tryParse(sv.group(1)!) ?? 0 : 0,
        'bronze': bz != null ? int.tryParse(bz.group(1)!) ?? 0 : 0,
        'play_time': playTime,
        'platform': platform,
      });
    }

    // 从游戏列表统计数据（游戏页没有档案汇总，需要自己算）
    int totalPlatinum = 0, totalGold = 0, totalSilver = 0, totalBronze = 0;
    int perfectCount = 0, totalCompletionRate = 0;
    for (final g in games) {
      totalPlatinum += (g['platinum'] as num?)?.toInt() ?? 0;
      totalGold += (g['gold'] as num?)?.toInt() ?? 0;
      totalSilver += (g['silver'] as num?)?.toInt() ?? 0;
      totalBronze += (g['bronze'] as num?)?.toInt() ?? 0;
      final rate = (g['completion_rate'] as num?)?.toInt() ?? 0;
      totalCompletionRate += rate;
      if (rate >= 100) perfectCount++;
    }
    final avgCompletionRate = games.isNotEmpty
        ? (totalCompletionRate / games.length).toStringAsFixed(1)
        : '0';
    final totalTrophyCount =
        totalPlatinum + totalGold + totalSilver + totalBronze;

    final profile = {
      'psn_id': psnId,
      'platinum': totalPlatinum,
      'gold': totalGold,
      'silver': totalSilver,
      'bronze': totalBronze,
      'level': await _extractLevel(psnId),
      'total_games': games.length,
      'perfect_games': perfectCount,
      'total_trophies': totalTrophyCount,
      'completion_rate': avgCompletionRate,
      'total_points': _findInt(html, r'总点数[：:]\s*(\d+)'),
      'platform': 'psn',
      'games': games,
      'psn_data_source': 'psnine.com',
    };

    print('[psnine] Fetched ${games.length} games for $psnId');
    return profile;
  }

  /// 从 psnine 抓取单个游戏的奖杯列表（含获得/未获得状态）
  Future<List<Map<String, dynamic>>> fetchGameTrophies(String gameId) async {
    if (gameId.isEmpty) throw Exception('empty game_id');
    final html = await _fetch('https://www.psnine.com/psngame/$gameId?psnid=$psnId');
    
    final trophies = <Map<String, dynamic>>[];
    
    // 查找奖杯列表区域 — psnine 奖杯行在 #trophy_list table tbody tr
    final blockM = RegExp(r'<table[^>]*id="trophy_list"[^>]*>(.*?)</table>',
        dotAll: true).firstMatch(html);
    final block = blockM?.group(1) ?? html;

    // 解析每个奖杯行
    final trRegex = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true);
    for (final trm in trRegex.allMatches(block)) {
      final tr = trm.group(1)!;
      
      // 判断是否已获得：行有 class="obtained" 或包含 ✓ 标记
      final earned = tr.contains('class="obtained"') ||
                     tr.contains('✅') ||
                     tr.contains('已获得') ||
                     tr.contains('✔');
      
      // 奖杯名称
      final nameM = RegExp(r'<td[^>]*class="trophy_name"[^>]*>(.*?)</td>',
          dotAll: true).firstMatch(tr);
      final name = nameM?.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
      if (name.isEmpty) continue;
      
      // 奖杯类型
      String type = 'bronze';
      if (tr.contains('text-platinum') || tr.contains('白金')) type = 'platinum';
      else if (tr.contains('text-gold') || tr.contains('金')) type = 'gold';
      else if (tr.contains('text-silver') || tr.contains('银')) type = 'silver';
      else if (tr.contains('text-bronze') || tr.contains('铜')) type = 'bronze';
      
      // 奖杯图标
      String iconUrl = '';
      final imgM = RegExp(r'<img[^>]*src="([^"]*trophy[^"]*)"[^>]*>',
          dotAll: true).firstMatch(tr);
      if (imgM != null) iconUrl = imgM.group(1)!;
      
      // 获取日期
      String earnedDate = '';
      final dateM = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(tr);
      if (dateM != null && earned) earnedDate = dateM.group(1)!;
      
      // 奖杯描述
      String description = '';
      final descM = RegExp(r'<td[^>]*class="trophy_desc"[^>]*>(.*?)</td>',
          dotAll: true).firstMatch(tr);
      if (descM != null) {
        description = descM.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      }
      
      // 奖杯 ID（从 onclick 或链接中提取）
      String trophyId = '';
      final idM = RegExp(r'trophy[=/](\d+)').firstMatch(tr);
      if (idM != null) trophyId = idM.group(1)!;
      
      trophies.add({
        'name': name,
        'type': type,
        'earned': earned,
        'earned_date': earnedDate,
        'icon_url': iconUrl,
        'description': description,
        'id': trophyId,
      });
    }
    
    return trophies;
  }

  /// 从 psnine 抓取单个奖杯的玩家心得（Tips）
  Future<List<Map<String, dynamic>>> fetchTrophyTips(String trophyId) async {
    if (trophyId.isEmpty) return [];
    try {
      final html = await _fetch('https://www.psnine.com/trophy/$trophyId');
      
      // 查找评论列表区域
      final listM = RegExp(r'<ul class="list">(.*?)<div class="pd10">',
          dotAll: true).firstMatch(html);
      if (listM == null) return [];
      
      final listHtml = listM.group(1)!;
      final tips = <Map<String, dynamic>>[];
      
      // 解析每个评论
      final items = listHtml.split('<li');
      for (int i = 1; i < items.length; i++) {
        final item = items[i];
        
        // 用户名
        final nameM = RegExp(r'class="psnnode"[^>]*>(.*?)<').firstMatch(item);
        final userName = nameM?.group(1)?.trim() ?? '';
        
        // 用户头像
        String avatar = '';
        final avatarM = RegExp(r'<a class="l"[^>]*><img[^>]*src="([^"]+)"').firstMatch(item);
        if (avatarM != null) {
          avatar = avatarM.group(1)!;
        }
        
        // 内容（心得文字）
        final contentM = RegExp(r'class="content[^"]*"[^>]*>(.*?)</div>',
            dotAll: true).firstMatch(item);
        String content = '';
        if (contentM != null) {
          content = contentM.group(1)!
              .replaceAll(RegExp(r'<(?!/?a\b)[^>]+>', caseSensitive: false), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }
        
        // 日期
        final dateM = RegExp(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2})').firstMatch(item);
        final date = dateM?.group(1) ?? '';
        
        // 地点
        final locM = RegExp(r'<span>\d{4}-\d{2}-\d{2}[^<]*</span>\s*([^<]+)').firstMatch(item);
        final location = locM?.group(1)?.trim() ?? '';
        
        if (content.isNotEmpty) {
          tips.add({
            'user': userName,
            'avatar': avatar,
            'content': content,
            'date': date,
            'location': location,
          });
        }
      }
      
      return tips;
    } catch (e) {
      print('[psnine] fetchTips failed: $e');
      return [];
    }
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

  /// 从 psnine 用户主页提取等级（游戏列表页可能不显示等级）
  Future<int> _extractLevel(String psnId) async {
    try {
      final html = await _fetch('https://www.psnine.com/psnid/$psnId');
      // 尝试多种格式
      for (final pattern in [
        r'Lv\s*(\d+)',
        r'等级[：:]\s*(\d+)',
        r'class="[^"]*level[^"]*"[^>]*>(\d+)',
        r'LEVEL\s*(\d+)',
        r'(\d+)\s*级',
      ]) {
        final v = _findInt(html, pattern);
        if (v > 0) return v;
      }
    } catch (_) {}
    return 0;
  }
}
