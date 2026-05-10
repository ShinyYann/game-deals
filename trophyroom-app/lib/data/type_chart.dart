/// 🔥 宝可梦属性相性表
/// 攻方→守方，值=伤害倍率

const Map<String, Map<String, double>> typeChart = {
  '普通': {'岩石': 0.5, '幽灵': 0.0, '钢': 0.5},
  '火':   {'火': 0.5, '水': 2.0, '草': 0.5, '冰': 0.5, '虫': 2.0, '岩石': 2.0, '龙': 0.5, '钢': 0.5},
  '水':   {'火': 0.5, '水': 0.5, '草': 2.0, '地面': 2.0, '岩石': 2.0, '龙': 0.5},
  '草':   {'火': 2.0, '水': 0.5, '草': 0.5, '毒': 2.0, '地面': 0.5, '飞行': 2.0, '虫': 2.0, '龙': 0.5, '钢': 0.5},
  '电':   {'水': 0.5, '草': 0.5, '电': 0.5, '地面': 2.0, '飞行': 0.5, '龙': 0.5},
  '冰':   {'火': 2.0, '水': 0.5, '草': 0.5, '冰': 0.5, '地面': 2.0, '飞行': 2.0, '龙': 2.0, '钢': 2.0},
  '格斗': {'普通': 2.0, '冰': 2.0, '毒': 0.5, '飞行': 2.0, '超能力': 2.0, '虫': 0.5, '岩石': 2.0, '幽灵': 0.0, '钢': 2.0, '火': 0.5, '水': 0.5, '草': 0.5, '恶': 2.0, '妖精': 2.0},
  '毒':   {'草': 0.5, '毒': 0.5, '地面': 2.0, '岩石': 0.5, '幽灵': 0.5, '钢': 0.0, '妖精': 2.0},
  '地面': {'火': 0.5, '草': 2.0, '电': 0.0, '毒': 0.5, '飞行': 2.0, '虫': 0.5, '岩石': 0.5, '钢': 2.0},
  '飞行': {'草': 0.5, '电': 2.0, '格斗': 0.5, '虫': 0.5, '岩石': 2.0, '钢': 0.5},
  '超能力': {'格斗': 2.0, '毒': 2.0, '超能力': 0.5, '钢': 0.5, '恶': 0.0},
  '虫':   {'火': 2.0, '草': 0.5, '格斗': 0.5, '毒': 0.5, '飞行': 2.0, '超能力': 2.0, '幽灵': 2.0, '岩石': 2.0, '钢': 2.0, '恶': 0.5},
  '岩石': {'火': 0.5, '冰': 2.0, '格斗': 2.0, '地面': 2.0, '飞行': 0.5, '虫': 2.0, '钢': 2.0},
  '幽灵': {'普通': 0.0, '超能力': 2.0, '幽灵': 2.0, '恶': 2.0, '钢': 0.5},
  '龙':   {'火': 0.5, '水': 0.5, '草': 0.5, '电': 0.5, '冰': 2.0, '龙': 2.0, '钢': 0.5, '妖精': 2.0},
  '恶':   {'格斗': 2.0, '超能力': 0.0, '虫': 2.0, '幽灵': 2.0, '恶': 0.5, '妖精': 2.0, '钢': 0.5},
  '钢':   {'火': 2.0, '草': 0.5, '冰': 0.5, '毒': 0.0, '地面': 2.0, '飞行': 0.5, '超能力': 0.5, '虫': 0.5, '岩石': 0.5, '龙': 0.5, '钢': 0.5, '妖精': 0.5},
  '妖精': {'火': 0.5, '毒': 2.0, '格斗': 0.5, '虫': 0.5, '钢': 2.0, '恶': 2.0, '龙': 0.0},
};

/// 属性中文名 → 属性图标(emoji)
const Map<String, String> typeIcons = {
  '普通': '⬜', '火': '🔥', '水': '💧', '草': '🌿', '电': '⚡', '冰': '❄️',
  '格斗': '👊', '毒': '☠️', '地面': '🏜️', '飞行': '🕊️', '超能力': '🔮',
  '虫': '🐛', '岩石': '🪨', '幽灵': '👻', '龙': '🐉', '恶': '😈', '钢': '⚙️', '妖精': '🧚',
};

/// 属性标签颜色
const Map<String, int> typeColors = {
  '普通': 0xFFA8A878, '火': 0xFFF08030, '水': 0xFF6890F0,
  '草': 0xFF78C850, '电': 0xFFF8D030, '冰': 0xFF98D8D8,
  '格斗': 0xFFC03028, '毒': 0xFFA040A0, '地面': 0xFFE0C068,
  '飞行': 0xFFA890F0, '超能力': 0xFFF85888, '虫': 0xFFA8B820,
  '岩石': 0xFFB8A038, '幽灵': 0xFF705898, '龙': 0xFF7038F8,
  '恶': 0xFF705848, '钢': 0xFFB8B8D0, '妖精': 0xFFEE99AC,
};

/// 根据宝可梦的 type(s) 计算属性相性
class TypeEffectiveness {
  final List<String> defenderTypes;
  final Map<String, double> effectiveness;

  TypeEffectiveness(this.defenderTypes)
      : effectiveness = _compute(defenderTypes);

  static Map<String, double> _compute(List<String> types) {
    final result = <String, double>{};
    for (final attacker in typeChart.keys) {
      double mult = 1.0;
      for (final defender in types) {
        if (typeChart[attacker]?.containsKey(defender) ?? false) {
          mult *= typeChart[attacker]![defender]!;
        }
      }
      result[attacker] = mult;
    }
    return result;
  }

  List<String> get superEffective =>
      effectiveness.entries.where((e) => e.value == 2.0).map((e) => e.key).toList();

  List<String> get notVeryEffective =>
      effectiveness.entries.where((e) => e.value == 0.5).map((e) => e.key).toList();

  List<String> get noEffect =>
      effectiveness.entries.where((e) => e.value == 0.0).map((e) => e.key).toList();

  List<String> get normalEffect =>
      effectiveness.entries.where((e) => e.value == 1.0).map((e) => e.key).toList();

  List<String> get quarterEffect =>
      effectiveness.entries.where((e) => e.value == 0.25).map((e) => e.key).toList();
}
