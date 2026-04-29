#!/usr/bin/env python3
import re

with open('deals.py', 'rb') as f:
    content = f.read()
text = content.decode('utf-8')

# ---- 1. Replace GAME_DETAILS ----
old_d_start = text.find("GAME_DETAILS = {")
new_func = "\ndef game_detail(name):"
old_d_end = text.find(new_func, old_d_start)

new_details = """GAME_DETAILS = {
    # Format: 'game_key': (简介, [评价标签], BV号)
    'elden ring': ('宫崎英高与乔治·R·R·马丁联手打造的动作RPG史诗。穿越「狭间之地」，挑战半神，揭开法环碎裂之谜。辽阔的开放世界令人惊叹，隐藏地牢与巨型Boss战充满探索欲。', ['动作RPG', 'MC96 年度最佳', 'TGA 2022年度游戏', '开放世界标杆'], 'BV1q5411c7aP'),
    'ghost of tsushima': ('以1274年元日战争为背景的开放世界动作冒险。武士境井仁在蒙古入侵下化身「战鬼」，守护对马岛。绝美的日本风光、爽快的刀剑对决、沉浸的和风叙事。', ['开放世界动作', 'MC87 佳作', '武士题材必玩', '玩家选择奖'], 'BV1d4411f7Q6'),
    'resident evil 4': ('经典生存恐怖系列巅峰之作。特工里昂前往欧洲村庄营救总统女儿。完美融合动作射击与恐怖氛围，关卡设计教科书级别。重制版画质大幅提升，战斗系统更流畅。', ['动作恐怖', 'MC93 必玩神作', '系列天花板', '最佳重制'], 'BV1Xk4y1q7Qp'),
    'persona 5 royal': ('风格前卫的日式角色扮演游戏。白天是高中生，夜晚化身怪盗潜入心灵迷宫。UI设计独树一帜，剧情深刻，BGM神级。皇家版加入新角色和第三学期内容。', ['日式RPG', 'MC95 神作', '200小时+内容量', '原声封神'], 'BV1JZ4y1X7YW'),
    'persona 5': ('风格前卫的日式角色扮演游戏。白天是高中生，夜晚化身怪盗潜入心灵迷宫。UI设计独树一帜，剧情深刻，BGM神级。皇家版加入新角色和第三学期内容。', ['日式RPG', 'MC95 神作', '200小时+内容量', '原声封神'], 'BV1JZ4y1X7YW'),
    'cyberpunk 2077': ('开放世界科幻RPG。在夜之城扮演雇佣兵V追寻永生。初期优化翻车，但经DLC「往日之影」与2.0大更新后彻底翻身——沉浸感爆棚的赛博朋克世界，剧情深刻，战斗爽快。', ['开放世界RPG', 'MC86 已修复', 'DLC口碑极佳', '2024年最佳翻身作'], 'BV1M3411C7mD'),
    'split fiction': ('「双人成行」团队最新力作。两位女主角穿梭科幻世界，兼具创新玩法与感人剧情。每一关都有全新机制，画面震撼，2025年TGA年度游戏有力竞争者。', ['双人合作', 'MC91 年度黑马', '必玩双人游戏', '最佳合作游戏'], 'BV1Jw411d7vB'),
    'it takes two': ('专门为双人合作设计的动作冒险游戏。一对即将离婚的夫妻变成玩偶，在奇幻世界中修复感情。每一章都有完全不同的玩法机制。荣获TGA 2021年度游戏。', ['双人合作', 'MC90 神作', 'TGA 2021年度游戏', '情侣必玩'], 'BV1rX4y1w7Td'),
    'stellar blade': ('末世科幻动作RPG。战士夏娃在末世上与奈提巴战斗，夺回家园。战斗系统流畅华丽，女主角设计出众，BOSS战魄力十足。索尼独占品质之作。', ['动作RPG', 'MC81 佳作', '战斗爽快', '配乐出色'], 'BV1wZ421e7zh'),
    'balatro': ('扑克牌Roguelike的独立神作。构建强力牌组挑战关底，数学策略与运气完美结合。一局接一局根本停不下来。2024年独立游戏最强口碑之一。', ['肉鸽/卡牌', 'MC90 独立神作', '上瘾警告', '性价比之王'], 'BV1rN4y1j7P1'),
    'black myth wukong': ('国产动作游戏里程碑。扮演「天命人」在东方奇幻世界探索，体验西游故事的全新演绎。画面表现力惊艳，Boss战设计出色，战斗系统扎实。全球销量破千万。', ['动作RPG', 'MC81 国产之光', '画面顶级', '中文文化输出'], 'BV14M4m1y7Gd'),
    'the witcher': ('开放世界RPG的标杆之作。猎魔人杰洛特穿越战乱大陆寻找养女希里。分支剧情深刻影响结局、人物塑造入木三分、「血与酒」DLC被誉为最佳DLC之一。', ['开放世界RPG', 'MC93 神作', '剧情天花板', 'TGA 2015年度游戏'], 'BV1is411i7WX'),
    'witcher': ('开放世界RPG的标杆之作。猎魔人杰洛特穿越战乱大陆寻找养女希里。分支剧情深刻影响结局、人物塑造入木三分、「血与酒」DLC被誉为最佳DLC之一。', ['开放世界RPG', 'MC93 神作', '剧情天花板', 'TGA 2015年度游戏'], 'BV1is411i7WX'),
    'monster hunter': ('共斗动作RPG的标杆。与好友组队狩猎巨型怪物，剥取材料打造更强装备。14种武器各有深度，每场战斗都是技术与策略的博弈。千小时内容量。', ['共斗动作', 'MC90 系列巅峰', '多人必玩', '千小时内容'], 'BV1GJ41187Qf'),
    'hades': ('Roguelike动作游戏天花板。冥王之子扎格柔斯试图逃离冥界。每一次死亡都是成长的契机，人物关系发展推动故事。战斗爽快、美术惊艳、叙事手法创新。', ['肉鸽动作', 'MC93 神作', 'TGA最佳动作', '2020年度游戏提名'], 'BV1kK4y187Vw'),
    'hades ii': ('备受期待的续作。扮演冥王之女墨利诺厄，探索全新希腊神话世界。保留前作精华的同时带来更丰富的战斗系统、法术体系和故事深度。', ['肉鸽动作', 'MC86 佳作', 'EA持续更新中', '超越前作潜力'], 'BV1SH4y177mr'),
    'dynasty warriors': ('「一骑当千」的爽快动作系列。三国武将横扫千军。真·三国无双 起源是系列革新之作，战斗系统大幅进化，战场氛围更真实。', ['动作割草', 'MC80 系列革新', '爽快解压', '起源口碑回升'], 'BV1RJ411q7o6'),
    'forza horizon': ('开放世界赛车游戏标杆。在广阔的风景中自由驰骋，参与各类赛事。画面精美、手感出色、车辆海量。地平线嘉年华氛围让人放松。', ['赛车竞速', 'MC92 最佳赛车', '开放世界赛车', '系列常青树'], 'BV1d4411S7LY'),
    'tmnt': ('忍者神龟再度集结！在纽约街头与施莱德等反派战斗。支持多人合作，经典动画画风，怀旧感满满。适合与朋友一起玩。', ['动作清版', 'MC75 中等', '多人合作', '怀旧情怀'], ''),
    'gran turismo 7': ('索尼第一方赛车模拟巅峰。海量真实车型和赛道，逼真驾驶体验与出色画面。GT系列25周年集大成之作，从新车手到老司机都能找到乐趣。', ['赛车模拟', 'MC87 最佳竞速', '真实驾驶体验', '系列25周年'], 'BV1t44y1q7LL'),
}

def game_detail(name):"""

text = text[:old_d_start] + new_details + text[old_d_end+len(new_func):]

# ---- 2. Update discount card generation ----
# Pattern in discount section
text = text.replace(
    "desc, bvid = game_detail(display_name)",
    "desc, tags, bvid = game_detail(display_name)"
)
text = text.replace(
    "desc, bvid = game_detail(display)",
    "desc, tags, bvid = game_detail(display)"
)

text = text.replace(
    "desc_attr = f'data-desc=\"{html_mod.escape(desc)}\"' if desc else ''\n            bvid_attr = f'data-bvid=\"{bvid}\"' if bvid else ''''",
    "desc_attr = f'data-desc=\"{html_mod.escape(desc)}\"' if desc else ''\n            tags_attr = f'data-tags=\"{html_mod.escape(\"|\".join(tags))}\"' if tags else ''\n            bvid_attr = f'data-bvid=\"{bvid}\"' if bvid else ''''"
)

text = text.replace(
    "desc_attr = f'data-desc=\"{html_mod.escape(desc)}\"' if desc else ''\n        bvid_attr = f'data-bvid=\"{bvid}\"' if bvid else ''''",
    "desc_attr = f'data-desc=\"{html_mod.escape(desc)}\"' if desc else ''\n        tags_attr = f'data-tags=\"{html_mod.escape(\"|\".join(tags))}\"' if tags else ''\n        bvid_attr = f'data-bvid=\"{bvid}\"' if bvid else ''''"
)

# Add tags_attr to div opening
text = text.replace(
    'top5 += f\\'\\\\n<div class="game-card"{desc_attr} {bvid_attr}>\\'',
    'top5 += f\\'\\\\n<div class="game-card"{desc_attr} {tags_attr} {bvid_attr}>\\''
)
text = text.replace(
    'cards += f\\'\\\\n            <div class="game-card"{desc_attr} {bvid_attr}>\\'',
    'cards += f\\'\\\\n            <div class="game-card"{desc_attr} {tags_attr} {bvid_attr}>\\''
)

# ---- 3. Update modal HTML ----
text = text.replace(
    '<div class="modal-rating" id="modal-rating"></div>\\n<div class="modal-desc" id="modal-desc">',
    '<div class="modal-tags" id="modal-tags"></div>\\n<div class="modal-rating" id="modal-rating"></div>\\n<div class="modal-desc" id="modal-desc">'
)

# ---- 4. Update modal CSS ----
old_css = """.modal-img {{ width: 100%; height: 200px; object-fit: cover; border-radius: 16px 16px 0 0; display: block; }}
.modal-body {{ padding: 16px 20px 20px; }}
.modal-title {{ font-size: 18px; font-weight: 700; margin-bottom: 6px; }}
.modal-price {{ font-size: 15px; color: #5dade2; font-weight: 600; margin-bottom: 8px; }}
.modal-rating {{ font-size: 13px; color: #ffb347; margin-bottom: 12px; }}
.modal-desc {{ font-size: 14px; color: #ccc; line-height: 1.6; margin-bottom: 16px; }}
.modal-bilibili {{ display: inline-flex; align-items: center; gap: 6px; padding: 10px 18px; background: #fb7299; color: #fff; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; text-decoration: none; }}
.modal-bilibili:hover {{ background: #fc8bab; }}"""

new_css = """.modal-img {{ width: 100%; height: 220px; object-fit: cover; border-radius: 16px 16px 0 0; display: block; }}
.modal-body {{ padding: 18px 22px 22px; }}
.modal-title {{ font-size: 20px; font-weight: 700; margin-bottom: 4px; }}
.modal-price {{ font-size: 16px; color: #5dade2; font-weight: 600; margin-bottom: 10px; }}
.modal-tags {{ display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 10px; }}
.modal-tag {{ display: inline-block; padding: 3px 10px; background: #2a2a4e; border-radius: 6px; font-size: 12px; color: #b0b0d0; white-space: nowrap; }}
.modal-rating {{ font-size: 14px; color: #ffb347; margin-bottom: 12px; padding: 8px 12px; background: #1a1a2e; border-radius: 8px; border-left: 3px solid #ffb347; }}
.modal-desc {{ font-size: 14px; color: #ccc; line-height: 1.7; margin-bottom: 16px; padding: 10px 14px; background: #16162a; border-radius: 10px; }}
.modal-bilibili {{ display: inline-flex; align-items: center; gap: 6px; padding: 10px 18px; background: #fb7299; color: #fff; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; text-decoration: none; }}
.modal-bilibili:hover {{ background: #fc8bab; }}"""

text = text.replace(old_css, new_css, 1)

# ---- 5. Update showGameModal JS ----
old_show = "function showGameModal(el) {{\n    var card = el.closest('.game-card');\n    var name = card.querySelector('.game-name').textContent.trim();\n    var price = card.querySelector('.current-price') ? card.querySelector('.current-price').textContent.trim() : '';\n    var img = card.querySelector('.game-thumb');\n    var rating = card.querySelector('.card-rating') ? card.querySelector('.card-rating').textContent.trim() : '';\n    var discount = card.querySelector('.discount-badge') ? card.querySelector('.discount-badge').textContent.trim() : '';\n    var desc = card.getAttribute('data-desc') || '暂无详细介绍';\n    var bvid = card.getAttribute('data-bvid') || '';\n\n    document.getElementById('modal-title').textContent = name + ' ' + discount;\n    document.getElementById('modal-price').textContent = price;\n    document.getElementById('modal-rating').textContent = rating || '暂无评分';\n    document.getElementById('modal-desc').textContent = desc;\n\n    if (img && img.src) {{\n        document.getElementById('modal-img').src = img.src;\n        document.getElementById('modal-img').style.display = 'block';\n    }} else {{\n        document.getElementById('modal-img').style.display = 'none';\n    }}\n\n    var biliLink = document.getElementById('modal-bili-link');\n    var biliIframe = document.getElementById('modal-bili-video');\n    var searchName = name.replace(/[《》「」]/g, '').trim();\n    \n    if (bvid) {{\n        biliLink.style.display = 'none';\n        biliIframe.style.display = 'block';\n        biliIframe.src = 'https://player.bilibili.com/player.html?bvid=' + bvid + '&autoplay=0';\n    }} else {{\n        biliLink.style.display = 'inline-flex';\n        biliIframe.style.display = 'none';\n        biliIframe.src = '';\n        biliLink.href = 'https://search.bilibili.com/all?keyword=' + encodeURIComponent(searchName + ' 游戏') + '&from_source=webtop_search';\n    }}\n\n    document.getElementById('modal-overlay').classList.add('show');\n    document.body.style.overflow = 'hidden';\n}}"

new_show = "function showGameModal(el) {{\n    var card = el.closest('.game-card');\n    var name = card.querySelector('.game-name').textContent.trim();\n    var price = card.querySelector('.current-price') ? card.querySelector('.current-price').textContent.trim() : '';\n    var img = card.querySelector('.game-thumb');\n    var rating = card.querySelector('.card-rating') ? card.querySelector('.card-rating').textContent.trim() : '';\n    var discount = card.querySelector('.discount-badge') ? card.querySelector('.discount-badge').textContent.trim() : '';\n    var desc = card.getAttribute('data-desc') || '正在查询该游戏的详细评价，请稍候...';\n    var tagsStr = card.getAttribute('data-tags') || '';\n    var bvid = card.getAttribute('data-bvid') || '';\n\n    document.getElementById('modal-title').textContent = name + ' ' + discount;\n    document.getElementById('modal-price').textContent = price;\n    document.getElementById('modal-rating').textContent = rating || '暂无评分';\n    document.getElementById('modal-desc').textContent = desc;\n\n    // Tags\n    var tagsEl = document.getElementById('modal-tags');\n    tagsEl.innerHTML = '';\n    if (tagsStr) {{\n        var tags = tagsStr.split('|');\n        for (var i = 0; i < tags.length; i++) {{\n            var span = document.createElement('span');\n            span.className = 'modal-tag';\n            span.textContent = tags[i];\n            tagsEl.appendChild(span);\n        }}\n        tagsEl.style.display = 'flex';\n    }} else {{\n        tagsEl.style.display = 'none';\n    }}\n\n    if (img && img.src) {{\n        document.getElementById('modal-img').src = img.src;\n        document.getElementById('modal-img').style.display = 'block';\n    }} else {{\n        document.getElementById('modal-img').style.display = 'none';\n    }}\n\n    var biliLink = document.getElementById('modal-bili-link');\n    var biliIframe = document.getElementById('modal-bili-video');\n    var searchName = name.replace(/[《》「」]/g, '').trim();\n    \n    if (bvid) {{\n        biliLink.style.display = 'none';\n        biliIframe.style.display = 'block';\n        biliIframe.src = 'https://player.bilibili.com/player.html?bvid=' + bvid + '&autoplay=0';\n    }} else {{\n        biliLink.style.display = 'inline-flex';\n        biliIframe.style.display = 'none';\n        biliIframe.src = '';\n        biliLink.href = 'https://search.bilibili.com/all?keyword=' + encodeURIComponent(searchName + ' 游戏') + '&from_source=webtop_search';\n    }}\n\n    document.getElementById('modal-overlay').classList.add('show');\n    document.body.style.overflow = 'hidden';\n}}"

text = text.replace(old_show, new_show, 1)

with open('deals.py', 'wb') as f:
    f.write(text.encode('utf-8'))
print("Done!")
