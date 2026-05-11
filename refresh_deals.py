#!/usr/bin/env python3
"""Refresh deals page - replace discount data from server JSON, keep everything else"""
import json, re, os, requests as req
from datetime import datetime

SERVER = "http://8.153.97.56/deals"
PAGE = os.path.expanduser("~/.openclaw/workspace/game-deals/docs/index.html")
HEADERS = {"User-Agent": "Mozilla/5.0"}

def fetch(platform):
    try:
        r = req.get(f"{SERVER}/{platform}_deals.json", headers=HEADERS, timeout=10)
        return r.json().get("deals",[])
    except: return []

def make_cards(deals, top=False):
    """Generate game-card HTML blocks matching existing page format"""
    cards = []
    for i, d in enumerate(deals):
        raw = d.get("name","?")
        name_cn = d.get("name_cn","")
        name = (name_cn if name_cn and name_cn != raw else raw).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
        
        # Normalize server format - handle both old and new
        # discount: could be int (40) or string ("-40%")
        di_raw = d.get("discount","")
        if isinstance(di_raw, int):
            di = f"-{di_raw}%"
            pct = di_raw
        elif isinstance(di_raw, str):
            di = di_raw
            m = re.search(r"(\d+)", di)
            pct = int(m.group(1)) if m else 0
        else:
            di = ""
            pct = 0
        
        # price: server uses final_formatted, old data uses current_price
        cp = str(d.get("current_price") or d.get("final_formatted") or d.get("price") or "")
        
        # image: server stores in header_image or image, or construct from appid
        img = str(d.get("image") or d.get("header_image") or "")
        if not img and d.get("appid"):
            img = f"https://steamcdn-a.akamaihd.net/steam/apps/{d['appid']}/header.jpg"
        
        dc = "disc-high" if pct >= 70 else ("disc-mid" if pct >= 40 else "disc-low")
        
        if top:
            medals = ["🥇","🥈","🥉","4️⃣","5️⃣","6️⃣"]
            ci = i + 1
            cr = f'<div class="crown crown-{ci}">{medals[ci-1] if ci <=3 else ""}</div>'
        else:
            cr = ""
        
        first_style = ' style="cursor:pointer;display:block"' if (top and i == 0) else ' style="cursor:pointer"'
        cards.append(f'''<div class="game-card" onclick="showGameModal(this)"{first_style}>
                <div class="game-card-inner">
                    <div class="card-left">{cr}<img src="{img}" class="game-thumb" onerror="this.parentElement.style.display=\'none\'"></div>
                    <div class="card-right">
                        <div class="card-header">
                            <span class="game-name">{name}</span>
                            <span class="discount-badge {dc}">{di}</span>
                        </div>
                        <div class="card-price">
                            <span class="current-price">{cp}</span>
                        </div>
                        <div class="card-rating"></div>
                    </div>
                </div>
            </div>''')
    return "\n".join(cards)

def section(sid, title, deals, top=False):
    if not deals:
        return ""
    style = ' style="display:block"' if sid == "disc-top5" else ""
    cards = make_cards(deals, top=top)
    return f'<div id="{sid}" class="disc-section"{style}><section class="platform"><h2>{title}</h2><div class="game-list">{cards}</div></section></div>'

# Fetch
steam = fetch("steam")
psn = fetch("psn_hk")
switch = fetch("nintendo_s")
all_ = steam + psn + switch
print(f"Steam={len(steam)} PSN={len(psn)} Switch={len(switch)}")

# Top 6
def ds(d):
    di = d.get("discount",0)
    if isinstance(di, int):
        return di
    m = re.search(r"(\d+)", str(di))
    return int(m.group(1)) if m else 0
top = sorted(all_, key=ds, reverse=True)[:6]

new_secs = {
    "disc-top5": section("disc-top5", "🎯 本期值得买", top, top=True),
    "disc-psn": section("disc-psn", "🔵 PSN 港服特惠", psn),
    "disc-steam": section("disc-steam", "🟢 Steam 国服特惠", steam[:100]),
    "disc-switch": section("disc-switch", "🔴 Switch 港服折扣", switch[:100]),
}

with open(PAGE, encoding="utf-8") as f:
    html = f.read()

changed = 0
for sid, new_content in new_secs.items():
    if not new_content:
        continue
    
    if sid == "disc-switch":
        # Check if section div exists
        section_exists = bool(re.search(
            r'<div id="' + re.escape(sid) + r'"[^>]*>',
            html))
        
        if section_exists:
            html = re.sub(
                r'<div id="' + re.escape(sid) + r'"[^>]*>.*?</section></div>',
                new_content, html, count=1, flags=re.DOTALL
            )
            changed += 1
            print(f"  Replaced #{sid}")
        else:
            # Insert before p9low
            html = re.sub(
                r'(<div id="disc-p9low")',
                new_content + "\n" + r'\1',
                html, count=1
            )
            changed += 1
            print(f"  Inserted #{sid}")
    else:
        html = re.sub(
            r'<div id="' + re.escape(sid) + r'"[^>]*>.*?</section></div>',
            new_content, html, count=1, flags=re.DOTALL
        )
        changed += 1
        print(f"  Replaced #{sid}")

# Update timestamp
now = datetime.now().strftime("%Y-%m-%d %H:%M")
html = re.sub(r'上次更新: [\d-]+ [\d:]+', f'上次更新: {now}', html)

with open(PAGE, "w", encoding="utf-8") as f:
    f.write(html)

print(f"\n✅ Done! {changed} sections, {len(all_)} deals total")
print(f"Steam: {len(steam)} | PSN: {len(psn)} | Switch: {len(switch)}")
