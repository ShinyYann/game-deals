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

  /// 获取 Steam 徽章/等级/卡牌数据
  Future<Map<String, dynamic>> fetchBadges() async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/badges?steamid=$steamId'),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam badges fetch failed: ${resp.statusCode}');
  }

  /// 获取最近游玩的 Steam 游戏
  Future<Map<String, dynamic>> fetchRecentGames() async {
    final resp = await http.get(
      Uri.parse('$_server/api/steam/recent?steamid=$steamId'),
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('error')) throw Exception(data['error']);
      return data;
    }
    throw Exception('Steam recent games fetch failed: ${resp.statusCode}');
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
    // 已有中文 → 直接返回
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(name)) return name;
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

  /// 自动翻译游戏名称（英文→中文），已有中文直接返回
  static String translateGameName(String name) {
    if (name.isEmpty) return name;
    // 已有中文 → 不变
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(name)) return name;
    // 查表
    if (_gameNameDict.containsKey(name)) return _gameNameDict[name]!;
    // 对英文名做简单处理：去掉TM标记，保留原名
    return name.replaceAll(RegExp(r'™|®'), '');
  }

  /// 游戏名称英→中翻译表
  static const Map<String, String> _gameNameDict = {
    'Counter-Strike 2': '反恐精英 2',
    'Counter-Strike: Global Offensive': '反恐精英：全球攻势',
    'Dota 2': '刀塔 2',
    'PUBG: BATTLEGROUNDS': '绝地求生',
    'Apex Legends': 'Apex英雄',
    'Elden Ring': '艾尔登法环',
    'Cyberpunk 2077': '赛博朋克2077',
    'The Witcher 3: Wild Hunt': '巫师3：狂猎',
    'Red Dead Redemption 2': '荒野大镖客：救赎2',
    'Grand Theft Auto V': '侠盗猎车手5',
    'God of War': '战神',
    'Horizon Zero Dawn': '地平线：零之曙光',
    'Horizon Forbidden West': '地平线：西之绝境',
    'Spider-Man': '漫威蜘蛛侠',
    'Spider-Man Remastered': '漫威蜘蛛侠 重制版',
    'Spider-Man: Miles Morales': '漫威蜘蛛侠：迈尔斯·莫拉莱斯',
    'The Last of Us Part I': '最后生还者 第一章',
    'Uncharted: Legacy of Thieves Collection': '神秘海域：盗贼传奇合集',
    'Ghost of Tsushima': '对马岛之魂',
    'Death Stranding': '死亡搁浅',
    'Final Fantasy VII Remake': '最终幻想7 重制版',
    'Final Fantasy VII Rebirth': '最终幻想7 重生',
    'Final Fantasy XIV Online': '最终幻想14',
    'Final Fantasy XV': '最终幻想15',
    'MONSTER HUNTER: WORLD': '怪物猎人：世界',
    'MONSTER HUNTER RISE': '怪物猎人：崛起',
    'Monster Hunter Wilds': '怪物猎人：荒野',
    'Monster Hunter: World': '怪物猎人：世界',
    'Dark Souls III': '黑暗之魂3',
    'Dark Souls Remastered': '黑暗之魂 重制版',
    'Dark Souls II': '黑暗之魂2',
    'Sekiro: Shadows Die Twice': '只狼：影逝二度',
    'Bloodborne': '血源诅咒',
    'Hollow Knight': '空洞骑士',
    'Hades': '哈迪斯',
    'Stardew Valley': '星露谷物语',
    'Terraria': '泰拉瑞亚',
    'Stray': '流浪',
    'Disco Elysium': '极乐迪斯科',
    'Baldur\'s Gate 3': '博德之门3',
    'Divinity: Original Sin 2': '神界：原罪2',
    'Skyrim': '上古卷轴5：天际',
    'The Elder Scrolls V: Skyrim': '上古卷轴5：天际',
    'The Elder Scrolls V: Skyrim Special Edition': '上古卷轴5：天际 特别版',
    'Fallout 4': '辐射4',
    'Fallout: New Vegas': '辐射：新维加斯',
    'Fallout 76': '辐射76',
    'DOOM Eternal': '毁灭战士：永恒',
    'DOOM (2016)': '毁灭战士',
    'Resident Evil 4': '生化危机4',
    'Resident Evil 2': '生化危机2 重制版',
    'Resident Evil Village': '生化危机8：村庄',
    'Resident Evil 7': '生化危机7',
    'Resident Evil 3': '生化危机3 重制版',
    'Street Fighter 6': '街头霸王6',
    'Tekken 8': '铁拳8',
    'Persona 5 Royal': '女神异闻录5 皇家版',
    'Persona 4 Golden': '女神异闻录4 黄金版',
    'Persona 3 Reload': '女神异闻录3 重制版',
    'NieR:Automata': '尼尔：机械纪元',
    'NieR Replicant': '尼尔：人工生命',
    'Metal Gear Solid V': '合金装备5：幻痛',
    'Devil May Cry 5': '鬼泣5',
    'Bayonetta': '猎天使魔女',
    'Darkest Dungeon': '暗黑地牢',
    'Slay the Spire': '杀戮尖塔',
    'Celeste': '蔚蓝',
    'Portal 2': '传送门2',
    'Half-Life 2': '半条命2',
    'Half-Life: Alyx': '半条命：爱莉克斯',
    'Left 4 Dead 2': '求生之路2',
    'Team Fortress 2': '军团要塞2',
    'Borderlands 3': '无主之地3',
    'Borderlands 2': '无主之地2',
    'BioShock Infinite': '生化奇兵：无限',
    'Prey': '掠食',
    'Dishonored 2': '耻辱2',
    'Control': '控制',
    'Alan Wake 2': '心灵杀手2',
    'Alan Wake': '心灵杀手',
    'Mass Effect Legendary Edition': '质量效应 传奇版',
    'Dragon Age: Inquisition': '龙腾世纪：审判',
    'Cities: Skylines': '城市：天际线',
    'Cities: Skylines II': '城市：天际线2',
    'Euro Truck Simulator 2': '欧洲卡车模拟2',
    'Factorio': '异星工厂',
    'RimWorld': '边缘世界',
    'Satisfactory': '幸福工厂',
    'Subnautica': '深海迷航',
    'Valheim': '英灵神殿',
    'Don\'t Starve Together': '饥荒联机版',
    'Risk of Rain 2': '雨中冒险2',
    'Vampire Survivors': '吸血鬼幸存者',
    'Dead Cells': '死亡细胞',
    'Into the Breach': '陷阵之志',
    'FTL: Faster Than Light': '超越光速',
    'Battlefield 2042': '战地风云2042',
    'Battlefield 1': '战地风云1',
    'Battlefield V': '战地风云5',
    'Call of Duty: Modern Warfare II': '使命召唤：现代战争II',
    'Call of Duty: Modern Warfare 2019': '使命召唤：现代战争',
    'Call of Duty: Black Ops Cold War': '使命召唤：黑色行动冷战',
    'Tom Clancy\'s Rainbow Six Siege': '彩虹六号：围攻',
    'Tom Clancy\'s The Division 2': '全境封锁2',
    'Ghost Recon Breakpoint': '幽灵行动：断点',
    'Watch Dogs 2': '看门狗2',
    'Assassin\'s Creed Valhalla': '刺客信条：英灵殿',
    'Assassin\'s Creed Odyssey': '刺客信条：奥德赛',
    'Assassin\'s Creed Origins': '刺客信条：起源',
    'FAR CRY 6': '孤岛惊魂6',
    'FAR CRY 5': '孤岛惊魂5',
    'Far Cry New Dawn': '孤岛惊魂：新曙光',
    'Deep Rock Galactic': '深岩银河',
    'Helldivers 2': '地狱潜者2',
    'Palworld': '幻兽帕鲁',
    'Lies of P': '匹诺曹的谎言',
    'Black Myth: Wukong': '黑神话：悟空',
    'Armored Core VI: Fires of Rubicon': '装甲核心6',
    'TEKKEN 8': '铁拳8',
    'NARAKA: BLADEPOINT': '永劫无间',
    'The Finals': 'The Finals',
    'Valorant': '无畏契约',
    'Overwatch 2': '守望先锋2',
    'Destiny 2': '命运2',
    'Warframe': '星际战甲',
    'Path of Exile': '流放之路',
    'Genshin Impact': '原神',
    'Honkai: Star Rail': '崩坏：星穹铁道',
    'Zenless Zone Zero': '绝区零',
    'Wuthering Waves': '鸣潮',
    '7 Days to Die': '七日杀',
    'ARK: Survival Evolved': '方舟：生存进化',
    'Rust': '腐蚀',
    'DayZ': 'DayZ',
    'Project Zomboid': '僵尸毁灭工程',
    'Phasmophobia': '恐鬼症',
    'Lethal Company': '致命公司',
    'Content Warning': '内容警告',
    'It Takes Two': '双人成行',
    'A Way Out': '逃出生天',
    'No Man\'s Sky': '无人深空',
    'The Forest': '森林',
    'Sons of the Forest': '森林之子',
    'Green Hell': '绿色地狱',
    'Grounded': '禁闭求生',
    'Stellaris': '群星',
    'Civilization VI': '文明6',
    'Total War: WARHAMMER III': '全面战争：战锤3',
    'Total War: THREE KINGDOMS': '全面战争：三国',
    'Age of Empires IV': '帝国时代4',
    'Age of Empires II: Definitive Edition': '帝国时代2：决定版',
    'Hearts of Iron IV': '钢铁雄心4',
    'Europa Universalis IV': '欧陆风云4',
    'Crusader Kings III': '十字军之王3',
    'Victoria 3': '维多利亚3',
    'Hogwarts Legacy': '霍格沃茨之遗',
    'Starfield': '星空',
    'Forza Horizon 5': '极限竞速：地平线5',
    'Forza Horizon 4': '极限竞速：地平线4',
    'Microsoft Flight Simulator': '微软模拟飞行',
    'Halo Infinite': '光环：无限',
    'Halo: The Master Chief Collection': '光环：士官长合集',
    'Gears 5': '战争机器5',
    'AC Mirage': '刺客信条：幻景',
    'Star Wars Jedi: Survivor': '星球大战绝地：幸存者',
    'Star Wars Jedi: Fallen Order': '星球大战绝地：陨落的武士团',
    'Atomic Heart': '原子之心',
    'Hi-Fi RUSH': 'Hi-Fi RUSH',
    'Shadow of the Tomb Raider': '古墓丽影：暗影',
    'Rise of the Tomb Raider': '古墓丽影：崛起',
    'Tomb Raider': '古墓丽影',
    'Detroit: Become Human': '底特律：变人',
    'Heavy Rain': '暴雨',
    'Beyond: Two Souls': '超凡双生',
    'Sifu': '师父',
    'Ghostrunner': '幽灵行者',
    'Hotline Miami': '迈阿密热线',
    'Katana Zero': '武士零',
    'Ori and the Blind Forest': '奥日与黑暗森林',
    'Ori and the Will of the Wisps': '奥日与萤火意志',
    'Cuphead': '茶杯头',
    'Undertale': '传说之下',
    'Deltarune': '三角符文',
    'Omori': 'OMORI',
    'Outer Wilds': '星际拓荒',
    'What Remains of Edith Finch': '艾迪芬奇的记忆',
    'Firewatch': '看火人',
    'Journey': '风之旅人',
    'ABZU': '智慧之海',
    'GRIS': '格莉斯的旅程',
    'Neon White': '霓虹白客',
    'Return of the Obra Dinn': '奥伯拉丁的归来',
    'Papers, Please': '请出示证件',
    'Returnal': '死亡回归',
    'Dave the Diver': '潜水员戴夫',
    'Sea of Stars': '星之海',
    'Chained Together': '链在一起',
    'Minecraft': '我的世界',
    'Football Manager 2024': '足球经理2024',
    'EA Sports FC 24': 'EA Sports FC 24',
    'eFootball 2024': 'eFootball 2024',
    'NBA 2K24': 'NBA 2K24',
    'FIFA 23': 'FIFA 23',
    'WWE 2K24': 'WWE 2K24',
    'Granblue Fantasy: Relink': '碧蓝幻想：Relink',
    'Dragon\'s Dogma 2': '龙之信条2',
    'Dragon\'s Dogma: Dark Arisen': '龙之信条：黑暗觉者',
    'Like a Dragon: Infinite Wealth': '如龙8：无限财富',
    'Like a Dragon: Gaiden': '如龙7外传',
    'Yakuza 0': '如龙0',
    'Yakuza Kiwami': '如龙：极',
    'Yakuza Kiwami 2': '如龙：极2',
    'Judgment': '审判之眼',
    'Lost Judgment': '审判之逝',
    'Warhammer: Vermintide 2': '战锤：末世鼠疫2',
    'Oxygen Not Included': '缺氧',
    'Wallpaper Engine': '壁纸引擎',
    'Sid Meier\'s Civilization VI': '文明6',
    'Danganronpa 2: Goodbye Despair': '弹丸论破2',
    'The Witcher: Enhanced Edition': '巫师：增强版',
    'Danganronpa: Trigger Happy Havoc': '弹丸论破1',
    'PAYDAY 2': '收获日2',
    'Where Winds Meet': '燕云十六声',
    'Yu-Gi-Oh!  Master Duel': '游戏王：大师决斗',
    'The Escapists 2': '逃脱者2',
    'TEKKEN 7': '铁拳7',
    'MyDockFinder': 'MyDockFinder',
    'The Legend of Heroes: Trails in the Sky the 3rd': '英雄传说：空之轨迹 the 3rd',
    'STEINS;GATE': '命运石之门',
    'Riichi City - Japanese Mahjong': 'Riichi City 立直麻将',
    'Lossless Scaling': 'Lossless Scaling',
    'Mind Over Magic': '魔法之上',
    'Tabletop Simulator': '桌游模拟器',
    'Gloomhaven': '幽港迷城',
    'The Scroll Of Taiwu': '太吾绘卷',
    'Danganronpa Another Episode: Ultra Despair Girls': '绝对绝望少女',
    'Batman™: Arkham Knight': '蝙蝠侠：阿卡姆骑士',
    'Chinese Parents': '中国式家长',
    'Bloodstained: Ritual of the Night': '赤痕：夜之仪式',
    'Dying Light': '消逝的光芒',
    'Grand Theft Auto V Legacy': 'GTA5 Legacy',
    'Zombie Army Trilogy': '僵尸部队三部曲',
    'Don\'t Starve': '饥荒',
    'Divinity: Original Sin Enhanced Edition': '神界：原罪 增强版',
    'Eastward': '风来之国',
    'Sekiro™: Shadows Die Twice': '只狼：影逝二度',
    'Cassette Beasts': '磁带妖怪',
    'Thronebreaker: The Witcher Tales': '王权的陨落：巫师传说',
    'Ni no Kuni™ II: Revenant Kingdom': '二之国2：亡灵国度',
    'RPG Maker MV': 'RPG制作大师 MV',
    'Sleeping Dogs: Definitive Edition': '热血无赖：决定版',
    'Hyperdimension Neptunia Re;Birth1': '超次元游戏海王星 重生1',
    'ONE PIECE World Seeker': '海贼王：世界探索者',
    'Dead or School': '死或学园',
    'The Witcher 2: Assassins of Kings Enhanced Edition': '巫师2：国王刺客 增强版',
    'Life is Strange™': '奇异人生',
    'Disgaea PC': '魔界战记 PC',
    'Sword Art Online: Fatal Bullet': '刀剑神域：夺命凶弹',
    'Shadow Warrior 2': '影武者2',
    'Batman™: Arkham Origins Blackgate - Deluxe Edition': '蝙蝠侠：阿卡姆起源黑门',
    'Catherine Classic': '凯瑟琳 经典版',
    'Full Spectrum Warrior': '全光谱战士',
    'Full Spectrum Warrior: Ten Hammers': '全光谱战士：十锤',
    'Tomb Raider: Legend': '古墓丽影：传奇',
    'Tomb Raider: Anniversary': '古墓丽影：周年纪念版',
    'Tomb Raider: Underworld': '古墓丽影：地下世界',
    'Frontlines: Fuel of War': '前线：战争燃料',
    'Red Faction: Guerrilla Steam Edition': '红色派系：游击战',
    'Lara Croft and the Guardian of Light': '劳拉与光之守护者',
    'Batman: Arkham Asylum GOTY Edition': '蝙蝠侠：阿卡姆疯人院',
    'Darksiders': '暗黑血统',
    'Red Faction: Armageddon': '红色派系：末日审判',
    'MX vs. ATV Reflex': 'MX vs. ATV 越野摩托',
    'Batman: Arkham City GOTY': '蝙蝠侠：阿卡姆之城',
    'Batman™: Arkham Origins': '蝙蝠侠：阿卡姆起源',
    'Tomb Raider I': '古墓丽影 I',
    'Tomb Raider: The Last Revelation (1999)': '古墓丽影：最后的启示',
    'Tomb Raider: Chronicles (2000)': '古墓丽影：历代记',
    'Tomb Raider (VI): The Angel of Darkness (2003)': '古墓丽影：黑暗天使',
    'Tomb Raider II': '古墓丽影 II',
    'Tomb Raider III: Adventures of Lara Croft': '古墓丽影 III',
    'Divinity: Original Sin (Classic)': '神界：原罪 经典版',
    'Company of Heroes 2': '英雄连2',
    'Middle-earth™: Shadow of Mordor™': '中土世界：暗影魔多',
    'Damned': 'Damned',
    '100% Orange Juice': '100%橙汁',
    'Lara Croft and the Temple of Osiris': '劳拉与奥西里斯神庙',
    'Valkyria Chronicles™': '战场女武神',
    'Hyperdimension Neptunia Re;Birth2 Sisters Generation': '超次元游戏海王星 重生2',
    'Hyperdimension Neptunia Re;Birth3 V Generation': '超次元游戏海王星 重生3',
    'Middle-earth™: Shadow of War™': '中土世界：战争之影',
    'DOOM': '毁灭战士',
    'Darksiders II Deathinitive Edition': '暗黑血统2 终极版',
    'ARK: Survival Of The Fittest': '方舟：适者生存',
    'Draw Slasher': 'Draw Slasher',
    'Kabounce': 'Kabounce',
    'Darksiders Warmastered Edition': '暗黑血统 战神版',
    'Titan Quest Anniversary Edition': '泰坦之旅',
    'Minion Masters': 'Minion Masters',
    'Disgaea 2 PC': '魔界战记2 PC',
    'Streets of Rogue': 'Streets of Rogue',
    'Lara Croft GO': '劳拉GO',
    'Estranged: The Departure': '陌路：启程',
    'Tokyo Xanadu eX+': '东京幻都 eX+',
    'Red Faction Guerrilla Re-Mars-tered': '红色派系：游击战 重制版',
    'Valkyria Chronicles 4 Complete Edition': '战场女武神4',
    'Shining Resonance Refrain': '光明之响 龙奏回音',
    'STEINS;GATE 0': '命运石之门0',
    'Little Nightmares II': '小小梦魇2',
    'NEOVERSE': 'NEOVERSE',
    'Heroes of the Three Kingdoms': '三国群英传',
    'Toy Tinker Simulator': 'Toy Tinker Simulator',
    'Grand Theft Auto V Enhanced': 'GTA5 增强版',
  };

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
