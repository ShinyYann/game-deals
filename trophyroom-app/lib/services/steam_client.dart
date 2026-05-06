/// Steam 数据客户端 — 通过服务器代理访问 Steam Web API
///
/// 所有请求走服务器中转，国内用户无感访问 Steam
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 翻译词对（内部使用）
class _WordPair {
  final String en;
  final String cn;
  const _WordPair(this.en, this.cn);
}

class SteamClient {
  static const String _server = 'http://8.153.97.56';

  final String steamId;

  SteamClient(this.steamId);

  /// 获取 Steam 个人资料（昵称、头像、等级等）
  Future<Map<String, dynamic>> fetchProfile() async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/profile?steamid=$steamId'),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam profile fetch failed: ${resp.statusCode}');
  }

  /// 获取 Steam 游戏库（含游玩时长）
  Future<Map<String, dynamic>> fetchGames() async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/games?steamid=$steamId'),
    ).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam games fetch failed: ${resp.statusCode}');
  }

  /// 获取某个游戏的成就列表 + 解锁状态
  Future<Map<String, dynamic>> fetchAchievements(String appId) async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/achievements?steamid=$steamId&appid=$appId'),
    ).timeout(const Duration(seconds: 20));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam achievements fetch failed: ${resp.statusCode}');
  }

  /// 获取某个游戏的社区攻略数
  Future<Map<String, dynamic>> fetchTips(String appId) async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/tips?appid=$appId'),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    return {'app_id': appId, 'guide_count': 0};
  }

  /// 设置服务器 Steam API Key（一次性操作）
  static Future<Map<String, dynamic>> setApiKey(String key) async {
    final resp = await http.post(
      Uri.parse('$_server/api/steam/key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': key}),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to set Steam API key: ${resp.statusCode}');
  }

  /// Steam 成就名 → 中文翻译（字典 + 规则引擎兜底）
  static String translateAchievement(String name) {
    if (_achTrans.containsKey(name)) return _achTrans[name]!;
    return _autoTranslate(name);
  }

  /// 规则引擎翻译兜底
  static String _autoTranslate(String en) {
    String result = en;
    for (final entry in _wordMap) {
      result = result.replaceAll(entry.en, entry.cn);
    }
    return result == en ? en : result;
  }

  /// 单词/短语替换表（按需排列）
  static final List<_WordPair> _wordMap = [
    _WordPair('Achievement Unlocked', '成就解锁'),
    _WordPair('Gotta Catch', '捕获全部'),
    _WordPair('Em All', ''),
    _WordPair('Game Complete', '游戏通关'),
    _WordPair('All Achievements', '全成就'),
    _WordPair('New Game Plus', '新游戏+'),
    _WordPair('Collect All', '收集全部'),
    _WordPair('Find All', '找到全部'),
    _WordPair('No Damage', '无伤'),
    _WordPair('No Death', '零死亡'),
    _WordPair('Speed Run', '速通'),
    _WordPair('Hard Mode', '困难模式'),
    _WordPair('Easy Mode', '简单模式'),
    _WordPair('Normal Mode', '普通模式'),
    _WordPair('True Ending', '真结局'),
    _WordPair('Bad Ending', '坏结局'),
    _WordPair('Good Ending', '好结局'),
    _WordPair('Secret Ending', '隐藏结局'),
    _WordPair('Hidden Ending', '隐藏结局'),
    _WordPair('First Kill', '首次击杀'),
    _WordPair('First Blood', '初见血'),
    _WordPair('First Step', '第一步'),
    _WordPair('Level Up', '升级'),
    _WordPair('Max Level', '满级'),
    
    _WordPair('Complete', '完成'),
    _WordPair('Defeat', '击败'),
    _WordPair('Defeated', '已击败'),
    _WordPair('Collect', '收集'),
    _WordPair('Collected', '已收集'),
    _WordPair('Find', '找到'),
    _WordPair('Found', '已找到'),
    _WordPair('Unlock', '解锁'),
    _WordPair('Unlocked', '已解锁'),
    _WordPair('Discover', '发现'),
    _WordPair('Discovered', '已发现'),
    _WordPair('Reach', '到达'),
    _WordPair('Reached', '已到达'),
    _WordPair('Obtain', '获得'),
    _WordPair('Obtained', '已获得'),
    _WordPair('Craft', '制作'),
    _WordPair('Crafted', '已制作'),
    _WordPair('Build', '建造'),
    _WordPair('Built', '已建造'),
    _WordPair('Upgrade', '升级'),
    _WordPair('Upgraded', '已升级'),
    _WordPair('Save', '拯救'),
    _WordPair('Saved', '已拯救'),
    _WordPair('Rescue', '营救'),
    _WordPair('Rescued', '已营救'),
    _WordPair('Escape', '逃脱'),
    _WordPair('Escaped', '已逃脱'),
    _WordPair('Survive', '生存'),
    _WordPair('Survived', '已生存'),
    _WordPair('Destroy', '摧毁'),
    _WordPair('Destroyed', '已摧毁'),
    _WordPair('Clear', '通关'),
    _WordPair('Cleared', '已通关'),
    _WordPair('Master', '精通'),
    _WordPair('Mastered', '已精通'),
    
    _WordPair('Kill', '击杀'),
    _WordPair('kills', '击杀'),
    _WordPair('Kills', '击杀'),
    _WordPair('kill', '击杀'),
    _WordPair('Death', '死亡'),
    _WordPair('deaths', '死亡'),
    _WordPair('Win', '胜利'),
    _WordPair('Wins', '胜利'),
    _WordPair('Lose', '失败'),
    _WordPair('Boss', 'Boss'),
    _WordPair('Chapter', '章'),
    _WordPair('Level', '级'),
    _WordPair('Stage', '阶段'),
    _WordPair('Area', '区域'),
    _WordPair('Zone', '地带'),
    _WordPair('World', '世界'),
    _WordPair('Map', '地图'),
    _WordPair('Dungeon', '地牢'),
    _WordPair('Quest', '任务'),
    _WordPair('Mission', '任务'),
    _WordPair('Challenge', '挑战'),
    _WordPair('Trial', '试炼'),
    _WordPair('Event', '事件'),
    
    _WordPair('Gold', '金币'),
    _WordPair('Silver', '银币'),
    _WordPair('Bronze', '铜'),
    _WordPair('Coin', '硬币'),
    _WordPair('Money', '金钱'),
    _WordPair('Treasure', '宝藏'),
    _WordPair('Loot', '战利品'),
    _WordPair('Item', '道具'),
    _WordPair('Weapon', '武器'),
    _WordPair('Armor', '防具'),
    _WordPair('Shield', '盾牌'),
    _WordPair('Sword', '剑'),
    _WordPair('Bow', '弓'),
    _WordPair('Staff', '法杖'),
    _WordPair('Ring', '戒指'),
    _WordPair('Potion', '药水'),
    _WordPair('Spell', '法术'),
    _WordPair('Magic', '魔法'),
    _WordPair('Skill', '技能'),
    _WordPair('Ability', '能力'),
    _WordPair('Power', '力量'),
    _WordPair('Speed', '速度'),
    _WordPair('Health', '生命'),
    _WordPair('Mana', '法力'),
    _WordPair('Stamina', '体力'),
    
    _WordPair('Player', '玩家'),
    _WordPair('Hero', '英雄'),
    _WordPair('Warrior', '战士'),
    _WordPair('Mage', '法师'),
    _WordPair('Rogue', '盗贼'),
    _WordPair('Archer', '弓箭手'),
    _WordPair('Knight', '骑士'),
    _WordPair('Paladin', '圣骑士'),
    _WordPair('Hunter', '猎人'),
    _WordPair('Monster', '怪物'),
    _WordPair('Dragon', '龙'),
    _WordPair('Demon', '恶魔'),
    _WordPair('Undead', '亡灵'),
    _WordPair('Zombie', '僵尸'),
    _WordPair('Skeleton', '骷髅'),
    _WordPair('Ghost', '幽灵'),
    _WordPair('Spirit', '灵魂'),
    _WordPair('Goblin', '哥布林'),
    _WordPair('Orc', '兽人'),
    _WordPair('Elf', '精灵'),
    _WordPair('Dwarf', '矮人'),
    _WordPair('Human', '人类'),
    
    _WordPair('Fire', '火'),
    _WordPair('Water', '水'),
    _WordPair('Earth', '土'),
    _WordPair('Wind', '风'),
    _WordPair('Ice', '冰'),
    _WordPair('Lightning', '闪电'),
    _WordPair('Poison', '毒'),
    _WordPair('Dark', '暗'),
    _WordPair('Light', '光'),
    _WordPair('Holy', '神圣'),
    _WordPair('Shadow', '暗影'),
    _WordPair('Blood', '血'),
    _WordPair('Chaos', '混沌'),
    _WordPair('Order', '秩序'),
    
    _WordPair('Forest', '森林'),
    _WordPair('Desert', '沙漠'),
    _WordPair('Mountain', '山脉'),
    _WordPair('Ocean', '海洋'),
    _WordPair('River', '河流'),
    _WordPair('Cave', '洞穴'),
    _WordPair('Castle', '城堡'),
    _WordPair('Tower', '塔'),
    _WordPair('Temple', '神殿'),
    _WordPair('Village', '村庄'),
    _WordPair('Town', '城镇'),
    _WordPair('City', '城市'),
    _WordPair('Kingdom', '王国'),
    _WordPair('Empire', '帝国'),
    
    _WordPair('of the', '之'),
    _WordPair('the ', ''),
    _WordPair('The ', ''),
    _WordPair('All ', '全部'),
    _WordPair('All', '全部'),
    _WordPair('First', '第一'),
    _WordPair('Last', '最后'),
    _WordPair('Final', '最终'),
    _WordPair('Ultimate', '终极'),
    _WordPair('Supreme', '至高'),
    _WordPair('Legendary', '传说'),
    _WordPair('Mythic', '神话'),
    _WordPair('Rare', '稀有'),
    _WordPair('Epic', '史诗'),
    _WordPair('Common', '普通'),
  ];

  /// Steam 成就描述 → 中文翻译
  static String translateDescription(String desc) {
    return _autoTranslate(desc);
  }

  static const Map<String, String> _achTrans = {
    // 通用
    'New Game': '新游戏',
    'Game Complete': '游戏通关',
    '100% Complete': '100% 完成',
    'First Blood': '初见血',
    'First Kill': '首次击杀',
    'Beginner': '初学者',
    'Amateur': '业余选手',
    'Professional': '职业选手',
    'Expert': '专家',
    'Master': '大师',
    'Grand Master': '宗师',
    'Legend': '传奇',
    'Welcome': '欢迎',
    'Getting Started': '入门',
    'Tutorial Complete': '教程完成',
    'Chapter 1': '第一章',
    'Chapter 2': '第二章',
    'Chapter 3': '第三章',
    'Chapter 4': '第四章',
    'Chapter 5': '第五章',
    'Ending': '结局',
    'True Ending': '真结局',
    'Secret Ending': '隐藏结局',
    'Speedrun': '速通',

    // 战斗/击杀
    'Sharpshooter': '神枪手',
    'Sniper': '狙击手',
    'Assassin': '刺客',
    'Mercenary': '佣兵',
    'Slayer': '屠戮者',
    'Executioner': '刽子手',
    'Berserker': '狂战士',
    'Gladiator': '角斗士',
    'Champion': '冠军',
    'Survivor': '幸存者',
    'Undefeated': '不败',
    'Invincible': '无敌',
    'Unstoppable': '势不可挡',
    'Combo King': '连击王',
    'Perfect Combo': '完美连击',
    'Headshot': '爆头',
    'Double Kill': '双杀',
    'Triple Kill': '三杀',
    'Multikill': '多杀',
    'Rampage': '狂暴',
    'Godlike': '超神',

    // 收集
    'Collector': '收藏家',
    'Hoarder': '囤积者',
    'Treasure Hunter': '寻宝猎人',
    'Archaeologist': '考古学家',
    'Librarian': '图书管理员',
    'Completionist': '完美主义者',
    'Gotta Catch Em All': '全收集',
    'Full Collection': '完整收藏',
    'All Weapons': '全武器',
    'All Armor': '全防具',
    'All Items': '全道具',
    'All Spells': '全法术',
    'All Skills': '全技能',
    'All Upgrades': '全升级',

    // 探索
    'Explorer': '探险家',
    'Pathfinder': '探路者',
    'Cartographer': '制图师',
    'Globetrotter': '环球旅行家',
    'Wanderer': '流浪者',
    'Nomad': '游牧民',
    'Pilgrim': '朝圣者',
    'Tourist': '游客',
    'Sightseer': '观光客',
    'Discoverer': '发现者',
    'Uncharted': '未知领域',
    'Hidden Area': '隐藏区域',
    'Secret Found': '发现秘密',
    'All Secrets': '全部秘密',
    'Every Corner': '每个角落',

    // 等级/进度
    'Level Up': '升级',
    'Max Level': '满级',
    'Level 10': '10级',
    'Level 20': '20级',
    'Level 50': '50级',
    'Level 100': '100级',
    'Veteran': '老兵',
    'Hardened': '硬核',
    'Elite': '精英',

    // 难度
    'Easy Mode': '简单模式',
    'Normal Mode': '普通模式',
    'Hard Mode': '困难模式',
    'Nightmare Mode': '噩梦模式',
    'Hell Mode': '地狱模式',
    'No Death': '零死亡',
    'No Damage': '无伤',
    'Flawless': '完美无瑕',
    'Pacifist': '和平主义者',
    'Genocide': '灭绝者',
    'Warmonger': '战争贩子',

    // 财富/资源
    'Rich': '富翁',
    'Millionaire': '百万富翁',
    'Billionaire': '亿万富翁',
    'Money Maker': '印钞机',
    'Gold Digger': '淘金者',
    'Misery': '穷困潦倒',
    'Penny Pincher': '铁公鸡',
    'Shopaholic': '购物狂',

    // 制作/建造
    'Crafter': '工匠',
    'Artisan': '手艺人',
    'Blacksmith': '铁匠',
    'Alchemist': '炼金术士',
    'Enchanter': '附魔师',
    'Cook': '厨师',
    'Brewer': '酿造师',
    'Builder': '建造者',
    'Architect': '建筑师',
    'Engineer': '工程师',

    // 社交/NPC
    'Friend': '朋友',
    'Best Friend': '挚友',
    'Romance': '浪漫',
    'Marriage': '结婚',
    'Betrayal': '背叛',
    'Savior': '救世主',
    'Hero': '英雄',
    'Villain': '反派',
    'Outlaw': '法外之徒',

    // 宠物/坐骑
    'Pet Owner': '宠物主人',
    'Beast Master': '兽王',
    'Tamer': '驯兽师',
    'Rider': '骑手',
    'Dragon Rider': '龙骑士',

    // 特殊/趣味
    'Vegetarian': '素食主义者',
    'Vegan': '纯素食',
    'Cannibal': '食人族',
    'Thief': '小偷',
    'Burglar': '窃贼',
    'Pickpocket': '扒手',
    'Prankster': '恶作剧者',
    'Jester': '小丑',
    'Clown': '小丑',
    'Daredevil': '敢死队',
    'Risk Taker': '冒险家',
    'Gambler': '赌徒',
    'Lucky': '幸运儿',
    'Unlucky': '倒霉蛋',
    'Oops': '哎呀',
    'Fail': '失败',
    'Game Over': '游戏结束',
    'Try Again': '再来一次',
    'Persistence': '坚持不懈',
    'Determination': '决心',
    'Never Give Up': '永不放弃',

    // 时间相关
    'Night Owl': '夜猫子',
    'Early Bird': '早起鸟',
    'Time Traveler': '时间旅行者',
    'Timeless': '永恒',
    'Speed Demon': '速度狂魔',
    'Marathon': '马拉松',
    'Sprint': '冲刺',

    // 特殊成就类型
    'Achievement Unlocked': '成就解锁',
    'Hidden Achievement': '隐藏成就',
    'Secret Achievement': '秘密成就',
    'Easter Egg': '彩蛋',
    'Developer Room': '开发者房间',
    'Debug Mode': '调试模式',
    'Cheater': '作弊者',
    'Legit': '正当游戏',
  };
}
