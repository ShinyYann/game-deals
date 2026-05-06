/// Switch 游戏数据模型
///
/// Switch 无成就系统，仅记录游戏库 + 游玩时长
class SwitchGame {
  final String name;
  final String? coverUrl;
  final int hoursPlayed; // 小时，手动记录
  final int minutesPlayed; // 分钟，手动记录
  final String? comment; // 备注
  final DateTime addedAt;
  final DateTime? lastPlayed;

  SwitchGame({
    required this.name,
    this.coverUrl,
    this.hoursPlayed = 0,
    this.minutesPlayed = 0,
    this.comment,
    required this.addedAt,
    this.lastPlayed,
  });

  /// 总游玩时间（分钟）
  int get totalMinutes => hoursPlayed * 60 + minutesPlayed;

  /// 格式化时长显示
  String get playTimeDisplay {
    if (totalMinutes == 0) return '未记录';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '$m 分钟';
    if (m == 0) return '$h 小时';
    return '$h 小时 $m 分钟';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'cover_url': coverUrl,
        'hours_played': hoursPlayed,
        'minutes_played': minutesPlayed,
        'comment': comment,
        'added_at': addedAt.toIso8601String(),
        'last_played': lastPlayed?.toIso8601String(),
      };

  factory SwitchGame.fromJson(Map<String, dynamic> json) => SwitchGame(
        name: json['name'] ?? '',
        coverUrl: json['cover_url'],
        hoursPlayed: json['hours_played'] ?? 0,
        minutesPlayed: json['minutes_played'] ?? 0,
        comment: json['comment'],
        addedAt: DateTime.tryParse(json['added_at'] ?? '') ?? DateTime.now(),
        lastPlayed: json['last_played'] != null
            ? DateTime.tryParse(json['last_played'])
            : null,
      );
}
