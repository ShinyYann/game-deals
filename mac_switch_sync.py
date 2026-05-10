#!/usr/bin/env python3
"""Mac 端小黑盒 Switch 数据同步脚本
Mac IP 不受 WAF 拦截 → 抓取 → SCP 推送服务器
用法: python3 mac_switch_sync.py [userid1] [userid2] ...
默认 userid: 89026038
"""

import json, urllib.request, os, subprocess, sys

SERVER = "root@8.153.97.56"
REMOTE_CACHE = "/root/switch_cache.json"
BASE = "https://api.xiaoheihe.cn"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36",
    "Referer": "https://www.xiaoheihe.cn/",
}

userids = sys.argv[1:] if len(sys.argv) > 1 else ["89026038"]

def fetch_account(uid: str) -> dict:
    """Fetch account data + all games for a userid."""
    # 1. account data
    req = urllib.request.Request(f"{BASE}/game/switch/jp/account/data?userid={uid}", headers=HEADERS)
    acc = json.loads(urllib.request.urlopen(req, timeout=15).read())
    if acc.get("status") != "ok":
        raise Exception(f"Account API failed for {uid}: {acc.get('msg', acc)}")

    # 2. paginated games
    all_games, offset, limit = [], 0, 12
    while True:
        req2 = urllib.request.Request(
            f"{BASE}/game/switch/jp/games/data?userid={uid}&offset={offset}&limit={limit}",
            headers=HEADERS,
        )
        gdata = json.loads(urllib.request.urlopen(req2, timeout=15).read())
        if gdata.get("status") != "ok":
            break
        page = gdata["result"].get("games", [])
        if not page:
            break
        all_games.extend(page)
        offset += limit
        if len(page) < limit:
            break

    result = acc["result"]
    ui = result.get("user_info", {})
    # Also store userid in user_info for fuzzy matching
    ui["userid"] = uid
    return {
        "account_id": uid,
        "user_info": ui,
        "games": all_games,
        "total_game_price": result.get("total_game_price", "0"),
        "region_name": result.get("region_name", ""),
    }


def main():
    cache = {}
    for uid in userids:
        uid = uid.strip()
        if not uid:
            continue
        print(f"📡 Fetching {uid}...")
        try:
            data = fetch_account(uid)
            cache[uid] = data
            g = len(data["games"])
            h = sum(float(g.get("played_time", 0)) for g in data["games"])
            print(f"   ✅ {g} games, {h:.0f}h, ¥{data['total_game_price']}")
        except Exception as e:
            print(f"   ❌ {e}")
            continue

    if not cache:
        print("No data fetched, aborting.")
        sys.exit(1)

    # Save locally
    local = "/tmp/switch_cache.json"
    with open(local, "w") as f:
        json.dump(cache, f, ensure_ascii=False)
    print(f"💾 Saved {local} ({os.path.getsize(local)} bytes)")

    # SCP to server
    print(f"📤 Uploading to {SERVER}...")
    r = subprocess.run(
        ["scp", local, f"{SERVER}:{REMOTE_CACHE}"],
        capture_output=True, text=True, timeout=30,
    )
    if r.returncode == 0:
        print("   ✅ Server updated")
    else:
        print(f"   ❌ SCP failed: {r.stderr}")


if __name__ == "__main__":
    main()
