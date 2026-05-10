#!/usr/bin/env python3
"""
pokemon_server.py — 宝可梦殿堂 HTTP 服务器
纯 Python 标准库，无需 Flask 等外部依赖
"""

import json
import os
import sys
import time
import re
import html
import threading
from datetime import datetime, timedelta
from pathlib import Path
from urllib.parse import urlparse, parse_qs, unquote
from http.server import HTTPServer, BaseHTTPRequestHandler
import socketserver

# ─── 配置 ───────────────────────────────────────────────

CONFIG = {
    "port": 8767,
    "host": "0.0.0.0",
    "cache_dir": "/var/www/html/api/pokemon_data",
    "api_base": "https://wiki.52poke.com/api.php",
    "request_delay": 0.6,
}

CACHE_TTL = {
    "pokedex": 86400,       # 图鉴: 24小时
    "proxy": 28800,         # 页面代理: 8小时
}

# 确保缓存目录存在
Path(CONFIG["cache_dir"]).mkdir(parents=True, exist_ok=True)

# ─── HTTP Session ──────────────────────────────────────

import requests as reqs
import ssl

last_request_time = 0
request_lock = threading.Lock()

# 禁用 SSL 警告
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def api_call(params):
    """带限速的 MediaWiki API 调用"""
    global last_request_time
    with request_lock:
        now = time.time()
        elapsed = now - last_request_time
        if elapsed < CONFIG["request_delay"]:
            time.sleep(CONFIG["request_delay"] - elapsed)
        
        params["format"] = "json"
        
        try:
            resp = reqs.get(
                CONFIG["api_base"],
                params=params,
                timeout=30,
                headers={"User-Agent": "TrophyRoom/1.0 (Pokedex Spider)"},
                verify=False
            )
            last_request_time = time.time()
            return resp.json()
        except Exception as e:
            print(f"  ⚠️  API 调用失败: {e}")
            return None


def get_wikitext(title):
    """获取页面的原始 wikitext"""
    data = api_call({
        "action": "parse",
        "page": title,
        "prop": "wikitext",
        "redirects": 1
    })
    if data and "parse" in data and "wikitext" in data["parse"]:
        return data["parse"]["wikitext"]["*"]
    return None


def get_category_members(category, limit=500):
    """获取分类下的所有页面"""
    members = []
    cmcontinue = None
    
    while True:
        params = {
            "action": "query",
            "list": "categorymembers",
            "cmtitle": category,
            "cmlimit": min(limit, 500),
            "cmtype": "page"
        }
        if cmcontinue:
            params["cmcontinue"] = cmcontinue
        
        data = api_call(params)
        
        if data and "query" in data and "categorymembers" in data["query"]:
            members.extend(data["query"]["categorymembers"])
        
        if data and "continue" in data and "cmcontinue" in data.get("continue", {}):
            cmcontinue = data["continue"]["cmcontinue"]
        else:
            break
        
        time.sleep(CONFIG["request_delay"])
    
    return members


# ─── 模板解析 ──────────────────────────────────────────

def strip_wiki_markup(text):
    """去除 wiki 标记，保留纯文本"""
    if not text:
        return ""
    text = re.sub(r'\[\[(?:[^|\]]*\|)?([^\]]+)\]\]', r'\1', text)
    text = re.sub(r'\{\{[^}]*\}\}', '', text)
    text = re.sub(r'<ref[^>]*>.*?</ref>', '', text, flags=re.DOTALL)
    text = re.sub(r'<[^>]+>', '', text)
    text = text.replace("'''", "").replace("''", "")
    text = html.unescape(text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def parse_pokemon_template(wikitext, title):
    """从 wikitext 解析宝可梦信息框"""
    # 查找宝可梦信息框模板
    patterns = [
        r'\{\{寶可夢信息框[^}]*\n(.*?)\n\}\}',
        r'\{\{寶可夢信息框/形態[^}]*\n(.*?)\n\}\}',
    ]
    
    raw_params = {}
    for pattern in patterns:
        match = re.search(pattern, wikitext, re.DOTALL)
        if match:
            content = match.group(0)
            # 解析参数
            lines = content.split('\n')
            for line in lines:
                line = line.strip()
                if '=' in line and not line.startswith('{{') and not line.startswith('}}'):
                    eq = line.index('=')
                    key = line[:eq].strip().lstrip('|')
                    value = line[eq+1:].strip()
                    if key and not key.startswith('<!--'):
                        raw_params[key] = value
            break
    
    if not raw_params:
        return None
    
    pokemon = {
        "_source": "52poke",
        "_updated": datetime.now().isoformat(),
        "name_zh": raw_params.get("name", title),
        "name_jp": raw_params.get("jname", ""),
        "name_en": raw_params.get("enname", ""),
        "ndex": int(raw_params.get("ndex", 0)) if raw_params.get("ndex", "").isdigit() else 0,
        "type": [strip_wiki_markup(raw_params.get("type1", ""))],
        "type2": strip_wiki_markup(raw_params.get("type2", "")),
        "species": strip_wiki_markup(raw_params.get("species", "")),
        "height": raw_params.get("height", ""),
        "weight": raw_params.get("weight", ""),
        "ability1": strip_wiki_markup(raw_params.get("ability1", "")),
        "ability2": strip_wiki_markup(raw_params.get("ability2", "")),
        "ability_hidden": strip_wiki_markup(raw_params.get("abilityd", "")),
        "egg_group1": strip_wiki_markup(raw_params.get("egggroup1", "")),
        "egg_group2": strip_wiki_markup(raw_params.get("egggroup2", "")),
        "exp_yield": raw_params.get("expyield", ""),
        "catch_rate": raw_params.get("catchrate", ""),
        "lv100_exp": raw_params.get("lv100exp", ""),
        "color": strip_wiki_markup(raw_params.get("color", "")),
        "ev_hp": int(raw_params.get("evhp", 0)),
        "ev_atk": int(raw_params.get("evat", 0)),
        "ev_def": int(raw_params.get("evde", 0)),
        "ev_spatk": int(raw_params.get("evsa", 0)),
        "ev_spdef": int(raw_params.get("evsd", 0)),
        "ev_speed": int(raw_params.get("evsp", 0)),
        "gender_diff": raw_params.get("genderdiff", "") == "y",
    }
    
    return pokemon


# ─── 抓取器 ────────────────────────────────────────────

def scrape_pokemon_list():
    """获取所有宝可梦页面名称（从世代分类爬取）"""
    print("📋 获取宝可梦列表...", flush=True)
    
    gen_cats = ["第一世代寶可夢", "第二世代寶可夢", "第三世代寶可夢", 
                "第四世代寶可夢", "第五世代寶可夢", "第六世代寶可夢",
                "第七世代寶可夢", "第八世代寶可夢", "第九世代寶可夢"]
    
    all_pokemon = []
    for gen in gen_cats:
        members = get_category_members(f"Category:{gen}")
        names = [m["title"] for m in members if m.get("ns") == 0]
        all_pokemon.extend(names)
        print(f"  {gen}: {len(names)} 只", flush=True)
        time.sleep(CONFIG["request_delay"])
    
    # 去重并检查
    all_pokemon = list(dict.fromkeys(all_pokemon))
    print(f"  ✅ 总计 {len(all_pokemon)} 只宝可梦", flush=True)
    return all_pokemon


def build_pokedex(pokemon_names=None):
    """全量抓取宝可梦数据"""
    if not pokemon_names:
        pokemon_names = scrape_pokemon_list()
    
    pokedex = {}
    errors = []
    
    for i, name in enumerate(pokemon_names):
        print(f"  [{i+1}/{len(pokemon_names)}] {name}...", end=" ", flush=True)
        try:
            wt = get_wikitext(name)
            if wt:
                data = parse_pokemon_template(wt, name)
                if data and data["ndex"] > 0:
                    pokedex[data["ndex"]] = data
                    print(f"✅ #{data['ndex']}", flush=True)
                elif data:
                    pokedex[hash(name) % 100000] = data
                    print(f"✅ (无编号)", flush=True)
                else:
                    print(f"⚠️  解析失败", flush=True)
                    errors.append(name)
            else:
                print(f"❌ 无页面", flush=True)
                errors.append(name)
        except Exception as e:
            print(f"❌ {e}", flush=True)
            errors.append(name)
        
        time.sleep(CONFIG["request_delay"])
    
    # 按编号排序
    sorted_pokedex = dict(sorted(pokedex.items()))
    
    print(f"\n✅ 完成: {len(sorted_pokedex)} 只, {len(errors)} 只失败")
    if errors:
        print(f"   失败样例: {', '.join(errors[:10])}")
    
    return sorted_pokedex


def save_pokedex(pokedex):
    """保存图鉴 JSON"""
    output = {
        "meta": {
            "source": "52poke",
            "updated": datetime.now().isoformat(),
            "count": len(pokedex)
        },
        "pokemon": list(pokedex.values())
    }
    
    path = Path(CONFIG["cache_dir"]) / "pokedex.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    
    print(f"💾 已保存: {path} ({len(pokedex)} 只)")
    return str(path)


# ─── 缓存工具 ──────────────────────────────────────────

def read_cache(name, ttl=None):
    """读取缓存"""
    path = Path(CONFIG["cache_dir"]) / f"{name}.json"
    if not path.exists():
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if ttl and "meta" in data and "updated" in data.get("meta", {}):
            updated = datetime.fromisoformat(data["meta"]["updated"])
            if datetime.now() - updated > timedelta(seconds=ttl):
                return None
        return data
    except:
        return None


def write_cache(name, data):
    """写入缓存"""
    path = Path(CONFIG["cache_dir"]) / f"{name}.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# ─── HTTP 请求处理 ─────────────────────────────────────

class PokemonHTTPHandler(BaseHTTPRequestHandler):
    """HTTP 请求处理"""
    
    def _send_json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))
    
    def _send_error(self, msg, status=400):
        self._send_json({"error": msg}, status)
    
    def _send_text(self, text, status=200, content_type="text/plain; charset=utf-8"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(text.encode("utf-8"))
    
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
    
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        params = parse_qs(parsed.query)
        
        try:
            if path == "/" or path == "":
                self._send_json({
                    "name": "宝可梦殿堂 API",
                    "endpoints": {
                        "pokedex": "/api/poke/pokedex",
                        "pokemon_by_id": "/api/poke/pokemon/025",
                        "pokemon_by_name": "/api/poke/pokemon/name/皮卡丘",
                        "search": "/api/poke/search?q=皮卡丘",
                        "proxy": "/api/poke/wiki/皮卡丘",
                        "stats": "/api/poke/stats",
                        "trigger_build": "POST /api/poke/build-pokedex",
                    }
                })
            
            elif path == "/pokedex":
                cached = read_cache("pokedex", CACHE_TTL["pokedex"])
                if cached:
                    self._send_json(cached)
                    return
                # 从文件直接读
                pokedex_path = Path(CONFIG["cache_dir"]) / "pokedex.json"
                if pokedex_path.exists():
                    with open(pokedex_path, "r", encoding="utf-8") as f:
                        self._send_json(json.load(f))
                    return
                self._send_error("图鉴数据尚未构建，请 POST /api/build-pokedex", 503)
            
            elif path.startswith("/pokemon/name/"):
                name = unquote(path[len("/pokemon/name/"):])
                pokedex = read_cache("pokedex")
                if pokedex and "pokemon" in pokedex:
                    for p in pokedex["pokemon"]:
                        if p.get("name_zh") == name or p.get("name_en", "").lower() == name.lower():
                            self._send_json(p)
                            return
                self._send_error(f"未找到: {name}", 404)
            
            elif path.startswith("/pokemon/"):
                poke_id_str = path[len("/pokemon/"):]
                try:
                    poke_id = int(poke_id_str)
                except:
                    self._send_error(f"无效编号: {poke_id_str}", 400)
                    return
                pokedex = read_cache("pokedex")
                if pokedex and "pokemon" in pokedex:
                    for p in pokedex["pokemon"]:
                        if p.get("ndex") == poke_id:
                            self._send_json(p)
                            return
                self._send_error(f"未找到 #{poke_id}", 404)
            
            elif path == "/search":
                q = params.get("q", [None])[0]
                if not q:
                    self._send_error("需要 q 参数")
                    return
                results = search_pages(q)
                self._send_json({"query": q, "results": results})
            
            elif path.startswith("/wiki/"):
                page = unquote(path[len("/wiki/"):])
                cache_name = f"wiki_{page.replace('/', '_')}"
                cached = read_cache(cache_name, CACHE_TTL["proxy"])
                if cached:
                    self._send_json(cached)
                    return
                content = fetch_page_content(page)
                if content:
                    write_cache(cache_name, content)
                    self._send_json(content)
                else:
                    self._send_error(f"页面不存在: {page}", 404)
            
            elif path == "/generations":
                self._send_json(get_generations_data())
            
            elif path == "/stats":
                self._send_json(get_stats_data())
            
            else:
                self._send_error(f"未知路径: {path}", 404)
        
        except Exception as e:
            print(f"❌ 请求错误: {e}")
            self._send_error(f"服务器错误: {str(e)}", 500)
    
    def do_POST(self):
        path = self.path.rstrip("/")
        
        if path == "/build-pokedex":
            # 测试模式: 抓取30只
            test_names = ["妙蛙种子", "妙蛙草", "妙蛙花", "小火龙", "火恐龙", "喷火龙",
                          "杰尼龟", "卡咪龟", "水箭龟", "绿毛虫", "铁甲蛹", "巴大蝶",
                          "独角虫", "铁壳蛹", "大针蜂", "波波", "比比鸟", "大比鸟",
                          "小拉达", "拉达", "烈雀", "大嘴雀", "阿柏蛇", "阿柏怪",
                          "皮卡丘", "雷丘", "穿山鼠", "穿山王", "尼多兰", "尼多娜",
                          "皮皮", "皮可西", "六尾", "九尾"]
            self._send_json({"status": "building", "count": len(test_names), "message": "开始构建测试图鉴..."})
            
            # 在后台线程跑
            import threading as t
            def build():
                pokedex = build_pokedex(test_names)
                save_pokedex(pokedex)
            t.Thread(target=build, daemon=True).start()
        
        elif path == "/build-full-pokedex":
            self._send_json({"status": "started", "message": "全量构建已启动，耗时约15分钟"})
            import threading as t
            def build():
                names = scrape_pokemon_list()
                pokedex = build_pokedex(names)  # 全量
                save_pokedex(pokedex)
            t.Thread(target=build, daemon=True).start()
        
        else:
            self._send_error(f"未知 POST 路径: {path}", 404)
    
    def log_message(self, format, *args):
        print(f"  [{datetime.now().strftime('%H:%M:%S')}] {args[0]} {args[1]} {args[2]}")


# ─── 辅助函数 ──────────────────────────────────────────

def search_pages(query, limit=20):
    """搜索页面"""
    data = api_call({
        "action": "query",
        "list": "search",
        "srsearch": query,
        "srlimit": limit,
        "srprop": "snippet|titlesnippet"
    })
    results = []
    if data and "query" in data and "search" in data["query"]:
        for r in data["query"]["search"]:
            results.append({
                "pageid": r["pageid"],
                "title": r["title"],
                "snippet": strip_wiki_markup(r.get("snippet", "")),
            })
    return results


def fetch_page_content(title):
    """获取页面内容"""
    wt = get_wikitext(title)
    if not wt:
        return None
    return {
        "title": title,
        "source": "52poke",
        "cached_at": datetime.now().isoformat(),
        "wikitext": wt[:50000]
    }


def get_generations_data():
    """获取世代数据"""
    index_path = Path(CONFIG["cache_dir"]) / "pokedex_index.json"
    if index_path.exists():
        with open(index_path, "r") as f:
            return json.load(f)
    return {"by_generation": {}}


def get_stats_data():
    """获取统计数据"""
    pokedex = read_cache("pokedex")
    count = len(pokedex.get("pokemon", [])) if pokedex else 0
    
    type_counts = {}
    if pokedex:
        for p in pokedex["pokemon"]:
            for t in [p.get("type", [None])[0], p.get("type2")]:
                if t:
                    type_counts[t] = type_counts.get(t, 0) + 1
    
    return {
        "pokemon_count": count,
        "by_type": type_counts,
        "cache_dir": CONFIG["cache_dir"],
    }


# ─── 启动 ───────────────────────────────────────────────

def run_server():
    """启动 HTTP 服务器"""
    server = HTTPServer((CONFIG["host"], CONFIG["port"]), PokemonHTTPHandler)
    print(f"🐉 宝可梦殿堂 API 服务器")
    print(f"   地址: http://{CONFIG['host']}:{CONFIG['port']}")
    print(f"   缓存: {CONFIG['cache_dir']}")
    print(f"   接口:")
    print(f"     GET  /api/pokedex           - 全图鉴")
    print(f"     GET  /api/pokemon/025       - 按编号查")
    print(f"     GET  /api/pokemon/name/皮卡丘 - 按名字查")
    print(f"     GET  /api/search?q=皮卡丘    - 搜索")
    print(f"     GET  /api/wiki/皮卡丘        - 页面代理")
    print(f"     GET  /api/stats             - 统计")
    print(f"     POST /api/build-pokedex     - 构建图鉴(30只测试)")
    print(f"     POST /api/build-full-pokedex - 构建全量图鉴")
    print()
    server.serve_forever()


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=CONFIG["port"])
    parser.add_argument("--host", type=str, default=CONFIG["host"])
    args = parser.parse_args()
    CONFIG["port"] = args.port
    CONFIG["host"] = args.host
    run_server()
