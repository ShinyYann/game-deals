#!/usr/bin/env python3
"""Steam badge scraper — parses steamcommunity.com/profiles/{id}/badges/ page"""

import urllib.request
import urllib.error
import re
import json


def scrape_steam_badges(steam_id: str) -> dict:
    """Scrape Steam badge page, return structured JSON."""
    req = urllib.request.Request(
        f'https://steamcommunity.com/profiles/{steam_id}/badges/',
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120'}
    )
    resp = urllib.request.urlopen(req, timeout=15)
    html = resp.read().decode('utf-8', errors='replace')
    html = html.replace('&quot;', '"')  # Steam uses &quot; in attribute values

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

        # Name — strip View details and &nbsp;
        name_m = re.search(r'class="badge_title"[^>]*>(.+?)(?:</div>|<span)', block, re.DOTALL)
        if name_m:
            name = re.sub(r'&nbsp;|<[^>]+>', '', name_m.group(1)).strip()
            name = re.sub(r'View\s+details', '', name, flags=re.IGNORECASE).strip()
            b['name'] = name

        # Icon (real URL from data-delayed-image, fallback to img src)
        icon_m = re.search(r'data-delayed-image="([^"]+)"', block)
        if not icon_m:
            icon_m = re.search(r'<img[^>]+src="(https://[^"]+)"', block)
        if icon_m:
            url = icon_m.group(1)
            if 'trans.gif' not in url:
                b['icon'] = url

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

        # Unlock date
        date_m = re.search(r'class="badge_info_unlocked"[^>]*>(.+?)</div>', block)
        if date_m:
            b['unlocked'] = re.sub(r'<[^>]+>', '', date_m.group(1)).strip()

        # Playtime
        pt_m = re.search(r'hrs on record', block)
        if pt_m:
            # Extract "XX hrs on record" with possible leading text
            ctx = block[max(0,pt_m.start()-30):pt_m.end()]
            pt_match = re.search(r'(\d+(?:[.,]\d+)?)\s*hrs on record', ctx)
            if pt_match:
                b['playtime'] = pt_match.group(1) + ' hrs on record'

        badges.append(b)

    # Steam level
    # Steam level — multiple patterns to try
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


if __name__ == '__main__':
    import sys
    sid = sys.argv[1] if len(sys.argv) > 1 else '76561198206837309'
    result = scrape_steam_badges(sid)
    print(json.dumps(result, indent=2, ensure_ascii=False))
