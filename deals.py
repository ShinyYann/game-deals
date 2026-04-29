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
}

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
            'tags': tags
        })
    
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
    html = fetch("https://store.playstation.com/zh-hant-hk/pages/deals")
    if not html: return []
    soup = BeautifulSoup(html, 'lxml')
    games = []
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
        games.append({'name': name.strip(), 'price': price.strip(), 'discount': disc.strip(), 'original_price': orig.strip()})
    return games

def parse_steam():
    data = fetch_json("https://store.steampowered.com/api/featuredcategories?cc=cn&l=zh")
    if not data: return []
    games = []
    specials = data.get('specials', {}).get('items', [])
    if isinstance(specials, list):
        for item in specials[:25]:
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
        'original_price': f'¥{op/100:.0f}' if op else ''
    }

def parse_switch():
    """Get Switch deals from Nintendo Japan eShop."""
    url = "https://search.nintendo.jp/nintendo_soft/search.json?q=&opt_sshow=1&limit=50"
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
        games.append({
            'name': title.strip(),
            'price': f'¥{current_price:,.0f}' if current_price else '',
            'discount': f'-{drate:.0f}%' if drate else '',
            'original_price': f'¥{price:,.0f}' if price else '',
            'has_cn': has_cn
        })
    return games

# ─── HTML generation ───────────────────────────────────────────────
def generate_html():
    ts = time.strftime('%Y-%m-%d %H:%M', time.localtime())
    psn = parse_psn()
    steam = parse_steam()
    switch = parse_switch()
    psnine = parse_psnine()

    def score_items(games, cn_bonus=False):
        seen, result = set(), []
        for g in games:
            n = clean_name(g['name'])
            if not n or n in seen: continue
            seen.add(n)
            r = rating_text(n)
            d = disc_pct(g['discount']) + (5 if cn_bonus and g.get('has_cn', False) else 0)
            p = price_num(g['price'])
            result.append((d + (10 if r else 0), n, g, r, d, p))
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

    cards = ""
    for label, items, icon, raw_label in [
        ("PSN 港服特惠", psn_items[:8], "🔵", "PSN"),
        ("Steam 国服特惠", steam_items[:8], "🟢", "Steam"),
        ("Switch 日服特惠", switch_items[:8], "🟡", "Switch"),
    ]:
        if not items:
            continue
        cards += f'<section class="platform"><h2>{icon} {label}</h2><div class="game-list">'
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
            cards += f'''
            <div class="game-card">
                <div class="card-header">
                    <span class="game-name">{display_name}</span>
                    <span class="discount-badge {disc_cls}">{disc_s}</span>
                </div>
                <div class="card-price">
                    <span class="current-price">{price}</span>{cn_tag}
                </div>
                <div class="card-rating">{rating}</div>
            </div>'''
        cards += '</div></section>'

    top5 = "<section class='top5'><h2>🔥 综合推荐 TOP 5</h2><div class='top-list'>"
    used = set()
    count = 0
    for s, n, g, r, d, p, plat in all_items:
        if count >= 5: break
        if n in used: continue
        used.add(n)
        display = trans_short(n)
        icon = platform_icon(plat)
        price = g['price']
        disc_s = g['discount']
        rating = (r[:15] if r else "") or ""
        top5 += f'<div class="top-item"><span class="top-icon">{icon}</span><span class="top-name">{display}</span> <span class="top-price">{price}</span> <span class="top-disc">{disc_s}</span> <span class="top-rating">{rating}</span></div>'
        count += 1
    top5 += "</div></section>"

    # ─── PSNine community ───────────────────────────────────────────
    p9_sections = ""

    if psnine.get('gamelist'):
        p9_sections += '<section class="platform"><h2>📦 P9 入库/会免信息</h2><div class="p9-list">'
        for item in psnine['gamelist'][:4]:
            link = item['link']
            if link and not link.startswith('http'):
                link = 'https://www.psnine.com' + link
            title = item['title'][:48]
            p9_sections += f'''
            <a href="{link}" class="p9-item" target="_blank" rel="noopener">
                <span class="p9-title">{title}</span>
                <span class="p9-meta">✎ {item['author']} · {item['time']}</span>
            </a>'''
        p9_sections += '</div></section>'

    if psnine.get('new_lows'):
        p9_sections += '<section class="platform"><h2>💸 P9 新史低汇总</h2><div class="p9-list">'
        for item in psnine['new_lows'][:4]:
            link = item['link']
            if link and not link.startswith('http'):
                link = 'https://www.psnine.com' + link
            title = item['title'][:48]
            p9_sections += f'''
            <a href="{link}" class="p9-item" target="_blank" rel="noopener">
                <span class="p9-title">{title}</span>
                <span class="p9-meta">✎ {item['author']} · {item['time']}</span>
            </a>'''
        p9_sections += '</div></section>'

    if psnine.get('guides'):
        p9_sections += '<section class="platform"><h2>🏆 P9 热门白金攻略</h2><div class="p9-list">'
        for item in psnine['guides'][:6]:
            link = item['link']
            if link and not link.startswith('http'):
                link = 'https://www.psnine.com' + link
            title = item['title'][:48]
            p9_sections += f'''
            <a href="{link}" class="p9-item" target="_blank" rel="noopener">
                <span class="p9-title">{title}</span>
                <span class="p9-meta">✎ {item['author']} · {item['time']}</span>
            </a>'''
        p9_sections += '</div></section>'

    # Build tab content for each section

    html = f'''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>本周游戏折扣精选</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f0f1a; color: #e8e8f0; padding: 16px; max-width: 800px; margin: 0 auto; }}
h1 {{ text-align: center; font-size: 24px; padding: 16px 0 4px; }}
.subtitle {{ text-align: center; color: #888; font-size: 13px; margin-bottom: 20px; }}
.last-update {{ text-align: center; color: #555; font-size: 11px; margin-bottom: 20px; }}
/* Tabs */
.tab-bar {{ display: flex; gap: 8px; margin-bottom: 16px; position: sticky; top: 0; background: #0f0f1a; padding: 8px 0; z-index: 10; }}
.tab-btn {{ flex: 1; padding: 10px; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; background: #1a1a2e; color: #888; transition: all 0.2s; }}
.tab-btn.active {{ background: #2a2a4e; color: #e8e8f0; }}
.tab-btn:active {{ background: #3a3a5e; }}
/* Discounts */
.platform {{ margin-bottom: 24px; }}
.platform h2 {{ font-size: 18px; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1px solid #2a2a3e; }}
.game-list {{ display: flex; flex-direction: column; gap: 10px; }}
.game-card {{ background: #1a1a2e; border-radius: 12px; padding: 14px 16px; }}
.card-header {{ display: flex; justify-content: space-between; align-items: center; }}
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
.p9-list {{ display: flex; flex-direction: column; gap: 6px; }}
.p9-item {{ background: #1a1a2e; border-radius: 10px; padding: 12px 14px; display: flex; flex-direction: column; gap: 4px; text-decoration: none; color: inherit; transition: background 0.2s; }}
.p9-item:active {{ background: #2a2a3e; }}
.p9-title {{ font-size: 14px; font-weight: 600; color: #e8e8f0; line-height: 1.4; }}
.p9-meta {{ font-size: 11px; color: #888; }}
.footer {{ text-align: center; color: #666; font-size: 12px; padding: 24px 0 16px; }}
/* Search */
.p9-search-box {{ display: flex; gap: 8px; margin-bottom: 16px; }}
.p9-search-input {{ flex: 1; padding: 10px 14px; border: 1px solid #2a2a3e; border-radius: 10px; font-size: 14px; background: #1a1a2e; color: #e8e8f0; outline: none; }}
.p9-search-input:focus {{ border-color: #5dade2; }}
.p9-search-btn {{ padding: 10px 16px; border: none; border-radius: 10px; font-size: 14px; font-weight: 600; background: #2a2a4e; color: #e8e8f0; cursor: pointer; white-space: nowrap; }}
.p9-search-btn:active {{ background: #3a3a5e; }}
</style>
</head>
<body>
<h1>🎮 本周游戏折扣精选</h1>
<p class="subtitle">PSN 港服 · Steam 国服 · Switch 日服 — 每日自动更新</p>
<p class="last-update">🔄 上次更新: {ts}</p>

<div class="tab-bar">
<button class="tab-btn active" onclick="switchTab('discounts')">🎯 折扣</button>
<button class="tab-btn" onclick="switchTab('psnine')">💬 P9 社区</button>
<button class="tab-btn" onclick="switchTab('trophy')">🏆 奖杯查询</button>
</div>

<div id="tab-discounts" class="tab-content">
{cards}
{top5}
</div>

<div id="tab-psnine" class="tab-content" style="display:none">
<div class="p9-search-box">
<input type="text" id="p9-search-input" class="p9-search-input" placeholder="搜游戏名直达P9游戏区…" onkeydown="if(event.key===&apos;Enter&apos;) p9Search()">
<button class="p9-search-btn" onclick="p9Search()">🔍 直达游戏</button>
</div>
<div id="p9-results">
<div id="p9-default-content">
{p9_sections}
</div>
</div>
</div>

<div id="tab-trophy" class="tab-content" style="display:none">
<div class="trophy-intro" style="color:#888;font-size:13px;margin-bottom:12px;">输入 PSN 用户名查看奖杯</div>
<div class="p9-search-box">
<input type="text" id="trophy-input" class="p9-search-input" placeholder="例如 wanshuai12138…" onkeydown="if(event.key===&apos;Enter&apos;) trophySearch()">
<button class="p9-search-btn" onclick="trophySearch()">🏆 查看奖杯</button>
</div>
<div id="trophy-frame" style="display:none; margin-top:12px;">
<iframe id="trophy-iframe" style="width:100%;height:800px;border:none;border-radius:12px;background:#1a1a2e;"></iframe>
</div>
</div>

<div class="footer">💬 对 King 说「最近什么游戏值得买」自动获取 · 数据来源多家平台</div>

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

window.onload = function() {{
    loadSavedTrophy();
}};

function switchTab(name) {{
    var btns = document.querySelectorAll('.tab-btn');
    var contents = document.querySelectorAll('.tab-content');
    for (var i = 0; i < contents.length; i++) contents[i].style.display = 'none';
    for (var i = 0; i < btns.length; i++) btns[i].classList.remove('active');
    document.getElementById('tab-' + name).style.display = 'block';
    event.target.classList.add('active');
    if (name === 'psnine') setTimeout(function(){{ document.getElementById('p9-search-input').focus(); }}, 300);
    if (name === 'trophy') setTimeout(function(){{ loadSavedTrophy(); }}, 100);
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
