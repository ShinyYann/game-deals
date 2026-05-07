class TrophyGame {
  final String name;
  final String platform; // 'psn' or 'steam'
  final String? coverUrl;
  final int platinum; // 仅 PSN
  final int gold;
  final int silver;
  final int bronze;
  final int totalAchievements; // Steam
  final int unlockedAchievements; // Steam
  final double completionRate; // 0-100
  final List<TrophyDetail>? trophies;
  final double? hoursPlayed; // psnine 上的游玩时间
  final String? difficulty; // psnine 上的难度评价

  TrophyGame({
    required this.name,
    required this.platform,
    this.coverUrl,
    this.platinum = 0,
    this.gold = 0,
    this.silver = 0,
    this.bronze = 0,
    this.totalAchievements = 0,
    this.unlockedAchievements = 0,
    this.completionRate = 0.0,
    this.trophies,
    this.hoursPlayed,
    this.difficulty,
  });

  factory TrophyGame.fromPsnineSummary(Map<String, dynamic> data) {
    return TrophyGame(
      name: data['name'] ?? '',
      platform: 'psn',
      coverUrl: data['cover_url'],
      platinum: data['platinum'] ?? 0,
      gold: data['gold'] ?? 0,
      silver: data['silver'] ?? 0,
      bronze: data['bronze'] ?? 0,
      completionRate: (data['completion_rate'] ?? 0).toDouble(),
      hoursPlayed: data['hours_played'],
      difficulty: data['difficulty'],
      trophies: (data['trophies'] as List?)
              ?.map((t) => TrophyDetail.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class TrophyDetail {
  final String name;
  final String type; // 'platinum', 'gold', 'silver', 'bronze'
  final bool unlocked;
  final String? iconUrl;
  final String? description;

  TrophyDetail({
    required this.name,
    required this.type,
    this.unlocked = true,
    this.iconUrl,
    this.description,
  });

  factory TrophyDetail.fromJson(Map<String, dynamic> data) {
    return TrophyDetail(
      name: data['name'] ?? '',
      type: data['type'] ?? 'bronze',
      unlocked: data['unlocked'] ?? true,
      iconUrl: data['icon_url'],
      description: data['description'],
    );
  }
}
