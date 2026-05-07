#!/usr/bin/env python3
"""Steam badge scraper — parses steamcommunity.com profile badges + gamecards page"""

import urllib.request
import urllib.error
import re
import json
import time


# ── Chinese translations for badge names & level names ──
BADGE_NAME_ZH = {
    # Community badges
    "Pillar of Community": "社区栋梁",
    "Power Player": "强力玩家",
    "Steam Replay 2025": "Steam 年度回顾 2025",
    "Steam Replay 2022": "Steam 年度回顾 2022",
    "Steam Grand Prix 2019": "Steam 大奖赛 2019",
    "Years of Service": "服役年数",
    "Gem Maker": "宝石工匠",
    # Game names (partial — others auto-detect from known list)
    "PAYDAY 2": "收获日 2",
    "The Escapists 2": "逃脱者 2",
    "Warhammer: Vermintide 2": "战锤：末日鼠疫 2",
    "Batman™: Arkham Origins": "蝙蝠侠：阿卡姆起源",
    "Batman: Arkham City GOTY": "蝙蝠侠：阿卡姆之城 年度版",
    "Batman: Arkham Asylum GOTY Edition": "蝙蝠侠：阿卡姆疯人院 年度版",
    "Catherine Classic": "凯瑟琳 经典版",
    "The Witcher 2: Assassins of Kings Enhanced Edition": "巫师 2：国王刺客 增强版",
    "The Legend of Heroes: Trails in the Sky the 3rd": "英雄传说：空之轨迹 the 3rd",
    "Divinity: Original Sin 2": "神界：原罪 2",
    "RPG Maker MV": "RPG 制作大师 MV",
    "ONE PIECE World Seeker": "海贼王 寻秘世界",
    "Hyperdimension Neptunia Re;Birth1": "超次元游戏 海王星 重生 1",
    "Total War: THREE KINGDOMS": "全面战争：三国",
    "Wallpaper Engine": "壁纸引擎",
    "Bayonetta": "猎天使魔女",
    "Monster Hunter: World": "怪物猎人：世界",
    "Batman™: Arkham Knight": "蝙蝠侠：阿卡姆骑士",
    "Stardew Valley": "星露谷物语",
    "Danganronpa Another Episode: Ultra Despair Girls": "弹丸论破 绝对绝望少女",
    "TEKKEN 7": "铁拳 7",
    "Zombie Army Trilogy": "僵尸部队三部曲",
    "Danganronpa: Trigger Happy Havoc": "弹丸论破：希望的学园与绝望高中生",
    "Danganronpa 2: Goodbye Despair": "超级弹丸论破 2：再见绝望学园",
    "STEINS;GATE": "命运石之门",
}

# Steam community badge descriptions
BADGE_DESC_ZH = {
    "Pillar of Community": "参与社区活动获得的徽章",
    "Power Player": "拥有大量游戏的玩家徽章",
    "Steam Replay 2025": "2025 年度游戏回顾徽章",
    "Steam Replay 2022": "2022 年度游戏回顾徽章",
    "Steam Grand Prix 2019": "2019 年 Steam 夏季大奖赛活动徽章",
    "Years of Service": "Steam 账号注册周年纪念徽章",
    "Gem Maker": "通过合成宝石获得的徽章",
}


def _zh(name: str) -> str:
    """Get Chinese name, fallback to English"""
    return BADGE_NAME_ZH.get(name, name)


def _zh_desc(name: str) -> str:
    """Get Chinese description"""
    return BADGE_DESC_ZH.get(name, "")


# ── English date → Chinese date ──
_MONTHS_EN = {'January':'1','February':'2','March':'3','April':'4','May':'5','June':'6',
              'July':'7','August':'8','September':'9','October':'10','November':'11','December':'12',
              'Jan':'1','Feb':'2','Mar':'3','Apr':'4','May':'5','Jun':'6',
              'Jul':'7','Aug':'8','Sep':'9','Oct':'10','Nov':'11','Dec':'12'}

def _cn_date(unlocked_str: str) -> str:
    """Convert Steam English unlock date to Chinese: 'Unlocked 4 Jun, 2018 @ 6:18am' → '2018年6月4日 06:18'"""
    # With year: Unlocked 4 Jun, 2018 @ 6:18am
    m = re.match(r'Unlocked\s+(\d+)\s+(\w+),?\s+(\d{4})\s*@\s*(\d+):(\d+)(am|pm)', unlocked_str, re.IGNORECASE)
    if m:
        day, mon, year, hour, minute, ampm = m.groups()
        h = int(hour)
        if ampm.lower() == 'pm' and h != 12: h += 12
        if ampm.lower() == 'am' and h == 12: h = 0
        return f'{year}年{_MONTHS_EN[mon]}月{day}日 {h:02d}:{minute}'
    # Without year: Unlocked 10 Jan @ 8:46pm
    m2 = re.match(r'Unlocked\s+(\d+)\s+(\w+)\s*@\s*(\d+):(\d+)(am|pm)', unlocked_str, re.IGNORECASE)
    if m2:
        day, mon, hour, minute, ampm = m2.groups()
        h = int(hour)
        if ampm.lower() == 'pm' and h != 12: h += 12
        if ampm.lower() == 'am' and h == 12: h = 0
        return f'{_MONTHS_EN[mon]}月{day}日 {h:02d}:{minute}'
    return unlocked_str


def scrape_steam_badges(steam_id: str) -> dict:
    """Scrape Steam badge page, return structured JSON with cards."""
    req = urllib.request.Request(
        f'https://steamcommunity.com/profiles/{steam_id}/badges/',
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120'}
    )
    resp = urllib.request.urlopen(req, timeout=15)
    html = resp.read().decode('utf-8', errors='replace')
    html = html.replace('&quot;', '"')

    parts = re.split(r'<div[^>]*class="badge_row is_link"[^>]*>', html)
    badges = []

    for block in parts[1:]:
        b = {}

        link_m = re.search(r'href="[^"]*?(/badges/|/gamecards/)(\d+)/?"', block)
        if not link_m:
            continue
        if link_m.group(1) == '/gamecards/':
            b['type'] = 'game'
            b['appid'] = int(link_m.group(2))
        else:
            b['type'] = 'community'
            b['badge_id'] = int(link_m.group(2))

        # Name
        name_m = re.search(r'class="badge_title"[^>]*>(.+?)(?:</div>|<span)', block, re.DOTALL)
        if name_m:
            name = re.sub(r'&nbsp;|<[^>]+>', '', name_m.group(1)).strip()
            name = re.sub(r'View\s+details', '', name, flags=re.IGNORECASE).strip()
            b['name'] = name

        # Icon — match data-delayed-image that contains .png (not the group name)
        for m in re.finditer(r'data-delayed-image="([^"]+)"', block):
            url = m.group(1)
            if '.png' in url or 'badges/' in url:
                b['icon'] = url
                break

        # Level name
        lvl_name_m = re.search(r'class="badge_info_title"[^>]*>(.+?)</div>', block)
        if lvl_name_m:
            b['level_name'] = re.sub(r'<[^>]+>', '', lvl_name_m.group(1)).strip()

        # Numeric level
        lvl_m = re.search(r'Level\s+(\d+)', block)
        b['level'] = int(lvl_m.group(1)) if lvl_m else 1

        # XP
        xp_m = re.search(r'(\d[\d,]*)\s+XP', block)
        b['xp'] = int(xp_m.group(1).replace(',', '')) if xp_m else 0

        # Unlock date — need re.DOTALL because date is on next line
        date_m = re.search(r'class="badge_info_unlocked"[^>]*>(.+?)</div>', block, re.DOTALL)
        if date_m:
            b['unlocked'] = _cn_date(re.sub(r'<[^>]+>', '', date_m.group(1)).strip())

        # Playtime
        pt_pat = r'(\d+(?:[.,]\d+)?)\s*hrs on record'
        pt_m = re.search(pt_pat, block)
        if pt_m:
            b['playtime'] = f'{pt_m.group(1)} 小时'

        badges.append(b)

    # Steam level
    level_m = re.search(r'friendPlayerLevelNum[^>]*>(\d+)<', html)
    if not level_m:
        level_m = re.search(r'unlocked \d+ badges.*?Steam Level:\s*(\d+)', html)
    level = int(level_m.group(1)) if level_m else None
    total_xp = sum(b['xp'] for b in badges)

    return {
        'steam_id': steam_id,
        'level': level,
        'total_xp': total_xp,
        'badge_count': len(badges),
        'community_badges': sum(1 for b in badges if b.get('type') == 'community'),
        'game_badges': sum(1 for b in badges if b.get('type') == 'game'),
        'badges': badges,
    }


def scrape_game_cards(steam_id: str, appid: int) -> dict:
    """Scrape gamecards page for card images and foil badge info."""
    try:
        req = urllib.request.Request(
            f'https://steamcommunity.com/profiles/{steam_id}/gamecards/{appid}/',
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120'}
        )
        resp = urllib.request.urlopen(req, timeout=15)
        html = resp.read().decode('utf-8', errors='replace')

        cards = []
        # Card images: economy/image (trading cards) + items/ (game assets) + community_assets
        for m in re.finditer(r'https://[^\"<>\s]+(?:economy/image|public/images/items|community_assets/images/items)[^\"<>\s]+', html):
            url = m.group(0)
            if url not in cards:
                cards.append(url)
        # Foil badge icon via data-delayed-image
        if not cards:
            for m in re.finditer(r'data-delayed-image="(https://[^"]+\.(?:png|jpg)[^"]*)"', html):
                url = m.group(1)
                if url not in cards:
                    cards.append(url)

        # Foil badge — the highest level badge
        foil_icon = None
        foil_name = None
        foil_m = re.search(r'class="badge_icon"[^>]*data-delayed-image="([^"]+)"', html)
        if foil_m:
            foil_icon = foil_m.group(1)
        foil_name_m = re.search(r'class="badge_name"[^>]*>(.+?)</div>', html)
        if foil_name_m:
            foil_name = re.sub(r'<[^>]+>', '', foil_name_m.group(1)).strip()

        # How to earn cards
        earn_m = re.search(r'class="gamecards_instruct_box"[^>]*>(.+?)</div>', html, re.DOTALL)
        earn_text = re.sub(r'<[^>]+>', '', earn_m.group(1)).strip() if earn_m else ''

        return {
            'cards': cards,
            'foil_icon': foil_icon,
            'foil_name': foil_name,
            'earn_text': earn_text,
        }
    except Exception as e:
        return {'cards': [], 'error': str(e)}


def scrape_all(steam_id: str, with_cards: bool = True, max_card_games: int = 10) -> dict:
    """Scrape badges + optional card images for game badges."""
    result = scrape_steam_badges(steam_id)

    if with_cards:
        game_badges = [b for b in result['badges'] if b.get('type') == 'game']
        # Limit to avoid too many requests
        for i, b in enumerate(game_badges[:max_card_games]):
            appid = b.get('appid')
            if appid:
                time.sleep(0.5)  # Be polite
                cards = scrape_game_cards(steam_id, appid)
                b['cards'] = cards.get('cards', [])
                b['foil_icon'] = cards.get('foil_icon')
                b['foil_name'] = cards.get('foil_name')
                b['earn_text'] = cards.get('earn_text')

    # Add Chinese translations
    for b in result['badges']:
        b['name_zh'] = _zh(b.get('name', ''))
        desc = _zh_desc(b.get('name', ''))
        if desc:
            b['desc_zh'] = desc

    return result


if __name__ == '__main__':
    import sys
    sid = sys.argv[1] if len(sys.argv) > 1 else '76561198206837309'
    with_cards = '--no-cards' not in sys.argv
    result = scrape_all(sid, with_cards=with_cards)
    print(json.dumps(result, indent=2, ensure_ascii=False))
