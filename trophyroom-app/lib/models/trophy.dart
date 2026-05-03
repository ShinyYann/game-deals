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

  const TrophyGame({
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
  });
}
