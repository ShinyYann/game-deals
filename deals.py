#!/usr/bin/env python3
"""
游戏折扣情报系统
PSN港服 + Steam国服 + Switch日服 — 每日自动更新
输出: docs/index.html (GitHub Pages)
"""

import urllib.request, urllib.parse, re, json, html as html_mod, ssl, os, sys, time
from bs4 import BeautifulSoup

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def fetch(url, timeout=15):
    req = urllib.request.Request(url, headers={
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    })
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=ctx) as r:
            return r.read().decode('utf-8', errors='replace')
    except:
        return None

def fetch_json(url, timeout=15):
    d = fetch(url, timeout)
    if d:
        try: return json.loads(d)
        except: pass
    return None

# ─── Ratings ────────────────────────────────────────────────────────
RATINGS = {
    # ─── From parsed data (actual deals) ───
    'elden ring': '⭐⭐⭐⭐ MC96 开放世界RPG标杆',
    'ghost of tsushima': '⭐⭐⭐⭐ MC87 武士开放世界，必玩',
    'resident evil 4': '⭐⭐⭐⭐⭐ MC93 恐怖动作巅峰',
    'gran turismo 7': '⭐⭐⭐⭐ MC87 PS最强赛车',
    'persona': '⭐⭐⭐⭐⭐ MC93 日式RPG天花板',
    'cyberpunk': '⭐⭐⭐⭐ MC86 已修复值得玩',
    'grand theft auto': '⭐⭐⭐⭐⭐ MC97 开放世界之王',
    'split fiction': '⭐⭐⭐⭐⭐ MC90 双人合作必玩',
    'stellar blade': '⭐⭐⭐⭐ MC81 动作RPG战斗爽',
    'dynasty warriors': '⭐⭐⭐⭐ MC80 真三革新作',
    'balatro': '⭐⭐⭐⭐ MC90 独立游戏神作',
    'hades': '⭐⭐⭐⭐⭐ MC93 肉鸽天花板',
    'hades ii': '⭐⭐⭐⭐ MC86 肉鸽续作',
    'black myth': '⭐⭐⭐⭐ MC81 国产之光',
    'wukong': '⭐⭐⭐⭐ MC81 国产之光',
    'witcher': '⭐⭐⭐⭐⭐ MC92 西方RPG天花板',
    'the witcher': '⭐⭐⭐⭐⭐ MC92 西方RPG天花板',
    'monster hunter': '⭐⭐⭐⭐ MC86 共斗RPG标杆',
    'red dead': '⭐⭐⭐⭐⭐ MC97 西部开放世界',
    'final fantasy': '⭐⭐⭐⭐ MC87 JRPG经典',
    'god of war': '⭐⭐⭐⭐⭐ MC94 动作剧情巅峰',
    'spider-man': '⭐⭐⭐⭐ MC87 超级英雄开放世界',
    'last of us': '⭐⭐⭐⭐⭐ MC95 剧情神作',
    'zelda': '⭐⭐⭐⭐⭐ MC97 开放世界标杆',
    'mario': '⭐⭐⭐⭐ MC93 平台跳跃之王',
    'metroid': '⭐⭐⭐⭐ MC88 银河城经典',
    'kirby': '⭐⭐⭐⭐ MC81 可爱动作冒险',
    'splatoon': '⭐⭐⭐⭐ MC83 涂鸦对战',
    'animal crossing': '⭐⭐⭐⭐ MC90 治愈模拟经营',
    'xenoblade': '⭐⭐⭐⭐ MC89 JRPG史诗',
    'fire emblem': '⭐⭐⭐⭐ MC89 战略RPG',
    'tekken': '⭐⭐⭐⭐ MC82 格斗游戏标杆',
    'street fighter': '⭐⭐⭐⭐ MC92 格斗之王',
    'silent hill': '⭐⭐⭐⭐ MC86 恐怖生存经典',
    'dark souls': '⭐⭐⭐⭐⭐ MC89 魂系鼻祖',
    'sekiro': '⭐⭐⭐⭐⭐ MC90 动作巅峰',
    'bloodborne': '⭐⭐⭐⭐⭐ MC92 哥特魂系',
    'nier': '⭐⭐⭐⭐ MC88 横尾风格RPG',
    # ─── More popular titles ───
    'horizon': '⭐⭐⭐⭐ MC89 机械兽开放世界',
    'gow ragnarok': '⭐⭐⭐⭐⭐ MC94 北欧神话终章',
    'ratchet & clank': '⭐⭐⭐⭐ MC88 画面天花板',
    'returnal': '⭐⭐⭐⭐ MC86 循环射击创新',
    'demons souls': '⭐⭐⭐⭐⭐ MC92 重制画面标杆',
    'sackboy': '⭐⭐⭐⭐ MC79 可爱平台跳跃',
    'uncharted': '⭐⭐⭐⭐⭐ MC87 动作冒险大片',
    'dreams': '⭐⭐⭐⭐ MC89 创作游戏神作',
    'astros playroom': '⭐⭐⭐⭐ MC83 PS5手柄展示',
    'ghwire: tokyo': '⭐⭐⭐⭐ MC75 东京风水和风',
    'death stranding': '⭐⭐⭐⭐ MC82 小岛步行模拟',
    'deathloop': '⭐⭐⭐⭐ MC88 循环刺杀创新',
    'evil west': '⭐⭐⭐⭐ MC73 西部吸血鬼爽游',
    'callisto protocol': '⭐⭐⭐ MC70 太空恐怖不足',
    'hogwarts legacy': '⭐⭐⭐⭐ MC84 哈利波特开放世界',
    'dead space': '⭐⭐⭐⭐⭐ MC89 恐怖重制标杆',
    'resident evil 2': '⭐⭐⭐⭐⭐ MC91 生化重制巅峰',
    'resident evil 3': '⭐⭐⭐⭐ MC79 重制不够诚意',
    'resident evil village': '⭐⭐⭐⭐ MC84 第一人称恐怖',
    'resident evil revelations': '⭐⭐⭐⭐ MC75 外传佳作',
    'stranger of paradise': '⭐⭐⭐⭐ MC72 最终幻想外传',
    'wo long': '⭐⭐⭐⭐ MC80 三国仁王',
    'lies of p': '⭐⭐⭐⭐ MC80 匹诺曹魂系',
    'armored core': '⭐⭐⭐⭐ MC86 机甲动作回归',
    'like a dragon': '⭐⭐⭐⭐ MC86 如龙RPG转型',
    'judgment': '⭐⭐⭐⭐ MC82 如龙侦探版',
    'lost judgment': '⭐⭐⭐⭐ MC83 侦探续作',
    'yakuza': '⭐⭐⭐⭐ MC80 日本黑道RPG',
    'fifa': '⭐⭐⭐ MC75 年货足球',
    'ea sports fc': '⭐⭐⭐ MC75 足球年货',
    'madden': '⭐⭐⭐ MC73 橄榄球年货',
    'nba 2k': '⭐⭐⭐ MC70 篮球年货',
    'call of duty': '⭐⭐⭐⭐ MC78 年货FPS',
    'battlefield': '⭐⭐⭐⭐ MC80 大型战场FPS',
    'battlefield 2042': '⭐⭐⭐ MC68 翻车战场',
    'doom': '⭐⭐⭐⭐⭐ MC87 暴力FPS之王',
    'doom eternal': '⭐⭐⭐⭐⭐ MC88 高速FPS巅峰',
    'wolfenstein': '⭐⭐⭐⭐ MC79 纳粹射击',
    'far cry': '⭐⭐⭐ MC75 育碧开放世界',
    'assassins creed': '⭐⭐⭐⭐ MC75 历史开放世界',
    'watch dogs': '⭐⭐⭐ MC73 黑客开放世界',
    'ghost recon': '⭐⭐⭐ MC70 战术射击',
    'the division': '⭐⭐⭐ MC70 刷宝射击',
    'rainbow six': '⭐⭐⭐ MC78 战术爆破',
    'immortals fenyx': '⭐⭐⭐⭐ MC79 希腊风格原神',
    'tomb raider': '⭐⭐⭐⭐ MC85 考古动作冒险',
    'rise of the tomb raider': '⭐⭐⭐⭐ MC88 考古续作',
    'shadow of the tomb raider': '⭐⭐⭐⭐ MC82 考古终章',
    'control': '⭐⭐⭐⭐ MC82 超能力射击',
    'alan wake': '⭐⭐⭐⭐ MC80 心理恐怖',
    'alan wake 2': '⭐⭐⭐⭐⭐ MC89 心理恐怖巅峰',
    'quantum break': '⭐⭐⭐⭐ MC77 时间控制射击',
    'mass effect': '⭐⭐⭐⭐⭐ MC90 科幻RPG经典',
    'dragon age': '⭐⭐⭐⭐ MC85 奇幻RPG',
    'anthem': '⭐⭐⭐ MC65 翻车刷宝',
    'fallout': '⭐⭐⭐⭐ MC84 废土RPG',
    'skyrim': '⭐⭐⭐⭐⭐ MC96 开放世界RPG丰碑',
    'starfield': '⭐⭐⭐ MC78 太空RPG失望',
    'outer worlds': '⭐⭐⭐⭐ MC82 太空RPG小品',
    'disco elysium': '⭐⭐⭐⭐⭐ MC91 叙事RPG神作',
    'divinity': '⭐⭐⭐⭐⭐ MC93 策略RPG巅峰',
    'baldurs gate': '⭐⭐⭐⭐⭐ MC96 CRPG王者回归',
    'pathfinder': '⭐⭐⭐⭐ MC80 硬核CRPG',
    'pillars of eternity': '⭐⭐⭐⭐ MC89 复古CRPG',
    'kingdom come': '⭐⭐⭐⭐ MC71 硬核中世纪RPG',
    'mount & blade': '⭐⭐⭐⭐ MC78 骑砍沙盒RPG',
    'rimworld': '⭐⭐⭐⭐ MC90 殖民模拟',
    'factorio': '⭐⭐⭐⭐⭐ MC90 工厂自动化',
    'satisfactory': '⭐⭐⭐⭐ MC87 3D工厂',
    'terraria': '⭐⭐⭐⭐⭐ MC82 2D沙盒冒险',
    'stardew valley': '⭐⭐⭐⭐⭐ MC89 农场经营治愈',
    'minecraft': '⭐⭐⭐⭐⭐ MC92 沙盒创造之王',
    'no mans sky': '⭐⭐⭐⭐ MC71 逆袭典范',
    'subnautica': '⭐⭐⭐⭐ MC87 深海生存探索',
    'the forest': '⭐⭐⭐⭐ MC83 恐怖生存',
    'valheim': '⭐⭐⭐⭐ MC89 北欧生存沙盒',
    'project zomboid': '⭐⭐⭐⭐ MC70 僵尸生存模拟',
    'dont starve': '⭐⭐⭐⭐ MC79 荒野生存',
    'oxygen not included': '⭐⭐⭐⭐ MC87 太空殖民地',
    'slay the spire': '⭐⭐⭐⭐⭐ MC89 卡牌Roguelike始祖',
    'monster train': '⭐⭐⭐⭐ MC83 卡牌防御',
    'dead cells': '⭐⭐⭐⭐⭐ MC87 动作肉鸽',
    'hollow knight': '⭐⭐⭐⭐⭐ MC87 银河城神作',
    'celeste': '⭐⭐⭐⭐⭐ MC92 平台跳跃神作',
    'cuphead': '⭐⭐⭐⭐⭐ MC86 手绘BOSS战',
    'shovel knight': '⭐⭐⭐⭐ MC86 复古平台',
    'blasphemous': '⭐⭐⭐⭐ MC80 宗教画风银河城',
    'ori': '⭐⭐⭐⭐⭐ MC88 唯美银河城',
    'guacamelee': '⭐⭐⭐⭐ MC83 墨西哥风格银河城',
    'astral chain': '⭐⭐⭐⭐ MC83 未来警探动作',
    'bayonetta': '⭐⭐⭐⭐ MC86 华丽ACT',
    'devil may cry': '⭐⭐⭐⭐ MC86 华丽动作',
    'metal gear': '⭐⭐⭐⭐⭐ MC94 潜行战术经典',
    'ace combat': '⭐⭐⭐⭐ MC80 空战模拟',
    'soulcalibur': '⭐⭐⭐⭐ MC76 刀剑格斗',
    'guilty gear': '⭐⭐⭐⭐ MC84 动漫格斗',
    'dragon ball': '⭐⭐⭐⭐ MC76 龙珠格斗',
    'naruto': '⭐⭐⭐ MC70 火影格斗',
    'one piece': '⭐⭐⭐ MC75 海贼动作',
    'borderlands': '⭐⭐⭐⭐ MC79 卡通刷宝射击',
    'diablo': '⭐⭐⭐⭐ MC87 暗黑刷宝始祖',
    'diablo iv': '⭐⭐⭐⭐ MC77 暗黑续作有起色',
    'path of exile': '⭐⭐⭐⭐ MC84 免费暗黑',
    'greedfall': '⭐⭐⭐ MC72 殖民RPG',
    'vampyr': '⭐⭐⭐⭐ MC72 吸血鬼RPG',
    'plague tale': '⭐⭐⭐⭐ MC85 老鼠末日剧情',
    'it takes two': '⭐⭐⭐⭐⭐ MC88 双人合作神作',
    'mortal kombat': '⭐⭐⭐⭐ MC82 暴力格斗',
    'snk': '⭐⭐⭐ MC73 老牌格斗',
    'king of fighters': '⭐⭐⭐⭐ MC79 拳皇格斗',
    'crash bandicoot': '⭐⭐⭐⭐ MC78 经典平台',
    'spyro': '⭐⭐⭐⭐ MC79 可爱平台',
    'medievil': '⭐⭐⭐⭐ MC70 经典重制',
    'tony hawk': '⭐⭐⭐⭐ MC80 滑板运动',
    'hell let loose': '⭐⭐⭐⭐ MC79 硬核二战',
    'squad': '⭐⭐⭐ MC78 硬核战术',
    'post scriptum': '⭐⭐⭐ MC75 二战拟真',
    'insurgency': '⭐⭐⭐⭐ MC81 硬核CQB',
    'escape from tarkov': '⭐⭐⭐⭐ MC77 硬核撤离',
    'dayz': '⭐⭐⭐ MC71 丧尸生存',
    'rust': '⭐⭐⭐⭐ MC69 生存沙盒残酷',
    'ark': '⭐⭐⭐⭐ MC70 恐龙生存',
    'conan exiles': '⭐⭐⭐ MC69 野蛮生存',
    'darksiders': '⭐⭐⭐⭐ MC80 上帝之战动作',
    'mad max': '⭐⭐⭐⭐ MC73 废土动作',
    'middle earth': '⭐⭐⭐⭐ MC82 魔多暗影动作',
    'batman': '⭐⭐⭐⭐⭐ MC87 蝙蝠侠动作经典',
    'shadow of mordor': '⭐⭐⭐⭐ MC85 中土世界复仇',
    'lego': '⭐⭐⭐ MC72 乐高合家欢',
    'overcooked': '⭐⭐⭐⭐ MC80 分手厨房',
    'moving out': '⭐⭐⭐ MC71 搬家合作',
    'human fall flat': '⭐⭐⭐⭐ MC76 物理搞笑',
    'gang beasts': '⭐⭐⭐⭐ MC70 物理对打',
    'fall guys': '⭐⭐⭐⭐ MC77 糖豆人大逃杀',
    'among us': '⭐⭐⭐⭐ MC77 太空狼人杀',
    'phasmophobia': '⭐⭐⭐⭐ MC79 恐怖捉鬼',
    'lethal company': '⭐⭐⭐⭐ MC78 恐怖公司合作',
    'content warning': '⭐⭐⭐ MC70 恐怖拍摄',
    'deep rock galactic': '⭐⭐⭐⭐ MC82 矮人挖矿合作',
    'helldivers': '⭐⭐⭐⭐ MC80 民主第一人称',
    'helldivers 2': '⭐⭐⭐⭐⭐ MC81 民主第三人称',
    'back 4 blood': '⭐⭐⭐ MC72 丧尸射击不够好',
    'left 4 dead': '⭐⭐⭐⭐⭐ MC85 丧尸射击经典',
    'payday': '⭐⭐⭐ MC78 抢劫射击',
    'killing floor': '⭐⭐⭐⭐ MC76 丧尸波次',
    'warhammer': '⭐⭐⭐⭐ MC80 战锤射击',
    'darktide': '⭐⭐⭐⭐ MC73 战锤丧尸',
    'vermentide': '⭐⭐⭐⭐ MC77 战锤鼠疫',
    'metro': '⭐⭐⭐⭐ MC82 地铁生存射击',
    'stalker': '⭐⭐⭐⭐ MC80 切尔诺贝利射击',
    'dysmantle': '⭐⭐⭐ MC73 拆解世界生存',
    'grounded': '⭐⭐⭐⭐ MC81 缩小求生',
    'smalland': '⭐⭐⭐ MC70 缩小生存',
    'green hell': '⭐⭐⭐⭐ MC82 亚马逊丛林生存',
    'the long dark': '⭐⭐⭐⭐ MC80 冰雪生存',
    'frostpunk': '⭐⭐⭐⭐ MC85 冰雪城市建造',
    'this war of mine': '⭐⭐⭐⭐ MC84 战争平民生存',
    'banished': '⭐⭐⭐⭐ MC81 中世纪城镇建设',
    'cliff empire': '⭐⭐⭐ MC70 城市建造',
    'the last campfire': '⭐⭐⭐⭐ MC70 治愈解谜',
    'joy of creation': '⭐⭐⭐ MC60 同人',
    'little nightmares': '⭐⭐⭐⭐ MC80 黑暗童话解谜',
    'inside': '⭐⭐⭐⭐⭐ MC93 横版解谜神作',
    'limbo': '⭐⭐⭐⭐⭐ MC88 黑白解谜经典',
    'braid': '⭐⭐⭐⭐⭐ MC92 时间解谜始祖',
    'fez': '⭐⭐⭐⭐ MC91 维度解谜',
    'witness': '⭐⭐⭐⭐⭐ MC87 解谜岛',
    'outer wilds': '⭐⭐⭐⭐⭐ MC85 太空探索解谜',
    'superliminal': '⭐⭐⭐⭐ MC73 视角解谜',
    'portal': '⭐⭐⭐⭐⭐ MC90 传送门解谜',
    'talos principle': '⭐⭐⭐⭐ MC82 哲学解谜',
    'obduction': '⭐⭐⭐ MC72 神秘岛续作',
    'myst': '⭐⭐⭐⭐ MC81 经典解谜重制',
    'return of obra dinn': '⭐⭐⭐⭐⭐ MC89 推理解谜神作',
    'her story': '⭐⭐⭐⭐ MC87 新颖推理',
    'what remains of edith finch': '⭐⭐⭐⭐⭐ MC88 步行模拟巅峰',
    'firewatch': '⭐⭐⭐⭐ MC81 森林步行模拟',
    'journey': '⭐⭐⭐⭐⭐ MC92 艺术游戏巅峰',
    'flower': '⭐⭐⭐⭐ MC76 治愈花之旅',
    'abzu': '⭐⭐⭐⭐ MC76 深海治愈之旅',
    'gris': '⭐⭐⭐⭐ MC76 水彩治愈平台',
    'neva': '⭐⭐⭐⭐ MC77 色彩治愈续作',
    'dredge': '⭐⭐⭐⭐ MC80 钓鱼恐怖',
    'chants of senaar': '⭐⭐⭐⭐ MC82 语言解谜',
    'tt isle': '⭐⭐⭐ MC68',
    'peppa pig': '⭐⭐⭐ MC58 小猪佩奇',
    'bluey': '⭐⭐⭐ MC68 布鲁伊',
    'paw patrol': '⭐⭐⭐ MC57 汪汪队',
    'hot wheels': '⭐⭐⭐ MC68 风火轮赛车',
    'my little pony': '⭐⭐⭐ MC60 小马宝莉',
    'doraemon': '⭐⭐⭐⭐ MC68 哆啦A梦合家欢',
    'demon slayer': '⭐⭐⭐⭐ MC70 鬼灭之刃',
    'jujutsu kaisen': '⭐⭐⭐ MC70 咒术回战',
    'my hero academia': '⭐⭐⭐ MC70 我英',
    'spongebob': '⭐⭐⭐⭐ MC68 海绵宝宝',
    'teenage mutant': '⭐⭐⭐⭐ MC72 忍者神龟',
    'tmnt': '⭐⭐⭐⭐ MC72 忍者神龟',
    'power rangers': '⭐⭐⭐ MC60 恐龙战队',
    'avengers': '⭐⭐⭐ MC68 漫威复联拉胯',
    'guardians of the galaxy': '⭐⭐⭐⭐ MC80 漫威银护黑马',
    'marvel vs capcom': '⭐⭐⭐⭐ MC80 漫威格斗',
    'marvels midnight suns': '⭐⭐⭐⭐ MC78 漫威策略卡牌',
    'marvel rivals': '⭐⭐⭐⭐ MC79 漫威OW',
    'lego star wars': '⭐⭐⭐⭐ MC80 乐高星战',
    'star wars jedi': '⭐⭐⭐⭐ MC80 星战绝地动作',
    'star wars fallen order': '⭐⭐⭐⭐ MC82 星战绝地',
    'star wars survivor': '⭐⭐⭐⭐ MC84 星战绝地续作',
    'star wars battlefront': '⭐⭐⭐ MC70 星战战场',
    'star wars squadrons': '⭐⭐⭐⭐ MC79 星战飞行',
    'star wars old republic': '⭐⭐⭐ MC70 星战MMO',
    'star wars outlaws': '⭐⭐⭐⭐ MC76 星战开放世界',
    'total war': '⭐⭐⭐⭐ MC82 历史策略',
    'civilization': '⭐⭐⭐⭐⭐ MC82 文明策略',
    'civ vi': '⭐⭐⭐⭐⭐ MC82 文明6策略',
    'cities skylines': '⭐⭐⭐⭐ MC82 城市建造',
    'cities skylines 2': '⭐⭐⭐ MC70 城市建造翻车',
    'planet coaster': '⭐⭐⭐⭐ MC75 过山车建造',
    'planet zoo': '⭐⭐⭐⭐ MC78 动物园建造',
    'surviving mars': '⭐⭐⭐⭐ MC76 火星建造',
    'tropico': '⭐⭐⭐⭐ MC72 香蕉共和国建造',
    'anno': '⭐⭐⭐⭐ MC80 纪元城市建造',
    'age of empires': '⭐⭐⭐⭐ MC82 帝国时代RTS',
    'age of mythology': '⭐⭐⭐⭐ MC76 神话RTS',
    'supreme commander': '⭐⭐⭐⭐ MC77 大型RTS',
    'company of heroes': '⭐⭐⭐⭐ MC82 二战RTS',
    'men of war': '⭐⭐⭐⭐ MC77 硬核二战RTS',
    'steel division': '⭐⭐⭐⭐ MC76 二战军团',
    'hearts of iron': '⭐⭐⭐⭐ MC80 二战大战略',
    'europa universalis': '⭐⭐⭐⭐ MC82 大战略经典',
    'crusader kings': '⭐⭐⭐⭐ MC82 中世纪大战略',
    'stellaris': '⭐⭐⭐⭐ MC78 太空大战略',
    'victoria': '⭐⭐⭐⭐ MC80 维多利亚大战略',
    'imperator rome': '⭐⭐⭐ MC70 罗马大战略',
    'sins of a solar empire': '⭐⭐⭐⭐ MC78 太空RTS',
    'homeworld': '⭐⭐⭐⭐ MC82 太空RTS经典',
    'endless space': '⭐⭐⭐⭐ MC76 太空4X',
    'endless legend': '⭐⭐⭐⭐ MC76 奇幻4X',
    'dungeons': '⭐⭐⭐ MC70 地下城模拟',
    'dungeon keeper': '⭐⭐⭐⭐ MC80 地下城模拟经典',
    'two point hospital': '⭐⭐⭐⭐ MC80 幽默医院模拟',
    'two point campus': '⭐⭐⭐⭐ MC78 幽默大学模拟',
    'house flipper': '⭐⭐⭐⭐ MC72 装修模拟',
    'powerwash simulator': '⭐⭐⭐⭐ MC73 清洗解压模拟',
    'car mechanic simulator': '⭐⭐⭐⭐ MC75 修车模拟',
    'farming simulator': '⭐⭐⭐⭐ MC73 种田模拟',
    'bus simulator': '⭐⭐⭐ MC68 公交模拟',
    'train simulator': '⭐⭐⭐ MC65 火车模拟',
    'euro truck simulator': '⭐⭐⭐⭐ MC75 卡车模拟',
    'american truck simulator': '⭐⭐⭐⭐ MC74 美卡模拟',
    'flight simulator': '⭐⭐⭐⭐ MC79 飞行模拟',
    'dirt rally': '⭐⭐⭐⭐ MC83 拉力赛车',
    'dirt': '⭐⭐⭐⭐ MC80 越野赛车',
    'f1': '⭐⭐⭐⭐ MC80 F1赛车',
    'grid': '⭐⭐⭐⭐ MC77 街机赛车',
    'project cars': '⭐⭐⭐⭐ MC78 模拟赛车',
    'assetto corsa': '⭐⭐⭐⭐ MC81 硬核赛车模拟',
    'forza': '⭐⭐⭐⭐⭐ MC91 地平线赛车之王',
    'need for speed': '⭐⭐⭐ MC72 街头赛车',
    'nfs heat': '⭐⭐⭐⭐ MC72 街头赛车',
    'burnout': '⭐⭐⭐⭐ MC80 火爆飙车',
    'trackmania': '⭐⭐⭐⭐ MC81 跑道赛车',
    'rocket league': '⭐⭐⭐⭐ MC85 汽车足球',
    'fallout shelter': '⭐⭐⭐⭐ MC71 末日经营',
    'sheltered': '⭐⭐⭐ MC68 末日避难所',
    'this war of mine': '⭐⭐⭐⭐ MC84 战争生存',
    'frostrunner': '⭐⭐⭐⭐ MC80 冰店模拟',
    'cocoon': '⭐⭐⭐⭐ MC88 创新解谜',
    'stray': '⭐⭐⭐⭐ MC83 猫猫冒险',
    'cult of the lamb': '⭐⭐⭐⭐ MC80 邪教经营动作',
    'vampire survivors': '⭐⭐⭐⭐⭐ MC86 幸存者类始祖',
    'broforce': '⭐⭐⭐⭐ MC76 像素动作爽游',
    'hotline miami': '⭐⭐⭐⭐⭐ MC87 暴力像素动作',
    'katana zero': '⭐⭐⭐⭐ MC82 赛博武士',
    'ghostrunner': '⭐⭐⭐⭐ MC77 高速跑酷斩杀',
    'ultrakill': '⭐⭐⭐⭐ MC88 高速复古FPS',
    'cruelty squad': '⭐⭐⭐⭐ MC75 怪异FPS',
    'neon white': '⭐⭐⭐⭐ MC78 卡牌跑酷',
    'inscryption': '⭐⭐⭐⭐⭐ MC84 黑暗卡牌解谜',
    'slay the princess': '⭐⭐⭐⭐ MC79 互动对话',
    'signalis': '⭐⭐⭐⭐ MC82 复古生存恐怖',
    'paranormasight': '⭐⭐⭐⭐ MC74 恐怖解谜ADV',
    'fatal frame': '⭐⭐⭐⭐ MC72 恐怖摄影',
    'sifu': '⭐⭐⭐⭐ MC81 功夫动作',
    'hi-fi rush': '⭐⭐⭐⭐ MC87 节奏动作',
    'chicory': '⭐⭐⭐⭐ MC87 治愈涂鸦解谜',
    'wandersong': '⭐⭐⭐⭐ MC82 歌谣冒险',
    'everhood': '⭐⭐⭐⭐ MC76 节奏RPG',
    'pizza tower': '⭐⭐⭐⭐ MC86 高速平台',
    'dave the diver': '⭐⭐⭐⭐ MC85 潜水钓鱼经营',
    'graveyard keeper': '⭐⭐⭐⭐ MC69 墓地经营',
    'core keeper': '⭐⭐⭐⭐ MC73 地牢探索',
    'starbound': '⭐⭐⭐⭐ MC80 太空版泰拉瑞亚',
    'spore': '⭐⭐⭐⭐ MC84 进化模拟经典',
    'sims': '⭐⭐⭐⭐ MC79 模拟人生',
    'rollercoaster tycoon': '⭐⭐⭐⭐ MC88 过山车经典',
    'harvestella': '⭐⭐⭐⭐ MC72 种田RPG',
    'story of seasons': '⭐⭐⭐⭐ MC75 种田经典',
    'rune factory': '⭐⭐⭐⭐ MC76 种田战斗RPG',
    'atelier': '⭐⭐⭐⭐ MC72 炼金工房RPG',
    'ys': '⭐⭐⭐⭐ MC78 伊苏动作RPG',
    'trails': '⭐⭐⭐⭐ MC78 轨迹RPG',
    'tales of': '⭐⭐⭐⭐ MC77 传说RPG',
    'star ocean': '⭐⭐⭐⭐ MC74 星海RPG',
    'valkyrie': '⭐⭐⭐⭐ MC73 北欧女神',
    'nier': '⭐⭐⭐⭐ MC88 横尾风格RPG',
    'bravely default': '⭐⭐⭐⭐ MC79 勇气默示录RPG',
    'octopath traveler': '⭐⭐⭐⭐ MC80 八方旅人RPG',
    'triangle strategy': '⭐⭐⭐⭐ MC79 三角战略RPG',
    'live a live': '⭐⭐⭐⭐ MC76 时空冒险RPG',
    'dragon quest': '⭐⭐⭐⭐ MC87 勇者斗恶龙',
    'pokémon': '⭐⭐⭐⭐ MC80 宝可梦RPG',
}

# ─── Game Details (descriptions, B站 BV IDs) ──────────────────────
# Format: '游戏名': ('简介', 'BV号或空')
GAME_DETAILS = {
    # Format: 'game_key': (简介, [评价标签], BV号)
    # Keys: English lowercase OR Chinese (without 《》)
    'elden ring': ('宫崎英高与乔治·R·R·马丁联手打造的动作RPG史诗。穿越「狭间之地」，挑战半神，揭开法环碎裂之谜。辽阔的开放世界令人惊叹，隐藏地牢与巨型Boss战充满探索欲。', ['动作RPG', 'MC96 年度最佳', 'TGA 2022年度游戏', '开放世界标杆'], ''),
    '艾尔登法环': ('宫崎英高与乔治·R·R·马丁联手打造的动作RPG史诗。穿越「狭间之地」，挑战半神，揭开法环碎裂之谜。辽阔的开放世界令人惊叹，隐藏地牢与巨型Boss战充满探索欲。', ['动作RPG', 'MC96 年度最佳', 'TGA 2022年度游戏', '开放世界标杆'], ''),
    'ghost of tsushima': ('以1274年元日战争为背景的开放世界动作冒险。武士境井仁在蒙古入侵下化身「战鬼」，守护对马岛。绝美的日本风光、爽快的刀剑对决、沉浸的和风叙事。', ['开放世界动作', 'MC87 佳作', '武士题材必玩', '玩家选择奖'], ''),
    '对马岛之魂': ('以1274年元日战争为背景的开放世界动作冒险。武士境井仁在蒙古入侵下化身「战鬼」，守护对马岛。绝美的日本风光、爽快的刀剑对决、沉浸的和风叙事。', ['开放世界动作', 'MC87 佳作', '武士题材必玩', '玩家选择奖'], ''),
    '对马岛': ('以1274年元日战争为背景的开放世界动作冒险。武士境井仁在蒙古入侵下化身「战鬼」，守护对马岛。绝美的日本风光、爽快的刀剑对决、沉浸的和风叙事。', ['开放世界动作', 'MC87 佳作', '武士题材必玩', '玩家选择奖'], ''),
    'resident evil 4': ('经典生存恐怖系列巅峰之作。特工里昂前往欧洲村庄营救总统女儿。完美融合动作射击与恐怖氛围，关卡设计教科书级别。重制版画质大幅提升，战斗系统更流畅。', ['动作恐怖', 'MC93 必玩神作', '系列天花板', '最佳重制'], ''),
    '生化危机4': ('经典生存恐怖系列巅峰之作。特工里昂前往欧洲村庄营救总统女儿。完美融合动作射击与恐怖氛围，关卡设计教科书级别。重制版画质大幅提升，战斗系统更流畅。', ['动作恐怖', 'MC93 必玩神作', '系列天花板', '最佳重制'], ''),
    'persona 5 royal': ('风格前卫的日式角色扮演游戏。白天是高中生，夜晚化身怪盗潜入心灵迷宫。UI设计独树一帜，剧情深刻，BGM神级。皇家版加入新角色和第三学期内容。', ['日式RPG', 'MC95 神作', '200小时+内容量', '原声封神'], ''),
    '女神异闻录5 皇家版': ('风格前卫的日式角色扮演游戏。白天是高中生，夜晚化身怪盗潜入心灵迷宫。UI设计独树一帜，剧情深刻，BGM神级。皇家版加入新角色和第三学期内容。', ['日式RPG', 'MC95 神作', '200小时+内容量', '原声封神'], ''),
    '女神异闻录5': ('风格前卫的日式角色扮演游戏。白天是高中生，夜晚化身怪盗潜入心灵迷宫。UI设计独树一帜，剧情深刻，BGM神级。皇家版加入新角色和第三学期内容。', ['日式RPG', 'MC95 神作', '200小时+内容量', '原声封神'], ''),
    'cyberpunk 2077': ('开放世界科幻RPG。在夜之城扮演雇佣兵V追寻永生。初期优化翻车，但经DLC「往日之影」与2.0大更新后彻底翻身——沉浸感爆棚的赛博朋克世界，剧情深刻，战斗爽快。', ['开放世界RPG', 'MC86 已修复', 'DLC口碑极佳', '2024年最佳翻身作'], ''),
    '赛博朋克2077': ('开放世界科幻RPG。在夜之城扮演雇佣兵V追寻永生。初期优化翻车，但经DLC「往日之影」与2.0大更新后彻底翻身——沉浸感爆棚的赛博朋克世界，剧情深刻，战斗爽快。', ['开放世界RPG', 'MC86 已修复', 'DLC口碑极佳', '2024年最佳翻身作'], ''),
    'split fiction': ('「双人成行」团队最新力作。两位女主角穿梭科幻世界，兼具创新玩法与感人剧情。每一关都有全新机制，画面震撼，2025年TGA年度游戏有力竞争者。', ['双人合作', 'MC91 年度黑马', '必玩双人游戏', '最佳合作游戏'], ''),
    '双影奇境': ('「双人成行」团队最新力作。两位女主角穿梭科幻世界，兼具创新玩法与感人剧情。每一关都有全新机制，画面震撼，2025年TGA年度游戏有力竞争者。', ['双人合作', 'MC91 年度黑马', '必玩双人游戏', '最佳合作游戏'], ''),
    'it takes two': ('专门为双人合作设计的动作冒险游戏。一对即将离婚的夫妻变成玩偶，在奇幻世界中修复感情。每一章都有完全不同的玩法机制。荣获TGA 2021年度游戏。', ['双人合作', 'MC90 神作', 'TGA 2021年度游戏', '情侣必玩'], ''),
    '双人成行': ('专门为双人合作设计的动作冒险游戏。一对即将离婚的夫妻变成玩偶，在奇幻世界中修复感情。每一章都有完全不同的玩法机制。荣获TGA 2021年度游戏。', ['双人合作', 'MC90 神作', 'TGA 2021年度游戏', '情侣必玩'], ''),
    'stellar blade': ('末世科幻动作RPG。战士夏娃在末世上与奈提巴战斗，夺回家园。战斗系统流畅华丽，女主角设计出众，BOSS战魄力十足。索尼独占品质之作。', ['动作RPG', 'MC81 佳作', '战斗爽快', '配乐出色'], ''),
    '剑星': ('末世科幻动作RPG。战士夏娃在末世上与奈提巴战斗，夺回家园。战斗系统流畅华丽，女主角设计出众，BOSS战魄力十足。索尼独占品质之作。', ['动作RPG', 'MC81 佳作', '战斗爽快', '配乐出色'], ''),
    'balatro': ('扑克牌Roguelike的独立神作。构建强力牌组挑战关底，数学策略与运气完美结合。一局接一局根本停不下来。2024年独立游戏最强口碑之一。', ['肉鸽/卡牌', 'MC90 独立神作', '上瘾警告', '性价比之王'], ''),
    'black myth wukong': ('国产动作游戏里程碑。扮演「天命人」在东方奇幻世界探索，体验西游故事的全新演绎。画面表现力惊艳，Boss战设计出色，战斗系统扎实。全球销量破千万。', ['动作RPG', 'MC81 国产之光', '画面顶级', '中文文化输出'], ''),
    '黑神话': ('国产动作游戏里程碑。扮演「天命人」在东方奇幻世界探索，体验西游故事的全新演绎。画面表现力惊艳，Boss战设计出色，战斗系统扎实。全球销量破千万。', ['动作RPG', 'MC81 国产之光', '画面顶级', '中文文化输出'], ''),
    '黑神话悟空': ('国产动作游戏里程碑。扮演「天命人」在东方奇幻世界探索，体验西游故事的全新演绎。画面表现力惊艳，Boss战设计出色，战斗系统扎实。全球销量破千万。', ['动作RPG', 'MC81 国产之光', '画面顶级', '中文文化输出'], ''),
    'the witcher': ('开放世界RPG的标杆之作。猎魔人杰洛特穿越战乱大陆寻找养女希里。分支剧情深刻影响结局、人物塑造入木三分、「血与酒」DLC被誉为最佳DLC之一。', ['开放世界RPG', 'MC93 神作', '剧情天花板', 'TGA 2015年度游戏'], ''),
    'witcher': ('开放世界RPG的标杆之作。猎魔人杰洛特穿越战乱大陆寻找养女希里。分支剧情深刻影响结局、人物塑造入木三分、「血与酒」DLC被誉为最佳DLC之一。', ['开放世界RPG', 'MC93 神作', '剧情天花板', 'TGA 2015年度游戏'], ''),
    'monster hunter': ('共斗动作RPG的标杆。与好友组队狩猎巨型怪物，剥取材料打造更强装备。14种武器各有深度，每场战斗都是技术与策略的博弈。千小时内容量。', ['共斗动作', 'MC90 系列巅峰', '多人必玩', '千小时内容'], ''),
    'hades': ('Roguelike动作游戏天花板。冥王之子扎格柔斯试图逃离冥界。每一次死亡都是成长的契机，人物关系发展推动故事。战斗爽快、美术惊艳、叙事手法创新。', ['肉鸽动作', 'MC93 神作', 'TGA最佳动作', '2020年度游戏提名'], ''),
    'hades ii': ('备受期待的续作。扮演冥王之女墨利诺厄，探索全新希腊神话世界。保留前作精华的同时带来更丰富的战斗系统、法术体系和故事深度。', ['肉鸽动作', 'MC86 佳作', 'EA持续更新中', '超越前作潜力'], ''),
    'dynasty warriors': ('「一骑当千」的爽快动作系列。三国武将横扫千军。真·三国无双 起源是系列革新之作，战斗系统大幅进化，战场氛围更真实。', ['动作割草', 'MC80 系列革新', '爽快解压', '起源口碑回升'], ''),
    '真三國無雙起源': ('「一骑当千」的爽快动作系列。三国武将横扫千军。真·三国无双 起源是系列革新之作，战斗系统大幅进化，战场氛围更真实。', ['动作割草', 'MC80 系列革新', '爽快解压', '起源口碑回升'], ''),
    'forza horizon': ('开放世界赛车游戏标杆。在广阔的风景中自由驰骋，参与各类赛事。画面精美、手感出色、车辆海量。地平线嘉年华氛围让人放松。', ['赛车竞速', 'MC92 最佳赛车', '开放世界赛车', '系列常青树'], ''),
    'tmnt': ('忍者神龟再度集结！在纽约街头与施莱德等反派战斗。支持多人合作，经典动画画风，怀旧感满满。适合与朋友一起玩。', ['动作清版', 'MC75 中等', '多人合作', '怀旧情怀'], ''),
    '忍者神龟': ('忍者神龟再度集结！在纽约街头与施莱德等反派战斗。支持多人合作，经典动画画风，怀旧感满满。适合与朋友一起玩。', ['动作清版', 'MC75 中等', '多人合作', '怀旧情怀'], ''),
    'gran turismo 7': ('索尼第一方赛车模拟巅峰。海量真实车型和赛道，逼真驾驶体验与出色画面。GT系列25周年集大成之作，从新车手到老司机都能找到乐趣。', ['赛车模拟', 'MC87 最佳竞速', '真实驾驶体验', '系列25周年'], ''),
    '跑车浪漫旅7': ('索尼第一方赛车模拟巅峰。海量真实车型和赛道，逼真驾驶体验与出色画面。GT系列25周年集大成之作，从新车手到老司机都能找到乐趣。', ['赛车模拟', 'MC87 最佳竞速', '真实驾驶体验', '系列25周年'], ''),
    '巫师3': ('开放世界RPG的标杆之作。猎魔人杰洛特穿越战乱大陆寻找养女希里。分支剧情深刻影响结局、人物塑造入木三分、「血与酒」DLC被誉为最佳DLC之一。', ['开放世界RPG', 'MC93 神作', '剧情天花板', 'TGA 2015年度游戏'], ''),
    '侠盗猎车手': ('开放世界犯罪题材的标杆之作。自由探索洛圣都，体验多主角叙事。在线模式GTA Online更是经久不衰。', ['开放世界', 'MC97 神作', '在线模式常青', '开放世界之王'], ''),
    '天际': ('史诗级开放世界RPG。上古卷轴5定义了西方RPG的标准。自由探索天际省，数百小时内容量。Mod社区极其活跃。', ['开放世界RPG', 'MC96 经典', 'Mod无限可能', 'RPG里程碑'], ''),
}
def game_detail(name):
    n = name.lower().strip()
    n = n.replace('《', '').replace('》', '').replace(' ', '').replace('-', '').replace(':', '')
    n = n.replace('·', '').replace('・', '').replace('/', '').replace('　', '')
    n = n.replace('跑車', '跑车').replace('劍星', '剑星').replace('無雙', '无双')
    n = n.replace('異聞錄', '异闻录').replace('雙影', '双影').replace('成行', '成行')
    for key, (desc, tags, bvid) in GAME_DETAILS.items():
        k = key.lower().strip().replace(' ', '').replace('-', '').replace(':', '')
        k = k.replace('·', '').replace('・', '').replace('/', '')
        if k in n or n in k:
            return desc, tags, bvid
    return '', [], ''

def rating_text(name):
    n = name.lower().strip()
    for key, text in RATINGS.items():
        if key in n or n in key:
            return text
    return ''

def clean_name(name):
    name = re.sub(r'\s*\(.*?\)', '', name)
    name = re.sub(r'\s*(PS4|PS5|PS4 & PS5)\s*', '', name)
    name = re.sub(r'\s*/\s*PS5', '', name)
    name = html_mod.unescape(name)
    name = re.sub(r'\s+', ' ', name).strip()
    name = name.replace('《', '').replace('》', '')
    name = re.sub(r'\s*/\s*$', '', name)
    name = re.sub(r'\s+', ' ', name).strip()
    name = re.sub(r'&', '', name)
    name = re.sub(r'\s+', ' ', name).strip()
    return name

def short_name(name):
    n = clean_name(name)
    n = re.sub(r'与.*', '', n)
    n = re.sub(r'\s+With\s+.*', '', n, flags=re.I)
    n = re.sub(r'\s*25周年.*', '', n)
    n = re.sub(r'\s*導演.*', '', n)
    n = re.sub(r'\s*數位.*', '', n)
    n = re.sub(r'\s*紀念.*', '', n)
    n = re.sub(r'\s*(Deluxe|Complete|Premium|Ultimate)\s*', '', n)
    n = n.replace('Gold Edition', 'GE')
    n = n.replace('Edition', '')
    n = re.sub(r'\s*(完全版|黄金版|豪華版|终极版|导演剪辑版|導演剪輯版)\s*', '', n)
    n = re.sub(r'\s*25th.*', '', n)
    n = n.strip()
    return n

def price_num(p):
    m = re.search(r'[\d.]+', str(p).replace(',', ''))
    return float(m.group()) if m else None

def disc_pct(d):
    m = re.search(r'-?(\d+)%', str(d))
    return int(m.group(1)) if m else 0

# ─── Translation dictionary ─────────────────────────────────────────
GAME_TRANSLATIONS = {
    'Sayonara Wild Hearts': '再见狂野之心',
    'Lorelei and the Laser Eyes': '洛蕾莱与激光眼',
    'Police Simulator: Patrol Officers': '警察模拟器：巡逻警员',
    'Dinkum': '叮垦',
    'Persona 5 Royal': '女神异闻录5 皇家版',
    'Cyberpunk 2077': '赛博朋克2077',
    'Grand Theft Auto V Enhanced': '侠盗猎车手V',
    'Split Fiction': '双影奇境',
    'Resident Evil 4': '生化危机4',
    'Ghost of Tsushima': '对马岛之魂',
    'Resident Evil Remake Trilogy': '生化危机重制三部曲',
}

def translate_name(name):
    if name in GAME_TRANSLATIONS:
        return GAME_TRANSLATIONS[name]
    for eng, cn in GAME_TRANSLATIONS.items():
        if eng in name or name in eng:
            return cn
    if re.search(r'[\u4e00-\u9fff]', name):
        return name
    return None

# ─── PSNine (P9) ────────────────────────────────────────────────────
P9_CATEGORIES = {
    '入库游戏': '入库/会免',
    '新史低': '史低',
    '二档': '入库/会免',
    '三档': '入库/会免',
    'PLUS': '入库/会免',
    'plus': '入库/会免',
    '白金攻略': '攻略',
    '白金': '攻略',
}

def fetch_p9_topic_thumbnail(url):
    """Fetch the first relevant game image from a P9 topic page."""
    html = fetch(url)
    if not html: return ''
    soup = BeautifulSoup(html, 'lxml')
    candidates = []
    for img in soup.find_all('img'):
        src = (img.get('src', '') or '').strip()
        if not src or '.gif' in src.lower():
            continue
        # Skip avatars, icons, emoji
        if any(k in src.lower() for k in ['avatar', 'face/', 'emotion', 'icon', 'upload/face', 'playstation.net/avatar']):
            continue
        # Prefer PlayStation trophy/game images and external image hosts
        if any(k in src for k in ['psnobj.prod.dl.playstation', 'image.api.playstation', 'psn-rsc.', 'ax1x.com', 's2.loli.net', 'imgur.com']):
            candidates.append(src)
    return candidates[0] if candidates else ''

def extract_p9_items(soup):
    """Extract post items from PSNine homepage."""
    items = []
    for div in soup.find_all('div', class_='ml64'):
        title_div = div.find('div', class_='title')
        if not title_div:
            title_div = div  # some items have title directly in ml64
        
        title_text = None
        link = None
        a_tag = title_div.find('a') if title_div != div else None
        if a_tag:
            title_text = a_tag.get_text(strip=True)
            link = a_tag.get('href', '')
        else:
            # Check if ml64 itself contains the structure
            for a in div.find_all('a'):
                t = a.get_text(strip=True)
                if len(t) > 10:
                    title_text = t
                    link = a.get('href', '')
                    break
        
        if not title_text or len(title_text) < 10:
            continue
        
        # Find meta for author/time/tags
        meta_div = div.find_next_sibling('div', class_='meta')
        if not meta_div:
            meta_div = div.find('div', class_='meta')
        
        author = ''
        time_text = ''
        tags = []
        if meta_div:
            meta_text = meta_div.get_text(strip=True)
            # Use Python regex to extract username and time from messy P9 meta
            # Format: "username<time>   region<tags>"
            if meta_text:
                # Find the time portion: digits followed by time unit words
                tm = re.search(r'(\d+[天小分时][前内]?|前天|昨天|今天|(\d{2}[-/]\d{2}))', meta_text)
                if tm:
                    time_start = tm.start()
                    # Author is everything before the time pattern
                    raw_author = meta_text[:time_start].strip()
                    # Take only alphanumeric chars for author
                    author = re.match(r'^([A-Za-z0-9_-]+)', raw_author)
                    author = author.group(1) if author else raw_author[:15]
                    # Time = the match
                    time_text = tm.group(1)
                    # Check for clock time after
                    clock = re.search(r'(\d{2}:\d{2})', meta_text[tm.end():])
                    if clock:
                        time_text += ' ' + clock.group(1)
        
        items.append({
            'title': title_text,
            'link': link,
            'author': author,
            'time': time_text,
            'tags': tags,
            'img': ''
        })
    
    # Fetch thumbnails for topic posts
    topic_links = [it['link'] for it in items[:14] if it['link'] and re.match(r'https://www\.psnine\.com/topic/\d+', it['link'])]
    for tl in topic_links:
        img = fetch_p9_topic_thumbnail(tl)
        if img:
            for it in items:
                if it['link'] == tl:
                    it['img'] = img
                    break
    
    return items

def parse_psnine():
    """Get PSNine latest posts."""
    html = fetch("https://www.psnine.com/")
    if not html:
        return {'gamelist': [], 'new_lows': [], 'guides': []}
    
    soup = BeautifulSoup(html, 'lxml')
    all_items = extract_p9_items(soup)
    
    result = {'gamelist': [], 'new_lows': [], 'guides': []}
    
    for item in all_items:
        title = item['title']
        tags_str = ' '.join(item['tags']).lower()
        
        # Categorize
        is_gamelist = any(k in tags_str or k in title for k in ['gamelist', '入库', '二三档', '二档', '三档', 'plus', '会员'])
        is_new_low = any(k in title or k in tags_str for k in ['新史低', '史低', 'new low', 'newlow'])
        is_guide = any(k in tags_str or k in title for k in ['guide', '白金攻略', '攻略', '指南'])
        
        if is_new_low:
            result['new_lows'].append(item)
        elif is_gamelist and ('入库' in title or '二档' in title or '三档' in title or 'PLUS' in title or 'PLUS' in title or '会免' in title):
            result['gamelist'].append(item)
        elif is_guide and ('白金' in title or '攻略' in title or '指南' in title):
            result['guides'].append(item)
    
    return result

# ─── Data sources ───────────────────────────────────────────────────
def parse_psn():
    # 多页面抓取 PS5 + PS4 折扣
    urls = [
        "https://store.playstation.com/zh-hant-hk/pages/deals",
        "https://store.playstation.com/zh-hant-hk/pages/browse/1?category=all_ps4_discounts&sort=discount_rate&page=1",
        "https://store.playstation.com/zh-hant-hk/pages/browse/1?category=all_ps5_discounts&sort=discount_rate&page=1",
    ]
    games = []
    for url in urls:
        html = fetch(url)
        if not html: continue
        soup = BeautifulSoup(html, 'lxml')
        for tile in soup.find_all('div', class_=lambda c: c and 'psw-product-tile' in c):
            nt = tile.find('span', {'data-qa': re.compile(r'product-name')})
            if not nt: continue
            name = nt.get_text(strip=True)
            if not name or len(name) > 80: continue
            tt = tile.find('span', {'data-qa': re.compile(r'product-type')})
            if tt and tt.get_text(strip=True) in ['物品', '武器', '服裝', '追加內容', '章節']:
                continue
            dt = tile.find('span', {'data-qa': re.compile(r'discount-badge')})
            disc = dt.get_text(strip=True) if dt else ''
            pt = tile.find('span', {'data-qa': re.compile(r'price#display-price')})
            price = pt.get_text(strip=True) if pt else ''
            st = tile.find('s', {'data-qa': re.compile(r'price#price-strikethrough')})
            orig = st.get_text(strip=True) if st else ''
            img = tile.find('img')
            img_url = img.get('src', '') if img else ''
            if img_url:
                img_url = img_url.split('?')[0] + '?w=240'
            games.append({'name': name.strip(), 'price': price.strip(), 'discount': disc.strip(), 'original_price': orig.strip(), 'img': img_url})
    return games

def parse_steam():
    data = fetch_json("https://store.steampowered.com/api/featuredcategories?cc=cn&l=zh")
    if not data: return []
    games = []
    specials = data.get('specials', {}).get('items', [])
    if isinstance(specials, list):
        for item in specials[:100]:
            g = parse_steam_item(item)
            if g: games.append(g)
    return games

def parse_steam_item(item):
    if not isinstance(item, dict): return None
    name = item.get('name', '')
    if not name: return None
    fp, op = item.get('final_price', 0), item.get('original_price', 0)
    dp = item.get('discount_percent', 0)
    return {
        'name': name.strip(),
        'price': f'¥{fp/100:.0f}' if fp else '',
        'discount': f'-{dp}%' if dp else '',
        'original_price': f'¥{op/100:.0f}' if op else '',
        'img': item.get('header_image', '')
    }

def parse_switch():
    """Get Switch deals from Nintendo Japan eShop."""
    url = "https://search.nintendo.jp/nintendo_soft/search.json?q=&opt_sshow=1&limit=100"
    raw = fetch(url)
    if not raw: return []
    try:
        data = json.loads(raw)
    except:
        return []
    games = []
    for item in data.get('result', {}).get('items', []):
        if item.get('sctg', '') != 'dl_soft':
            continue
        if item.get('sale_flg', '0') != '1':
            continue
        drates = item.get('drate', ['0'])
        drate = float(drates[0]) if isinstance(drates, list) else 0
        if drate <= 0:
            continue
        title = item.get('title', '')
        price = item.get('price', 0)
        sprice = item.get('sprice', None)
        current_price = sprice if sprice and sprice != price else item.get('dprice', price)
        if not title:
            continue
        lang = item.get('lang', [])
        has_cn = any('zh' in l for l in lang) if isinstance(lang, list) else False
        # Get image - Nintendo API has 'image' field
        img_url = item.get('image', '') or item.get('screenshot', '') or ''
        if isinstance(img_url, list):
            img_url = img_url[0] if img_url else ''
        games.append({
            'name': title.strip(),
            'price': f'¥{current_price:,.0f}' if current_price else '',
            'discount': f'-{drate:.0f}%' if drate else '',
            'original_price': f'¥{price:,.0f}' if price else '',
            'has_cn': has_cn,
            'img': img_url
        })
    return games

# ─── HTML generation ───────────────────────────────────────────────
def pre_search_mods():
    """Pre-cache mod search results using DuckDuckGo."""
    # Pairs of (keyword, game_slug) to search
    kw_pairs = [
        ("画质", "cyberpunk2077"),
        ("武器", "eldenring"),
        ("人物外观", "skyrimspecialedition"),
        ("UI", "baldursgate3"),
        ("地图", "skyrimspecialedition"),
        ("战斗", "eldenring"),
        ("联机", "stardewvalley"),
    ]
    results_cache = {}
    for kw, game in kw_pairs:
        q = f"+mod+\"{kw}\"+site:nexusmods.com/\"{game}\""
        url = f"https://lite.duckduckgo.com/lite/?q={urllib.parse.quote(q)}"
        html = fetch(url, timeout=10)
        if not html:
            results_cache[f"{kw}_{game}"] = []
            continue
        soup = BeautifulSoup(html, 'lxml')
        items = []
        for a in soup.find_all('a', class_='result-link'):
            href = a.get('href', '')
            text = a.get_text(strip=True)
            if not text or not href: continue
            real_url = href
            if 'uddg=' in href:
                try:
                    real_url = urllib.parse.unquote(href.split('uddg=')[1].split('&')[0])
                except:
                    pass
            if 'nexusmods.com' not in real_url:
                continue
            row = a.find_parent('tr')
            snippet = ''
            if row:
                tds = row.find_all('td')
                if len(tds) >= 3:
                    snippet = tds[2].get_text(strip=True)[:100]
            items.append({'title': text, 'url': real_url, 'snippet': snippet})
            if len(items) >= 6:
                break
        results_cache[f"{kw}_{game}"] = items
    return results_cache

def generate_html():
    ts = time.strftime('%Y-%m-%d %H:%M', time.localtime())
    psn = parse_psn()
    steam = parse_steam()
    switch = parse_switch()
    psnine = parse_psnine()

    # Build image lookup from all game data
    game_images = {}
    for game_list in [psn, steam, switch]:
        for g in game_list:
            if g.get('img') and g.get('name'):
                key = clean_name(g['name']).lower()
                game_images[key] = g['img']

    def score_items(games, cn_bonus=False):
        seen, result = set(), []
        for g in games:
            n = clean_name(g['name'])
            if not n or n in seen: continue
            if not disc_pct(g['discount']): continue  # 不打折的过滤掉
            seen.add(n)
            r = rating_text(n)
            d = disc_pct(g['discount']) + (5 if cn_bonus and g.get('has_cn', False) else 0)
            p = price_num(g['price'])
            result.append((d, n, g, r, d, p))
        result.sort(key=lambda x: -x[0])
        return result

    psn_items = score_items(psn)
    steam_items = score_items(steam)
    switch_items = score_items(switch, cn_bonus=True)

    all_items = [(s, n, g, r, d, p, 'PSN') for s, n, g, r, d, p in psn_items] + \
                [(s, n, g, r, d, p, 'Steam') for s, n, g, r, d, p in steam_items] + \
                [(s, n, g, r, d, p, 'Switch') for s, n, g, r, d, p in switch_items]
    all_items.sort(key=lambda x: -x[0])

    def trans_short(n):
        t = translate_name(n)
        return short_name(t if t else n)

    def platform_icon(plat):
        return {'PSN': '🔵', 'Steam': '🟢', 'Switch': '🟡'}.get(plat, '🎮')

    # Build more flexible image lookup from all platform data
    img_lookup = {}
    for g in psn + steam + switch:
        if g.get('img'):
            name = clean_name(g.get('name', '')).lower()
            img_lookup[name] = g['img']
            # Also map Chinese translated names
            cn = translate_name(g['name'])
            if cn:
                img_lookup[cn.lower().replace('《','').replace('》','')] = g['img']

    def find_p9_cover(title):
        """Extract game name from P9 post title and find cover image."""
        title_lower = title.lower()
        # Direct match in lookup
        for key, img in img_lookup.items():
            if key in title_lower or title_lower in key:
                return img
        # Try to extract game name from common patterns
        # "怪物猎人：世界冰原大小金..." → check 怪物猎人
        for key in sorted(img_lookup.keys(), key=len, reverse=True):
            if key in title_lower:
                return img_lookup[key]
        return ''

    cards = ""

    # ---- Pre-cached Mod search results ----
    mod_cache = pre_search_mods()
    cached_mod_results = '<div id="mod-cache-results" style="display:block">'
    for key, items in mod_cache.items():
        parts = key.rsplit('_', 1)
        kw, game = parts[0], parts[1] if len(parts) > 1 else ''
        slug = f'rc-{kw}-{game}'
        display_kw = {"画质": "🎨 画质 Mod", "武器": "⚔️ 武器 Mod", "人物外观": "👤 外观 Mod", "UI": "🖥️ UI Mod", "地图": "🗺️ 地图 Mod", "战斗": "⚡ 战斗 Mod", "联机": "👥 联机 Mod"}.get(kw, f"🔍 {kw}")
        game_name = {"cyberpunk2077": "Cyberpunk 2077", "skyrimspecialedition": "Skyrim SE", "baldursgate3": "Baldur's Gate 3", "eldenring": "Elden Ring", "stardewvalley": "Stardew Valley", "blackmythwukong": "黑神话:悟空"}.get(game, game)
        cached_mod_results += f'<div id="{slug}" class="mod-cache-group" style="display:none"><section class="platform"><h2>{display_kw} — {game_name}</h2><div class="game-list">'
        if items:
            for it in items:
                title = it['title'][:50]
                snippet = it.get('snippet', '')[:100]
                snippet_html = f'<div class="card-rating" style="margin-top:2px;font-size:11px;color:#666">{snippet}</div>' if snippet else ''
                cached_mod_results += f'''
            <a href="{it["url"]}" target="_blank" rel="noopener" class="game-card" style="text-decoration:none;color:inherit">
                <div class="game-card-inner">
                    <div class="card-right">
                        <div class="card-header">
                            <span class="game-name" style="font-size:13px">{title}</span>
                            <span class="discount-badge disc-low" style="font-size:10px">🧩 Nexus</span>
                        </div>
                        {snippet_html}
                    </div>
                </div>
            </a>'''
        else:
            cached_mod_results += '<div style="text-align:center;padding:16px;color:#666">暂无缓存结果</div>'
        cached_mod_results += '</div></section></div>'
    cached_mod_results += '</div>'
    
    # ---- Mod 精选列表 ----
    hot_mods = [
        {"name": "Skyrim UE / 天际重制", "game": "The Elder Scrolls V: Skyrim SE", "desc": "最新 Mod 整合包，包含材质、光照、战斗大修", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/489830/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/skyrimspecialedition"},
        {"name": "Cyberpunk 2077 画质大修", "game": "Cyberpunk 2077", "desc": "光线追踪增强、城市细节重制、天气系统", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1091500/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/cyberpunk2077"},
        {"name": "Baldur's Gate 3 Mod 合集", "game": "Baldur's Gate 3", "desc": "新增职业、法术、外观、UI增强等热门Mod", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1245620/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/baldursgate3"},
        {"name": "Elden Ring 无缝联机", "game": "Elden Ring", "desc": "Seamless Co-op Mod — 联机不再被入侵限制", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1245620/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/eldenring"},
        {"name": "Stardew Valley 扩展", "game": "Stardew Valley", "desc": "Stardew Valley Expanded — 新地图/角色/事件", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/stardewvalley"},
        {"name": "Minecraft 模组精选", "game": "Minecraft", "desc": "OptiFine + Create + JEI + 光影包", "img": "https://media.forgecdn.net/avatars/thumbnails/0/102/64/64/636420395584242713.png", "site": "curseforge", "link": "https://www.curseforge.com/minecraft"},
        {"name": "GTA V LSPDFR", "game": "Grand Theft Auto V", "desc": "警察模组 — 扮演警探执法", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/271590/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/gta5"},
        {"name": "塞尔达 旷野之息 Mod", "game": "The Legend of Zelda: Breath of the Wild", "desc": "60帧解锁+画质增强+性能优化 (Cemu)", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1677280/header_chinese.jpg", "site": "other", "link": "https://gamebanana.com/mods/cats/1"},
        {"name": "七日杀 Mod 整合", "game": "7 Days to Die", "desc": "Undead Legacy / Darkness Falls 大改版", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/251570/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/7daystodie"},
        {"name": "黑神话·悟空 Mod", "game": "Black Myth: Wukong", "desc": "画质提升+视角Mod+性能优化", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/367520/header.jpg", "site": "nexus", "link": "https://www.nexusmods.com/blackmythwukong"},
        {"name": "Cities: Skylines 资产包", "game": "Cities: Skylines", "desc": "真实建筑+道路模组+交通管理", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/255710/header.jpg", "site": "steam", "link": "https://steamcommunity.com/workshop/browse/?appid=255710"},
        {"name": "Factorio 大型Mod", "game": "Factorio", "desc": "Space Exploration / Krastorio 2 / AngelBob", "img": "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/427520/header.jpg", "site": "other", "link": "https://mods.factorio.com/"},
    ]

    search_games = [
        {"name": "Skyrim SE 天际重制", "appid": "489830", "steam": "1", "nexus_game": "skyrimspecialedition"},
        {"name": "Cyberpunk 2077", "appid": "1091500", "steam": "1", "nexus_game": "cyberpunk2077"},
        {"name": "Baldur's Gate 3", "appid": "1086940", "steam": "1", "nexus_game": "baldursgate3"},
        {"name": "Elden Ring 老头环", "appid": "1245620", "steam": "1", "nexus_game": "eldenring"},
        {"name": "GTA V", "appid": "271590", "steam": "1", "nexus_game": "gta5"},
        {"name": "Stardew Valley", "appid": "413150", "steam": "1", "nexus_game": "stardewvalley"},
        {"name": "黑神话·悟空", "appid": "2358720", "steam": "1", "nexus_game": "blackmythwukong"},
        {"name": "Minecraft", "appid": "", "steam": "0", "nexus_game": ""},
        {"name": "7 Days to Die", "appid": "251570", "steam": "1", "nexus_game": "7daystodie"},
        {"name": "Borderlands 3", "appid": "397540", "steam": "1", "nexus_game": "borderlands3"},
        {"name": "Factorio", "appid": "427520", "steam": "1", "nexus_game": "factorio"},
    ]

    mods_html = '<div id="tab-mods" class="tab-content" style="display:none">'
    mods_html += '<div class="sub-tab-bar p9-section-bar">'
    mods_html += '<button class="sub-tab-btn active" onclick="switchModSubTab(\'mod-hot\', this)">🔥 热门 Mod</button>'
    mods_html += '<button class="sub-tab-btn" onclick="switchModSubTab(\'mod-search\', this)">🔍 搜 Mod</button>'
    mods_html += '</div>'

    # Hot mods section
    mods_html += '<div id="mod-hot" class="mod-section" style="display:block">'
    mods_html += '<section class="platform"><h2>🔥 精选热门 Mod</h2><div class="game-list">'
    for m in hot_mods:
        site_icon = {"nexus": "Nexus", "curseforge": "CurseForge", "steam": "Steam工坊", "other": "M站"}.get(m["site"], "Mod站")
        mods_html += f'''
        <a href="{m["link"]}" target="_blank" rel="noopener" class="game-card" style="text-decoration:none;color:inherit">
            <div class="game-card-inner">
                <div class="card-left"><img src="{m["img"]}" class="game-thumb" onerror="this.parentElement.style.display=\'none\'"></div>
                <div class="card-right">
                    <div class="card-header">
                        <span class="game-name">{m["name"]}</span>
                        <span class="discount-badge disc-low">{site_icon}</span>
                    </div>
                    <div style="font-size:12px;color:#888;margin-top:4px">{m["game"]}</div>
                    <div class="card-rating">{m["desc"]}</div>
                </div>
            </div>
        </a>'''
    mods_html += '</div></section></div>'

    # Search section - 后端预缓存搜索
    mods_html += '<div id="mod-search" class="mod-section" style="display:none">'
    mods_html += '<section class="platform"><h2>🔍 搜索 PC Mod（点击跳转原站）</h2>'
    mods_html += '<div style="margin-bottom:12px">'
    mods_html += '''<div class="p9-search-box">
        <input type="text" id="mod-search-input" class="p9-search-input" placeholder="中文/英文搜 Mod…" onkeydown="if(event.key==='Enter') modSearchRedirect()">
        <button class="p9-search-btn" onclick="modSearchRedirect()">🔍 搜</button>
    </div>
    <div style="margin-bottom:8px;display:flex;gap:6px;flex-wrap:wrap">
        <button class="sub-tab-btn" onclick="modSearchRedirectKW('画质增强', 'cyberpunk2077')">🎨 画质</button>
        <button class="sub-tab-btn" onclick="modSearchRedirectKW('武器', 'cyberpunk2077')">⚔️ 武器</button>
        <button class="sub-tab-btn" onclick="modSearchRedirectKW('人物外观', 'skyrimspecialedition')">👤 外观</button>
        <button class="sub-tab-btn" onclick="modSearchRedirectKW('UI', 'skyrimspecialedition')">🖥️ UI</button>
        <button class="sub-tab-btn" onclick="modSearchRedirectKW('地图', 'eldenring')">🗺️ 地图</button>
        <button class="sub-tab-btn" onclick="modSearchRedirectKW('战斗', 'eldenring')">⚡ 战斗</button>
        <button class="sub-tab-btn" onclick="modSearchRedirectKW('联机', 'eldenring')">👥 联机</button>
    </div>
    <div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:16px">
        <button class="p9-search-btn" style="font-size:12px;padding:6px 10px" onclick="modSearchRedirectGame('cyberpunk2077')">🌆 Cyberpunk</button>
        <button class="p9-search-btn" style="font-size:12px;padding:6px 10px" onclick="modSearchRedirectGame('skyrimspecialedition')">🏔️ Skyrim</button>
        <button class="p9-search-btn" style="font-size:12px;padding:6px 10px" onclick="modSearchRedirectGame('baldursgate3')">🎲 BG3</button>
        <button class="p9-search-btn" style="font-size:12px;padding:6px 10px" onclick="modSearchRedirectGame('eldenring')">⚫ 老头环</button>
        <button class="p9-search-btn" style="font-size:12px;padding:6px 10px" onclick="modSearchRedirectGame('stardewvalley')">🌾 星露谷</button>
        <button class="p9-search-btn" style="font-size:12px;padding:6px 10px" onclick="modSearchRedirectGame('blackmythwukong')">🐵 黑神话</button>
    </div>'''
    # Pre-cached mod search results
    mods_html += cached_mod_results
    mods_html += '</div></section></div></div>'
    for label, items, icon, raw_label, section_id in [
        ("PSN 港服特惠", psn_items[:100], "🔵", "PSN", "disc-psn"),
        ("Steam 国服特惠", steam_items[:100], "🟢", "Steam", "disc-steam"),
        ("Switch 日服特惠", switch_items[:100], "🟡", "Switch", "disc-switch"),
    ]:
        if not items:
            continue
        cards += f'<div id="{section_id}" class="disc-section"><section class="platform"><h2>{icon} {label}</h2><div class="game-list">'
        for i, (score, n, g, r, d, p) in enumerate(items, 1):
            display = translate_name(n) or n
            sn = trans_short(n)
            display_name = f"《{sn}》" if re.search(r'[\u4e00-\u9fff]', sn) else sn
            price = g['price']
            disc_s = g['discount']
            dc = disc_pct(disc_s)
            rating = r or ""
            disc_cls = "disc-high" if dc >= 50 else ("disc-mid" if dc >= 30 else "disc-low")
            cn_tag = ' <span class="cn-tag">🇨🇳 中文</span>' if raw_label == "Switch" and g.get('has_cn', False) else ""
            card_img = f'<img src="{g["img"]}" class="game-thumb" onerror="this.parentElement.style.display=\'none\'">' if g.get('img') else ''
            cn_tag = ' <span class="cn-tag">🇨🇳 中文</span>' if raw_label == "Switch" and g.get('has_cn', False) else ""
            desc, tags, bvid = game_detail(display_name)
            desc_attr = f'data-desc="{html_mod.escape(desc)}"' if desc else ''
            tags_attr = f'data-tags="{html_mod.escape("|".join(tags))}"' if tags else ''
            bvid_attr = f'data-bvid="{bvid}"' if bvid else ''
            cards += f'''
            <div class="game-card" onclick="showGameModal(this)" style="cursor:pointer"{desc_attr} {tags_attr} {bvid_attr}>
                <div class="game-card-inner">
                    <div class="card-left">{card_img}</div>
                    <div class="card-right">
                        <div class="card-header">
                            <span class="game-name">{display_name}</span>
                            <span class="discount-badge {disc_cls}">{disc_s}</span>
                        </div>
                        <div class="card-price">
                            <span class="current-price">{price}</span>{cn_tag}
                        </div>
                        <div class="card-rating">{rating}</div>
                    </div>
                </div>
            </div>'''
        cards += '</section></div>'

    top5 = '<div id="disc-top5" class="disc-section"><section class="platform"><h2>🔥 综合推荐 TOP</h2><div class="game-list">'
    used = set()
    count = 0
    for s, n, g, r, d, p, plat in all_items:
        if count >= 20: break
        if n in used: continue
        used.add(n)
        display = trans_short(n)
        icon = platform_icon(plat)
        price = g['price']
        disc_s = g['discount']
        disc_cls = "disc-high" if d >= 50 else ("disc-mid" if d >= 30 else "disc-low")
        rating = (r[:15] if r else "") or ""
        cn_tag = ' <span class="cn-tag">🇨🇳 中文</span>' if plat == "Switch" and g.get('has_cn', False) else ""
        card_img = f'<img src="{g["img"]}" class="game-thumb" onerror="this.parentElement.style.display=\'none\'">' if g.get('img') else ''
        desc, tags, bvid = game_detail(display)
        desc_attr = f'data-desc="{html_mod.escape(desc)}"' if desc else ''
        bvid_attr = f'data-bvid="{bvid}"' if bvid else ''
        top5 += f'''<div class="game-card" onclick="showGameModal(this)" style="cursor:pointer"{desc_attr} {tags_attr} {bvid_attr}>
                <div class="game-card-inner">
                    <div class="card-left">{card_img}</div>
                    <div class="card-right">
                        <div class="card-header">
                            <span class="game-name">{display}</span>
                            <span class="discount-badge {disc_cls}">{disc_s}</span>
                        </div>
                        <div class="card-price">
                            <span class="current-price">{price}</span>{cn_tag}
                        </div>
                        <div class="card-rating">{rating}</div>
                    </div>
                </div>
            </div>'''
        count += 1
    top5 += "</div></section></div>"

    # ─── PSNine community ───────────────────────────────────────────
    p9_sections = ""

    if psnine.get('gamelist'):
        p9_sections += '<section id="p9-game" class="platform p9-section"><h2>📦 P9 入库/会免信息</h2><div class="p9-list">'
        for item in psnine['gamelist'][:4]:
            link = item['link']
            if link and not link.startswith('http'):
                link = 'https://www.psnine.com' + link
            title = item['title'][:48]
            img_src = item.get("img", "") or find_p9_cover(item["title"])
            p9_img_html = f'<div class="p9-thumb"><img src="{img_src}" class="p9-thumb-img" onerror="this.parentElement.style.display=\'none\'"></div>' if img_src else ''
            fallback = '<div class="p9-thumb p9-thumb-game">📦</div>' if not img_src else ''
            p9_sections += f'''
            <a href="{link}" class="p9-item" target="_blank" rel="noopener">
                <div class="p9-item-inner">{p9_img_html or fallback}
                <div class="p9-item-texts">
                <span class="p9-title">{title}</span>
                <span class="p9-meta">✎ {item['author']} · {item['time']}</span>
                </div></div>
            </a>'''
        p9_sections += '</div></section>'

    if psnine.get('new_lows'):
        p9_sections += '<section id="p9-low" class="platform p9-section"><h2>💸 P9 新史低汇总</h2><div class="p9-list">'
        for item in psnine['new_lows'][:4]:
            link = item['link']
            if link and not link.startswith('http'):
                link = 'https://www.psnine.com' + link
            title = item['title'][:48]
            img_src = item.get("img", "") or find_p9_cover(item["title"])
            p9_img_html = f'<div class="p9-thumb"><img src="{img_src}" class="p9-thumb-img" onerror="this.parentElement.style.display=\'none\'"></div>' if img_src else ''
            fallback = '<div class="p9-thumb p9-thumb-low">💸</div>' if not img_src else ''
            p9_sections += f'''
            <a href="{link}" class="p9-item" target="_blank" rel="noopener">
                <div class="p9-item-inner">{p9_img_html or fallback}
                <div class="p9-item-texts">
                <span class="p9-title">{title}</span>
                <span class="p9-meta">✎ {item['author']} · {item['time']}</span>
                </div></div>
            </a>'''
        p9_sections += '</div></section>'

    if psnine.get('guides'):
        p9_sections += '<section id="p9-guide" class="platform p9-section"><h2>🏆 P9 热门白金攻略</h2><div class="p9-list">'
        for item in psnine['guides'][:6]:
            link = item['link']
            if link and not link.startswith('http'):
                link = 'https://www.psnine.com' + link
            title = item['title'][:48]
            img_src = item.get("img", "") or find_p9_cover(item["title"])
            p9_img_html = f'<div class="p9-thumb"><img src="{img_src}" class="p9-thumb-img" onerror="this.parentElement.style.display=\'none\'"></div>' if img_src else ''
            fallback = '<div class="p9-thumb p9-thumb-guide">🏆</div>' if not img_src else ''
            p9_sections += f'''
            <a href="{link}" class="p9-item" target="_blank" rel="noopener">
                <div class="p9-item-inner">{p9_img_html or fallback}
                <div class="p9-item-texts">
                <span class="p9-title">{title}</span>
                <span class="p9-meta">✎ {item['author']} · {item['time']}</span>
                </div></div>
            </a>'''
        p9_sections += '</div></section>'

    # Build tab content for each section

    html = f'''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>Yann 的小站</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: linear-gradient(160deg, #0f0f1a 0%, #161630 50%, #0f0f1a 100%); color: #e8e8f0; padding: 16px; max-width: 800px; margin: 0 auto; transition: background 0.8s ease; position: relative; }}
body::before {{ content: ''; position: fixed; inset: -10px; z-index: -1; background-size: cover; background-position: center; opacity: 0.08; transition: opacity 0.8s ease; pointer-events: none; animation: bgBreathe 20s ease-in-out infinite alternate; }}
body.tab-trophy::before {{ background-image: url('https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1086940/header.jpg'); }}
body.tab-discounts::before {{ background-image: url('https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/271590/header.jpg'); }}
body.tab-psnine::before {{ background-image: url('https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2358720/header.jpg'); }}
body.tab-mods::before {{ background-image: url('https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1085660/header.jpg'); }}
@keyframes bgBreathe {{
  0% {{ transform: scale(1) translate(0, 0); }}
  50% {{ transform: scale(1.05) translate(-1%, -1%); }}
  100% {{ transform: scale(1) translate(0, 0); }}
}}
.tab-accent {{ height: 3px; border-radius: 3px; margin-bottom: 12px; position: relative; overflow: hidden; transition: background 0.5s ease; }}
.tab-accent.trophy {{ background: linear-gradient(90deg, #a855f7, #7c3aed); }}
.tab-accent.discounts {{ background: linear-gradient(90deg, #34d399, #059669); }}
.tab-accent.psnine {{ background: linear-gradient(90deg, #5dade2, #3b82f6); }}
.tab-accent.mods {{ background: linear-gradient(90deg, #f97316, #ea580c); }}
.tab-accent::after {{ content: ''; position: absolute; top: 0; left: -100%; width: 100%; height: 100%; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent); animation: shimmer 3s ease-in-out infinite; }}
@keyframes shimmer {{
  0% {{ left: -100%; }}
  50% {{ left: 100%; }}
  100% {{ left: 100%; }}
}}
/* 粒子背景 */
.particles {{ position: fixed; inset: 0; z-index: -1; overflow: hidden; pointer-events: none; }}
.particle {{ position: absolute; pointer-events: none; animation: particleFloat linear infinite; font-size: 14px; }}
.particle.text-particle {{ animation: particleFloat linear infinite, textGlow 3s ease-in-out infinite alternate; }}
@keyframes particleFloat {{
  0% {{ transform: translateY(-5vh) rotate(0deg); opacity: 0; }}
  20% {{ opacity: 0.7; transform: translateY(10vh) rotate(60deg); }}
  80% {{ opacity: 0.5; transform: translateY(80vh) rotate(300deg); }}
  100% {{ transform: translateY(105vh) rotate(360deg); opacity: 0; }}
}}
@keyframes textGlow {{
  0% {{ color: #a855f7; text-shadow: 0 0 4px rgba(168,85,247,0.5); }}
  33% {{ color: #f97316; text-shadow: 0 0 4px rgba(249,115,22,0.5); }}
  66% {{ color: #22d3ee; text-shadow: 0 0 4px rgba(34,211,238,0.5); }}
  100% {{ color: #a855f7; text-shadow: 0 0 4px rgba(168,85,247,0.5); }}
}}
.tab-content-fade {{ animation: tabFlipIn 0.3s cubic-bezier(0.05, 0.7, 0.1, 1) forwards; }}
@keyframes tabFlipIn {{
  0% {{ opacity: 0.3; transform: translateY(-8px); }}
  100% {{ opacity: 1; transform: translateY(0); }}
}}
.tab-bar {{ display: flex; gap: 4px; margin-bottom: 0; position: sticky; top: 0; background: #0f0f1a; padding: 6px 0; z-index: 10; }}
.tab-btn {{ flex: 1; padding: 6px 0; border: none; border-radius: 6px; font-size: 12px; font-weight: 600; cursor: pointer; background: transparent; color: #666; transition: all 0.2s; }}
.tab-btn.active {{ background: #1a1a2e; color: #e8e8f0; }}
.tab-btn:active {{ background: #2a2a3e; }}
.sub-tab-bar {{ display: flex; gap: 4px; margin-bottom: 12px; }}
.sub-tab-btn {{ padding: 5px 14px; border: none; border-radius: 5px; font-size: 12px; font-weight: 500; cursor: pointer; background: transparent; color: #555; transition: all 0.2s; }}
.sub-tab-btn.active {{ background: #1f1f32; color: #e8e8f0; }} 
h1 {{ text-align: center; font-size: 20px; padding: 8px 0; }}
.subtitle {{ text-align: center; color: #888; font-size: 13px; margin-bottom: 16px; }}
.last-update {{ text-align: center; color: #555; font-size: 11px; margin-bottom: 12px; }}
/* Discounts */
.platform {{ margin-bottom: 24px; }}
.platform h2 {{ font-size: 18px; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1px solid #2a2a3e; }}
.game-list {{ display: flex; flex-direction: column; gap: 10px; }}
.game-card {{ background: #1a1a2e; border-radius: 12px; padding: 10px 12px; }}
.game-card-inner {{ display: flex; gap: 12px; }}
.card-left {{ flex-shrink: 0; }}
.game-thumb {{ width: 80px; height: 45px; border-radius: 6px; object-fit: cover; display: block; }}
.card-right {{ flex: 1; min-width: 0; }}
.card-header {{ display: flex; justify-content: space-between; align-items: flex-start; gap: 6px; }}
.game-name {{ font-size: 15px; font-weight: 600; }}
.discount-badge {{ padding: 3px 10px; border-radius: 6px; font-size: 13px; font-weight: 700; flex-shrink: 0; }}
.disc-high {{ background: #e74c3c22; color: #ff6b6b; border: 1px solid #e74c3c44; }}
.disc-mid {{ background: #e67e2222; color: #ffb347; border: 1px solid #e67e2244; }}
.disc-low {{ background: #2ecc7122; color: #6fcf97; border: 1px solid #2ecc7144; }}
.card-price {{ font-size: 16px; font-weight: 700; color: #5dade2; margin-top: 6px; }}
.card-rating {{ font-size: 12px; color: #aaa; margin-top: 4px; }}
.cn-tag {{ font-size: 12px; color: #e8b84b; margin-left: 8px; }}
.top5 {{ margin-top: 28px; }}
.top5 h2 {{ font-size: 18px; margin-bottom: 12px; }}
.top-list {{ display: flex; flex-direction: column; gap: 8px; }}
.top-item {{ background: #1a1a2e; border-radius: 10px; padding: 12px 14px; display: flex; align-items: center; gap: 8px; font-size: 14px; }}
.top-icon {{ font-size: 16px; }}
.top-name {{ flex: 1; font-weight: 600; }}
.top-price {{ color: #5dade2; font-weight: 600; }}
.top-disc {{ color: #ff6b6b; font-weight: 700; }}
.top-rating {{ color: #aaa; font-size: 12px; }}
/* P9 */
.p9-list {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 8px; }}
.p9-item {{ background: #1a1a2e; border-radius: 12px; padding: 8px; text-decoration: none; color: inherit; transition: background 0.2s; display: flex; flex-direction: column; }}
.p9-item:active {{ background: #2a2a3e; }}
.p9-item-inner {{ display: flex; flex-direction: column; align-items: center; text-align: center; gap: 6px; }}
.p9-thumb {{ width: 100%; aspect-ratio: 2/1; border-radius: 8px; overflow: hidden; display: flex; align-items: center; justify-content: center; }}
.p9-thumb-img {{ width: 100%; height: 100%; object-fit: cover; display: block; }}
.p9-thumb-game {{ background: linear-gradient(135deg,#2a5a3e,#1a3a2e); font-size: 32px; }}
.p9-thumb-low {{ background: linear-gradient(135deg,#5a4a1e,#3a2e1a); font-size: 32px; }}
.p9-thumb-guide {{ background: linear-gradient(135deg,#3a2a5e,#2a1a3e); font-size: 32px; }}
.p9-item-texts {{ width: 100%; }}
.p9-title {{ font-size: 13px; font-weight: 600; color: #e8e8f0; line-height: 1.3; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }}
.p9-meta {{ font-size: 11px; color: #888; margin-top: 2px; }}
.footer {{ text-align: center; color: #666; font-size: 12px; padding: 24px 0 16px; }}
/* Search */
.p9-search-box {{ display: flex; gap: 8px; margin-bottom: 16px; }}
.p9-search-input {{ flex: 1; padding: 10px 14px; border: 1px solid #2a2a3e; border-radius: 10px; font-size: 14px; background: #1a1a2e; color: #e8e8f0; outline: none; }}
.p9-search-input:focus {{ border-color: #5dade2; }}
.p9-search-btn {{ padding: 10px 16px; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; background: #2a2a4e; color: #e8e8f0; cursor: pointer; white-space: nowrap; }}
.p9-search-btn:active {{ background: #3a3a5e; }}
/* Mods */
select {{ appearance: none; -webkit-appearance: none; background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23888' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2 5l6 6 6-6'/%3e%3c/svg%3e"); background-repeat: no-repeat; background-position: right 10px center; background-size: 12px; padding-right: 30px; }}
/* Trophy search */
.trophy-bar {{ display: none; align-items: center; gap: 6px; margin-bottom: 8px; }}

.trophy-bar.show {{ display: flex; }}
.trophy-input {{ width: 140px; padding: 6px 10px; border: 1px solid #2a2a3e; border-radius: 8px; font-size: 13px; background: #1a1a2e; color: #e8e8f0; outline: none; }}
.trophy-input:focus {{ border-color: #5dade2; }}
.trophy-btn {{ padding: 6px 10px; border: none; border-radius: 8px; font-size: 13px; background: #2a2a4e; color: #e8e8f0; cursor: pointer; }}
.trophy-btn:active {{ background: #3a3a5e; }}
.trophy-btn-toggle {{ display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; background: transparent; color: #888; cursor: pointer; font-size: 18px; border: none; flex-shrink: 0; }}
.trophy-btn-toggle:hover {{ color: #e8e8f0; }}
/* Game detail modal */
.modal-overlay {{ display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; justify-content: center; align-items: center; padding: 20px; opacity: 0; transition: opacity 0.25s ease, background 0.25s ease; }}
.modal-overlay.show {{ display: flex !important; opacity: 1; background: rgba(0,0,0,0.75); }}
.modal {{ background: linear-gradient(145deg, #1f1f35, #18182a); border-radius: 20px; max-width: 500px; width: 100%; max-height: 85vh; overflow-y: auto; padding: 0; position: relative; transform: translateY(30px) scale(0.95); opacity: 0; transition: transform 0.35s cubic-bezier(0.34, 1.56, 0.64, 1), opacity 0.3s ease; box-shadow: 0 20px 60px rgba(0,0,0,0.5); border: 3px solid #5dade2; animation: borderGlow 3s linear infinite; }}
.modal-overlay.show .modal {{ transform: translateY(0) scale(1); opacity: 1; }}
@keyframes borderGlow {{
  15% {{ border-color: #a855f7; box-shadow: 0 20px 60px rgba(0,0,0,0.5), 0 0 15px 2px rgba(168, 85, 247, 0.25); }}
  30% {{ border-color: #fb7299; box-shadow: 0 20px 60px rgba(0,0,0,0.5), 0 0 15px 2px rgba(251, 114, 153, 0.25); }}
  45% {{ border-color: #fbbf24; box-shadow: 0 20px 60px rgba(0,0,0,0.5), 0 0 15px 2px rgba(251, 191, 36, 0.25); }}
  60% {{ border-color: #34d399; box-shadow: 0 20px 60px rgba(0,0,0,0.5), 0 0 15px 2px rgba(52, 211, 153, 0.25); }}
  75% {{ border-color: #5dade2; box-shadow: 0 20px 60px rgba(0,0,0,0.5), 0 0 15px 2px rgba(93, 173, 226, 0.25); }}
  90% {{ border-color: #a855f7; box-shadow: 0 20px 60px rgba(0,0,0,0.5), 0 0 15px 2px rgba(168, 85, 247, 0.25); }}
}}
.modal-overlay.show .modal {{ transform: translateY(0) scale(1); opacity: 1; }}
.modal::-webkit-scrollbar {{ width: 4px; }}
.modal::-webkit-scrollbar-thumb {{ background: #3a3a5e; border-radius: 4px; }}
.modal-close {{ position: absolute; top: 12px; right: 14px; background: rgba(0,0,0,0.4); border: none; color: #aaa; width: 32px; height: 32px; border-radius: 50%; font-size: 16px; cursor: pointer; z-index: 3; display: flex; align-items: center; justify-content: center; transition: all 0.2s ease; backdrop-filter: blur(4px); }}
.modal-close:hover {{ background: rgba(255,255,255,0.15); color: #fff; transform: rotate(90deg); }}
.modal-img {{ width: 100%; height: 220px; object-fit: cover; border-radius: 20px 20px 0 0; display: block; }}
.modal-body {{ padding: 18px 22px 22px; }}
.modal-body > * {{ opacity: 0; transform: translateY(12px); animation: modalFadeIn 0.4s ease forwards; }}
.modal-body > *:nth-child(1) {{ animation-delay: 0.05s; }}
.modal-body > *:nth-child(2) {{ animation-delay: 0.10s; }}
.modal-body > *:nth-child(3) {{ animation-delay: 0.15s; }}
.modal-body > *:nth-child(4) {{ animation-delay: 0.20s; }}
.modal-body > *:nth-child(5) {{ animation-delay: 0.25s; }}
.modal-body > *:nth-child(6) {{ animation-delay: 0.30s; }}
.modal-body > *:nth-child(7) {{ animation-delay: 0.35s; }}
@keyframes modalFadeIn {{ to {{ opacity: 1; transform: translateY(0); }} }}
.modal-title {{ font-size: 20px; font-weight: 700; margin-bottom: 4px; }}
.modal-price {{ font-size: 16px; color: #5dade2; font-weight: 600; margin-bottom: 10px; }}
.modal-tags {{ display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 10px; }}
.modal-tag {{ display: inline-block; padding: 3px 10px; background: #2a2a4e; border-radius: 6px; font-size: 12px; color: #b0b0d0; white-space: nowrap; transition: all 0.2s ease; cursor: default; }}
.modal-tag:hover {{ background: #3d3d6a; color: #e0e0f0; transform: translateY(-1px); box-shadow: 0 2px 8px rgba(90, 173, 226, 0.15); }}
.modal-rating {{ font-size: 14px; color: #ffb347; margin-bottom: 12px; padding: 8px 12px; background: linear-gradient(135deg, #1a1a2e, #1f1f35); border-radius: 8px; border-left: 3px solid #ffb347; transition: border-left-width 0.2s ease; }}
.modal-desc {{ font-size: 14px; color: #ccc; line-height: 1.7; margin-bottom: 16px; padding: 10px 14px; background: #16162a; border-radius: 10px; border: 1px solid rgba(255,255,255,0.04); }}
.modal-bilibili {{ display: inline-flex; align-items: center; gap: 6px; padding: 10px 18px; background: linear-gradient(135deg, #fb7299, #fc8fa7); color: #fff; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; text-decoration: none; transition: all 0.25s ease; }}
.modal-bilibili:hover {{ background: linear-gradient(135deg, #fc8fab, #ff9db8); transform: translateY(-2px); box-shadow: 0 6px 20px rgba(251, 114, 153, 0.3); }}
</style>
</head>
<body class="tab-trophy">
<div class="particles" id="particles"></div>
<div class="tab-bar">
<button class="tab-btn active" onclick="switchTab('trophy')">🏆 奖杯</button>
<button class="tab-btn" onclick="switchTab('discounts')">🎯 折扣</button>
<button class="tab-btn" onclick="switchTab('psnine')">💬 P9 社区</button>
<a href="mod.html" target="_self" style="flex:1;text-decoration:none;display:block;"><button class="tab-btn">🎮 Mod</button></a>
</div>
<div class="tab-accent trophy" id="tab-accent"></div>

<h1>🎮 Yann 的小站</h1>
<p class="subtitle">PSN 港服 · Steam 国服 · Switch 日服 — 每日自动更新</p>
<p class="last-update">🔄 上次更新: {ts}</p>

<div id="tab-discounts" class="tab-content" style="display:none">
<div class="sub-tab-bar">
<button class="sub-tab-btn active" onclick="switchSubTab('disc-psn', this)">🔵 PSN</button>
<button class="sub-tab-btn" onclick="switchSubTab('disc-steam', this)">🟢 Steam</button>
<button class="sub-tab-btn" onclick="switchSubTab('disc-switch', this)">🟡 Switch</button>
<button class="sub-tab-btn" onclick="switchSubTab('disc-top5', this)">🔥 Top5</button>
</div>
{cards}
{top5}
<div class="footer">💬 对 King 说「最近什么游戏值得买」自动获取 · 数据来源多家平台</div>
</div>

<div id="tab-psnine" class="tab-content" style="display:none">
<div style="display:flex; justify-content:flex-end; align-items:center; gap:6px; margin-bottom:8px;">
<input type="text" id="p9-search-input" style="width:180px;padding:6px 10px;border:1px solid #2a2a3e;border-radius:8px;font-size:13px;background:#1a1a2e;color:#e8e8f0;outline:none;" placeholder="搜游戏名直达P9…" onkeydown="if(event.key===&apos;Enter&apos;) p9Search()">
<button style="padding:6px 10px;border:none;border-radius:8px;font-size:13px;background:#2a2a4e;color:#e8e8f0;cursor:pointer;" onclick="p9Search()">🔍</button>
</div>
<div class="sub-tab-bar p9-section-bar">
<button class="sub-tab-btn active" onclick="switchP9SubTab('p9-game', this)">📦 入库/会免</button>
<button class="sub-tab-btn" onclick="switchP9SubTab('p9-low', this)">💸 新史低</button>
<button class="sub-tab-btn" onclick="switchP9SubTab('p9-guide', this)">🏆 白金攻略</button>
</div>
<div id="p9-results" style="max-width:560px;margin:0 auto;">
<div id="p9-default-content">
{p9_sections}
</div>
</div>
<div class="footer">💬 对 King 说「最近什么游戏值得买」自动获取 · 数据来源多家平台</div>
</div>

<div id="tab-trophy" class="tab-content">
<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:8px;">
<div style="flex:1;"></div>
<button class="trophy-btn-toggle" id="trophy-toggle" onclick="toggleTrophyBar()">🔍</button>
</div>
<div class="trophy-bar" id="trophy-bar">
<input type="text" id="trophy-input" class="trophy-input" placeholder="填PSN ID" onkeydown="if(event.key===&apos;Enter&apos;) trophySearch()">
<button class="trophy-btn" onclick="trophySearch()">🔍</button>
</div>
<div id="trophy-frame" style="display:none; margin-top:12px; max-width:500px; margin-left:auto; margin-right:auto;">
<iframe id="trophy-iframe" style="width:100%;height:600px;max-width:500px;border:none;border-radius:12px;background:#1a1a2e;display:block;margin:0 auto;"></iframe>
</div>
<div class="footer">💬 对 King 说「最近什么游戏值得买」自动获取 · 数据来源多家平台</div>
</div>

<!-- Game detail modal -->
<div class="modal-overlay" id="modal-overlay" onclick="closeModal(event)">
<div class="modal" id="modal" onclick="event.stopPropagation()">
<button class="modal-close" onclick="closeModal()">✕</button>
<img id="modal-img" class="modal-img" src="" alt="">
<div class="modal-body">
<div class="modal-title" id="modal-title"></div>
<div class="modal-price" id="modal-price"></div>
<div class="modal-tags" id="modal-tags"></div>
<div class="modal-rating" id="modal-rating"></div>
<div class="modal-desc" id="modal-desc">暂无详细介绍</div>
<a id="modal-bili-link" class="modal-bilibili" href="#" target="_blank" rel="noopener">▶ 官方预告片</a>
<iframe id="modal-bili-video" style="display:none; width:100%; height:220px; border:none; border-radius:10px; margin-top:8px;" allowfullscreen></iframe>
</div>
</div>
</div>
</div>


<script>
function p9Search() {{
    var q = document.getElementById('p9-search-input').value.trim();
    if (!q) return;
    window.open('https://www.psnine.com/psngame?title=' + encodeURIComponent(q), '_blank');
}}

function trophySearch() {{
    var q = document.getElementById('trophy-input').value.trim();
    if (!q) return;
    localStorage.setItem('trophy_id', q);
    document.getElementById('trophy-frame').style.display = 'block';
    document.getElementById('trophy-iframe').src = 'https://www.psnine.com/psnid/' + encodeURIComponent(q);
}}

function loadSavedTrophy() {{
    var saved = localStorage.getItem('trophy_id');
    if (saved) {{
        document.getElementById('trophy-input').value = saved;
        document.getElementById('trophy-frame').style.display = 'block';
        document.getElementById('trophy-iframe').src = 'https://www.psnine.com/psnid/' + encodeURIComponent(saved);
    }}
}}

function switchSubTab(id, btn) {{
    var sections = document.querySelectorAll('.disc-section');
    var btns = document.querySelectorAll('.sub-tab-btn');
    for (var i = 0; i < sections.length; i++) sections[i].style.display = 'none';
    for (var i = 0; i < btns.length; i++) btns[i].classList.remove('active');
    document.getElementById(id).style.display = 'block';
    btn.classList.add('active');
}}

function switchP9SubTab(id, btn) {{
    var sections = document.querySelectorAll('#tab-psnine .p9-section');
    var btns = document.querySelectorAll('#tab-psnine .p9-section-bar .sub-tab-btn');
    for (var i = 0; i < sections.length; i++) sections[i].style.display = 'none';
    for (var i = 0; i < btns.length; i++) btns[i].classList.remove('active');
    document.getElementById(id).style.display = 'block';
    btn.classList.add('active');
}}

window.onload = function() {{
    loadSavedTrophy();
    spawnParticles();
}};

function spawnParticles() {{
    var container = document.getElementById('particles');
    var shapes = ['Yann','✕','◯','△','□','✦','⬡','♢','Yann','✕','◯','△','□','✦','⬡','♢','Yann','✕','◯','△','□','✦','⬡','♢'];
    var colors = ['rgba(168,85,247,0.3)','rgba(52,211,153,0.25)','rgba(93,173,226,0.25)','rgba(249,115,22,0.25)','rgba(251,191,36,0.3)','rgba(236,72,153,0.2)'];
    // 首屏立即显示一批 - 无延迟、随机初始透明度
    for (var i = 0; i < 30; i++) {{
        var p = document.createElement('div');
        var isText = shapes[i % shapes.length] === 'Yann';
        p.className = 'particle' + (isText ? ' text-particle' : '');
        p.textContent = shapes[i % shapes.length];
        p.style.left = Math.random() * 100 + '%';
        p.style.top = Math.random() * 100 + '%';
        p.style.fontSize = (10 + Math.random() * 10) + 'px';
        p.style.color = colors[i % colors.length];
        p.style.animationDuration = (15 + Math.random() * 20) + 's';
        p.style.animationDelay = (Math.random() * 5) + 's';
        p.style.opacity = (0.1 + Math.random() * 0.4).toString();
        p.style.transform = 'translateY(' + (Math.random() * 60 - 30) + 'px)';
        if (i >= 15) {{
            p.style.animationDirection = 'reverse';
        }}
        container.appendChild(p);
    }}
    // 每10秒再补一批
    setInterval(function() {{
        for (var j = 0; j < 10; j++) {{
            var p = document.createElement('div');
            var isText = shapes[j % shapes.length] === 'Yann';
            p.className = 'particle' + (isText ? ' text-particle' : '');
            p.textContent = shapes[j % shapes.length];
            p.style.left = Math.random() * 100 + '%';
            p.style.top = Math.random() * 100 + '%';
            p.style.fontSize = (10 + Math.random() * 10) + 'px';
            p.style.color = colors[j % colors.length];
            p.style.animationDuration = (15 + Math.random() * 20) + 's';
            p.style.animationDelay = '0s';
            p.style.opacity = '0.3';
            p.style.transform = 'translateY(' + (Math.random() * 60 - 30) + 'px)';
            if (j >= 5) {{
                p.style.animationDirection = 'reverse';
            }}
            container.appendChild(p);
        }}
    }}, 10000);
}}

function switchTab(name) {{
    var btns = document.querySelectorAll('.tab-btn');
    var contents = document.querySelectorAll('.tab-content');
    for (var i = 0; i < contents.length; i++) contents[i].style.display = 'none';
    for (var i = 0; i < btns.length; i++) btns[i].classList.remove('active');
    document.getElementById('tab-' + name).style.display = 'block';
    event.target.classList.add('active');
    // 3D flip animation
    var content = document.getElementById('tab-' + name);
    content.classList.remove('tab-content-fade');
    void content.offsetWidth; // reflow
    content.classList.add('tab-content-fade');
    // Tab accent + body background
    document.querySelector('.tab-accent').className = 'tab-accent ' + name;
    document.body.className = 'tab-' + name;
    if (name === 'psnine') {{
        // Show first P9 sub-tab by default
        var sections = document.querySelectorAll('#tab-psnine .p9-section');
        var sbtns = document.querySelectorAll('#tab-psnine .p9-section-bar .sub-tab-btn');
        for (var i = 0; i < sections.length; i++) sections[i].style.display = i === 0 ? 'block' : 'none';
        for (var i = 0; i < sbtns.length; i++) sbtns[i].classList.toggle('active', i === 0);
    }}
    if (name === 'trophy') {{ loadSavedTrophy(); }}
    if (name === 'discounts') {{
        var sections = document.querySelectorAll('#tab-discounts .disc-section');
        var sbtns = document.querySelectorAll('#tab-discounts .sub-tab-btn');
        for (var i = 0; i < sections.length; i++) sections[i].style.display = i === 0 ? 'block' : 'none';
        for (var i = 0; i < sbtns.length; i++) sbtns[i].classList.toggle('active', i === 0);
    }}
    if (name === 'mods') {{
        var sections = document.querySelectorAll('#tab-mods .mod-section');
        var sbtns = document.querySelectorAll('#tab-mods .p9-section-bar .sub-tab-btn');
        for (var i = 0; i < sections.length; i++) sections[i].style.display = i === 0 ? 'block' : 'none';
        for (var i = 0; i < sbtns.length; i++) sbtns[i].classList.toggle('active', i === 0);
    }}
}}

function switchModSubTab(id, btn) {{
    var sections = document.querySelectorAll('#tab-mods .mod-section');
    var btns = document.querySelectorAll('#tab-mods .p9-section-bar .sub-tab-btn');
    for (var i = 0; i < sections.length; i++) sections[i].style.display = 'none';
    for (var i = 0; i < btns.length; i++) btns[i].classList.remove('active');
    document.getElementById(id).style.display = 'block';
    btn.classList.add('active');
}}

function toggleTrophyBar() {{
    var bar = document.getElementById('trophy-bar');
    var toggle = document.getElementById('trophy-toggle');
    if (bar.classList.contains('show')) {{
        bar.classList.remove('show');
        toggle.style.display = 'inline-flex';
    }} else {{
        bar.classList.add('show');
        toggle.style.display = 'none';
        document.getElementById('trophy-input').focus();
    }}
}}

function showGameModal(el) {{
    var card = el.closest('.game-card');
    var name = card.querySelector('.game-name').textContent.trim();
    var price = card.querySelector('.current-price') ? card.querySelector('.current-price').textContent.trim() : '';
    var img = card.querySelector('.game-thumb');
    var rating = card.querySelector('.card-rating') ? card.querySelector('.card-rating').textContent.trim() : '';
    var discount = card.querySelector('.discount-badge') ? card.querySelector('.discount-badge').textContent.trim() : '';
    var desc = card.getAttribute('data-desc') || '正在查询该游戏的详细评价，请稍候...';
    var tagsStr = card.getAttribute('data-tags') || '';
    var bvid = card.getAttribute('data-bvid') || '';

    document.getElementById('modal-title').textContent = name + ' ' + discount;
    document.getElementById('modal-price').textContent = price;
    document.getElementById('modal-rating').textContent = rating || '暂无评分';
    document.getElementById('modal-desc').textContent = desc;

    // Tags
    var tagsEl = document.getElementById('modal-tags');
    tagsEl.innerHTML = '';
    if (tagsStr) {{
        var tags = tagsStr.split('|');
        for (var i = 0; i < tags.length; i++) {{
            var span = document.createElement('span');
            span.className = 'modal-tag';
            span.textContent = tags[i];
            tagsEl.appendChild(span);
        }}
        tagsEl.style.display = 'flex';
    }} else {{
        tagsEl.style.display = 'none';
    }}
    if (img && img.src) {{
        document.getElementById('modal-img').src = img.src;
        document.getElementById('modal-img').style.display = 'block';
    }} else {{
        document.getElementById('modal-img').style.display = 'none';
    }}

    var biliLink = document.getElementById('modal-bili-link');
    var biliIframe = document.getElementById('modal-bili-video');
    var searchName = name.replace(/[《》「」]/g, '').trim();
    
    if (bvid) {{
        biliLink.style.display = 'none';
        biliIframe.style.display = 'block';
        biliIframe.src = 'https://player.bilibili.com/player.html?bvid=' + bvid + '&autoplay=0';
    }} else {{
        biliLink.style.display = 'inline-flex';
        biliIframe.style.display = 'none';
        biliIframe.src = '';
        biliLink.href = 'https://search.bilibili.com/all?keyword=' + encodeURIComponent(searchName + ' 官方预告片') + '&from_source=webtop_search';
    }}

    document.getElementById('modal-overlay').classList.add('show');
    document.body.style.overflow = 'hidden';
}}

function closeModal(e) {{
    if (e && e.target !== e.currentTarget) return;
    document.getElementById('modal-overlay').classList.remove('show');
    document.body.style.overflow = '';
}}

function setModSearch(keyword) {{
    document.getElementById('mod-search-input').value = keyword;
    modSearchRedirect();
}}

function setModSearchGame(game) {{
    document.getElementById('mod-search-input').value = game;
    modSearchRedirect();
}}

function modSearchRedirect() {{
    var q = document.getElementById('mod-search-input').value.trim();
    if (!q) return;
    window.open('https://www.nexusmods.com/search/?search=' + encodeURIComponent(q), '_blank');
}}

function modSearchRedirectKW(kw, game) {{
    // Show cached group if available
    var slug = 'rc-' + kw + '-' + game;
    var el = document.getElementById(slug);
    if (el) {{
        // Hide all groups, show this one
        var groups = document.querySelectorAll('.mod-cache-group');
        for (var i = 0; i < groups.length; i++) groups[i].style.display = 'none';
        el.style.display = 'block';
        document.getElementById('mod-cache-results').style.display = 'block';
    }} else {{
        window.open('https://www.nexusmods.com/search/?search=' + encodeURIComponent(kw + ' ' + game), '_blank');
    }}
}}

function modSearchRedirectGame(game) {{
    window.open('https://www.nexusmods.com/' + game + '/mods/', '_blank');
}}
</script>
</body>
</html>'''
    return html


if __name__ == '__main__':
    out_dir = sys.argv[1] if len(sys.argv) > 1 else 'docs'
    os.makedirs(out_dir, exist_ok=True)
    html = generate_html()
    out_path = os.path.join(out_dir, 'index.html')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f"✅ HTML saved to {out_path}")
