#!/usr/bin/env python3
"""
pokemon_spider.py — 52poke 百科爬虫
从 MediaWiki API 抓取结构化和非结构化数据，缓存到 JSON 文件
"""

import json
import os
import sys
import time
import re
import html
from datetime import datetime
from pathlib import Path

import requests

# ─── 配置 ───────────────────────────────────────────────

API_BASE = "https://wiki.52poke.com/api.php"
CACHE_DIR = Path("/var/www/html/api/pokemon_data")
CACHE_DIR.mkdir(parents=True, exist_ok=True)

HEADERS = {
    "User-Agent": "TrophyRoom/1.0 (宝可梦殿堂数据爬虫; +https://github.com/ShinyYann/trophyroom)"
}

# robots.txt: Crawl-delay: 500ms → 每秒最多2请求
REQUEST_DELAY = 0.6

# ─── MediaWiki API 工具 ────────────────────────────────

session = requests.Session()
session.headers.update(HEADERS)

last_request_time = 0

def api_call(params):
    """带限速的 MediaWiki API 调用"""
    global last_request_time
    now = time.time()
    elapsed = now - last_request_time
    if elapsed < REQUEST_DELAY:
        time.sleep(REQUEST_DELAY - elapsed)
    
    params["format"] = "json"
    r = session.get(API_BASE, params=params, timeout=30)
    last_request_time = time.time()
    r.raise_for_status()
    return r.json()

def get_wikitext(title):
    """获取页面的原始 wikitext"""
    data = api_call({
        "action": "parse",
        "page": title,
        "prop": "wikitext",
        "redirects": 1
    })
    if "parse" in data and "wikitext" in data["parse"]:
        return data["parse"]["wikitext"]["*"]
    return None

def get_page_html(title):
    """获取页面的渲染 HTML"""
    data = api_call({
        "action": "parse",
        "page": title,
        "prop": "text",
        "redirects": 1
    })
    if "parse" in data and "text" in data["parse"]:
        return data["parse"]["text"]["*"]
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
            "cmtype": "page|subcat"
        }
        if cmcontinue:
            params["cmcontinue"] = cmcontinue
        
        data = api_call(params)
        
        if "query" in data and "categorymembers" in data["query"]:
            members.extend(data["query"]["categorymembers"])
        
        if "continue" in data and "cmcontinue" in data.get("continue", {}):
            cmcontinue = data["continue"]["cmcontinue"]
        else:
            break
            
        time.sleep(REQUEST_DELAY)
    
    return members


# ─── 模板解析 ──────────────────────────────────────────

def parse_template(text, template_name, start=0):
    """解析模板调用 {{模板名|...}}，返回参数dict和结束位置"""
    # 找模板开始
    pattern = r'\{\{' + re.escape(template_name)
    match = re.search(pattern, text[start:])
    if not match:
        return None, -1
    
    pos = start + match.start()
    # 找匹配的 }}
    depth = 2  # 已经匹配了 {{
    i = pos + 2
    
    while i < len(text) and depth > 0:
        if text[i:i+2] == '{{':
            depth += 1
            i += 2
        elif text[i:i+2] == '}}':
            depth -= 1
            i += 2
        else:
            i += 1
    
    if depth != 0:
        return None, -1
    
    content = text[pos+2:i-2]  # 去掉 {{ 和 }}
    end_pos = i
    
    # 解析参数
    params = {}
    # 跳过模板名
    first_pipe = content.find('|')
    if first_pipe == -1:
        return {}, end_pos
    
    params['_name'] = content[:first_pipe].strip()
    param_str = content[first_pipe+1:]
    
    # 逐行解析 name=value
    lines = param_str.split('\n')
    # 先用 | 分隔 top-level 参数（处理嵌套）
    # 简单方法: 找到不在嵌套中的 |
    
    # 更健壮的方法
    parts = split_template_params(param_str)
    
    for part in parts:
        if '=' not in part:
            continue
        eq = part.index('=')
        key = part[:eq].strip()
        value = part[eq+1:].strip()
        params[key] = value
    
    return params, end_pos


def split_template_params(text):
    """在顶层 | 处分割模板参数，跳过嵌套 {{}}"""
    parts = []
    depth = 0
    current = []
    
    for ch in text:
        if ch == '{':
            depth += 1
            current.append(ch)
        elif ch == '}':
            depth = max(0, depth - 1)
            current.append(ch)
        elif ch == '|' and depth == 0:
            parts.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    
    remaining = ''.join(current).strip()
    if remaining:
        parts.append(remaining)
    
    return parts


def strip_wiki_markup(text):
    """去除 wiki 标记，保留纯文本"""
    if not text:
        return ""
    # 移除 [[link|label]] → label 或 link
    text = re.sub(r'\[\[(?:[^|\]]*\|)?([^\]]+)\]\]', r'\1', text)
    # 移除 {{template}}
    text = re.sub(r'\{\{[^}]+\}\}', '', text)
    # 移除 <ref>...</ref>
    text = re.sub(r'<ref[^>]*>.*?</ref>', '', text, flags=re.DOTALL)
    # 移除 HTML 标签
    text = re.sub(r'<[^>]+>', '', text)
    # 移除 '''bold''' 和 ''italic''
    text = text.replace("'''", "").replace("''", "")
    # 解码 HTML 实体
    text = html.unescape(text)
    # 清理多余空白
    text = re.sub(r'\s+', ' ', text).strip()
    return text


# ─── 宝可梦数据抓取 ────────────────────────────────────

def scrape_pokemon_wikitext_to_json(wikitext, title):
    """从宝可梦页面的 wikitext 提取结构化数据"""
    
    # 查找 {{寶可夢信息框/形態}} 或 {{寶可夢信息框}}
    params = None
    for tpl_name in ["寶可夢信息框/形態", "寶可夢信息框"]:
        params, _ = parse_template(wikitext, tpl_name)
        if params:
            break
    
    if not params:
        print(f"  ⚠️  未找到信息框: {title}")
        return None
    
    # 基础数据
    pokemon = {
        "_source": "52poke",
        "_updated": datetime.now().isoformat(),
        "name_zh": params.get("name", title),
        "name_jp": params.get("jname", ""),
        "name_en": params.get("enname", ""),
        "ndex": int(params.get("ndex", 0)) if params.get("ndex", "").isdigit() else 0,
        "type": [params.get("type1", "")],
        "type2": params.get("type2", ""),
        "species": strip_wiki_markup(params.get("species", "")),
        "height": params.get("height", ""),
        "weight": params.get("weight", ""),
        "ability1": strip_wiki_markup(params.get("ability1", "")),
        "ability2": strip_wiki_markup(params.get("ability2", "")),
        "ability_hidden": strip_wiki_markup(params.get("abilityd", "")),
        "gender_ratio_code": params.get("gendercode", ""),
        "egg_group1": strip_wiki_markup(params.get("egggroup1", "")),
        "egg_group2": strip_wiki_markup(params.get("egggroup2", "")),
        "egg_cycles": params.get("eggcycles", ""),
        "exp_yield": params.get("expyield", ""),
        "catch_rate": params.get("catchrate", ""),
        "lv100_exp": params.get("lv100exp", ""),
        "color": strip_wiki_markup(params.get("color", "")),
        "body_style": params.get("body", ""),
        "ev_hp": int(params.get("evhp", 0)),
        "ev_atk": int(params.get("evat", 0)),
        "ev_def": int(params.get("evde", 0)),
        "ev_spatk": int(params.get("evsa", 0)),
        "ev_spdef": int(params.get("evsd", 0)),
        "ev_speed": int(params.get("evsp", 0)),
        "gender_diff": params.get("genderdiff", "") == "y",
        "forms": [],
    }
    
    # 收集形态
    form_count = 0
    for key in params:
        if key.startswith("form") and key.replace("form", "").isdigit():
            form_idx = key.replace("form", "")
            if form_idx:
                form_count = max(form_count, int(form_idx))
    
    if form_count > 0:
        for i in range(1, form_count + 1):
            form_name = params.get(f"form{i}", "")
            if form_name:
                form = {
                    "name": strip_wiki_markup(form_name),
                    "type1": strip_wiki_markup(params.get(f"type1-{i}", params.get("type1", ""))),
                    "type2": strip_wiki_markup(params.get(f"type2-{i}", params.get("type2", ""))),
                    "ability1": strip_wiki_markup(params.get(f"ability1-{i}", "")),
                    "ability2": strip_wiki_markup(params.get(f"ability2-{i}", "")),
                    "ability_hidden": strip_wiki_markup(params.get(f"abilityd{i}", "")),
                    "height": params.get(f"height{i}", ""),
                    "weight": params.get(f"weight{i}", ""),
                }
                pokemon["forms"].append(form)
    
    return pokemon


def scrape_pokemon_list():
    """获取所有宝可梦列表"""
    print("📋 获取宝可梦列表...")
    
    # 从简单列表页获取
    # 尝试从列表页获取
    members = get_category_members("Category:宝可梦")
    
    # 过滤出实际的宝可梦页面（排除分类和列表页）
    pokemon_pages = []
    for m in members:
        title = m["title"]
        # 排除分类和列表页
        if m.get("ns", 0) != 0:
            continue
        if "列表" in title or "Category" in title:
            continue
        
        # 单字或两字的中文名一般是宝可梦
        if re.match(r'^[\u4e00-\u9fff]{1,6}$', title):
            pokemon_pages.append(title)
    
    # 如果不够全，从宝可梦列表（按全国图鉴编号）获取
    if len(pokemon_pages) < 100:
        print("  ⚠️  直接从Category不够全，尝试从列表页获取...")
        list_wikitext = get_wikitext("宝可梦列表（按全国图鉴编号）/简单版")
        if list_wikitext:
            # 找所有宝可梦链接
            links = re.findall(r'\[\[([^|\]]+)(?:\|[^\]]+)?\]\]', list_wikitext)
            pokemon_pages = list(dict.fromkeys(links))  # 去重保持顺序
    
    print(f"  ✅ 找到 {len(pokemon_pages)} 只宝可梦")
    return pokemon_pages


def build_pokedex(pokemon_names=None):
    """全量抓取所有宝可梦数据"""
    if not pokemon_names:
        pokemon_names = scrape_pokemon_list()
    
    pokedex = {}
    errors = []
    
    for i, name in enumerate(pokemon_names):
        print(f"  [{i+1}/{len(pokemon_names)}] {name}...", end=" ", flush=True)
        try:
            wt = get_wikitext(name)
            if wt:
                data = scrape_pokemon_wikitext_to_json(wt, name)
                if data and data["ndex"] > 0:
                    pokedex[data["ndex"]] = data
                    print(f"✅ #{data['ndex']}", flush=True)
                elif data:
                    pokedex[name] = data
                    print(f"✅ (无编号)", flush=True)
                else:
                    print(f"⚠️  解析失败", flush=True)
                    errors.append(name)
            else:
                print(f"❌ 页面不存在", flush=True)
                errors.append(name)
        except Exception as e:
            print(f"❌ {e}", flush=True)
            errors.append(name)
        
        time.sleep(REQUEST_DELAY)
    
    # 按编号排序
    sorted_pokedex = dict(sorted(pokedex.items()))
    
    print(f"\n✅ 完成: {len(sorted_pokedex)} 只成功, {len(errors)} 只失败")
    if errors:
        print(f"   失败: {', '.join(errors[:20])}")
    
    return sorted_pokedex


def save_pokedex(pokedex):
    """保存到 JSON 文件"""
    output = {
        "meta": {
            "source": "52poke",
            "updated": datetime.now().isoformat(),
            "count": len(pokedex)
        },
        "pokemon": list(pokedex.values())
    }
    
    path = CACHE_DIR / "pokedex.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    
    print(f"💾 已保存: {path} ({len(pokedex)} 只)")
    
    # 也保存按世代分的索引
    by_gen = {}
    for p in pokedex.values():
        ndex = p["ndex"]
        if ndex <= 151:
            gen = 1
        elif ndex <= 251:
            gen = 2
        elif ndex <= 386:
            gen = 3
        elif ndex <= 493:
            gen = 4
        elif ndex <= 649:
            gen = 5
        elif ndex <= 721:
            gen = 6
        elif ndex <= 809:
            gen = 7
        elif ndex <= 898:
            gen = 8
        elif ndex <= 1025:
            gen = 9
        else:
            gen = 10
        
        by_gen.setdefault(gen, []).append(ndex)
    
    index_path = CACHE_DIR / "pokedex_index.json"
    with open(index_path, "w", encoding="utf-8") as f:
        json.dump({"by_generation": {str(k): v for k, v in sorted(by_gen.items())}}, f, ensure_ascii=False)
    
    return str(path)


# ─── 按需页面代理 ──────────────────────────────────────

def fetch_page_content(title):
    """获取页面内容（按需代理用）"""
    data = get_wikitext(title)
    if not data:
        return None
    
    return {
        "title": title,
        "source": "52poke",
        "cached_at": datetime.now().isoformat(),
        "wikitext": data[:50000]  # 限制大小
    }


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
    if "query" in data and "search" in data["query"]:
        for r in data["query"]["search"]:
            results.append({
                "pageid": r["pageid"],
                "title": r["title"],
                "snippet": strip_wiki_markup(r.get("snippet", "")),
            })
    
    return results


# ─── 主入口 ─────────────────────────────────────────────

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="52poke 百科爬虫")
    parser.add_argument("--build-pokedex", action="store_true", help="全量抓取宝可梦图鉴")
    parser.add_argument("--search", type=str, help="搜索页面")
    parser.add_argument("--page", type=str, help="获取页面内容")
    parser.add_argument("--limit", type=int, default=20, help="搜索结果数量")
    parser.add_argument("--delay", type=float, default=0.6, help="请求间隔(秒)")
    
    args = parser.parse_args()
    
    if args.delay:
        REQUEST_DELAY = args.delay
    
    if args.build_pokedex:
        print("=== 🐉 宝可梦图鉴全量抓取 ===")
        pokedex = build_pokedex()
        save_pokedex(pokedex)
    
    elif args.search:
        print(f"搜索: {args.search}")
        results = search_pages(args.search, args.limit)
        for r in results:
            print(f"  [{r['pageid']}] {r['title']}: {r['snippet'][:100]}")
    
    elif args.page:
        print(f"获取页面: {args.page}")
        content = fetch_page_content(args.page)
        if content:
            print(json.dumps(content, ensure_ascii=False, indent=2)[:2000])
        else:
            print("❌ 页面不存在")
    
    else:
        parser.print_help()
