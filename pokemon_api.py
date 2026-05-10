#!/usr/bin/env python3
"""
pokemon_api.py — 宝可梦殿堂 API 服务器
为 Flutter App 提供数据接口
"""

import json
import os
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from functools import wraps
from urllib.parse import unquote

from flask import Flask, jsonify, request, Response
from flask_cors import CORS

# ─── 配置 ───────────────────────────────────────────────

CACHE_DIR = Path("/var/www/html/api/pokemon_data")
CACHE_DIR.mkdir(parents=True, exist_ok=True)

API_PORT = 8767
CACHE_TTL = {
    "pokedex": 86400,       # 图鉴: 24小时
    "proxy": 28800,         # 页面代理: 8小时
}

# ─── 导入爬虫模块 ──────────────────────────────────────

# 添加本地路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    import pokemon_spider as spider
    SPIDER_AVAILABLE = True
except ImportError:
    SPIDER_AVAILABLE = False
    print("⚠️  pokemon_spider 模块未找到，部分功能不可用")

# ─── Flask App ──────────────────────────────────────────

app = Flask(__name__)
CORS(app)

# ─── 缓存工具 ──────────────────────────────────────────

def read_cache(name, ttl=None):
    """读取缓存，过期返回 None"""
    path = CACHE_DIR / f"{name}.json"
    if not path.exists():
        return None
    
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        if ttl and "meta" in data and "updated" in data["meta"]:
            updated = datetime.fromisoformat(data["meta"]["updated"])
            if datetime.now() - updated > timedelta(seconds=ttl):
                return None  # 缓存过期
        
        return data
    except (json.JSONDecodeError, KeyError, ValueError):
        return None


def write_cache(name, data):
    """写入缓存"""
    path = CACHE_DIR / f"{name}.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def cache_response(name, ttl):
    """装饰器: 自动缓存 API 响应"""
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            cached = read_cache(name, ttl)
            if cached is not None:
                return jsonify(cached)
            
            result = f(*args, **kwargs)
            if isinstance(result, tuple):
                data, status = result
                if status == 200 and data:
                    write_cache(name, data.get_json() if hasattr(data, 'get_json') else data)
                return data, status
            
            if result and hasattr(result, 'get_json'):
                data = result.get_json()
                write_cache(name, data)
            
            return result
        return wrapper
    return decorator


# ─── API 路由 ──────────────────────────────────────────

@app.route("/")
def index():
    """API 首页"""
    return jsonify({
        "name": "宝可梦殿堂 API",
        "version": "1.0.0",
        "endpoints": {
            "pokedex": "/api/pokedex - 全图鉴",
            "pokemon_by_id": "/api/pokemon/<id> - 单只宝可梦",
            "pokemon_by_name": "/api/pokemon/name/<name> - 按名字查",
            "search": "/api/search?q=<query> - 搜索页面",
            "proxy": "/api/wiki/<page> - 52poke 页面代理",
            "stats": "/api/stats - 统计信息",
        }
    })


@app.route("/api/pokedex")
def get_pokedex():
    """获取全图鉴"""
    cached = read_cache("pokedex", CACHE_TTL["pokedex"])
    if cached:
        return jsonify(cached)
    
    # 尝试从文件加载
    pokedex_path = CACHE_DIR / "pokedex.json"
    if pokedex_path.exists():
        with open(pokedex_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return jsonify(data)
    
    return jsonify({"error": "图鉴数据尚未构建", "meta": {"count": 0}}), 503


@app.route("/api/pokemon/<int:poke_id>")
def get_pokemon_by_id(poke_id):
    """按全国编号查询宝可梦"""
    pokedex = read_cache("pokedex", CACHE_TTL["pokedex"])
    
    if pokedex and "pokemon" in pokedex:
        for p in pokedex["pokemon"]:
            if p.get("ndex") == poke_id:
                return jsonify(p)
    
    # 尝试从文件
    pokedex_path = CACHE_DIR / "pokedex.json"
    if pokedex_path.exists():
        with open(pokedex_path, "r", encoding="utf-8") as f:
            pokedex = json.load(f)
        for p in pokedex.get("pokemon", []):
            if p.get("ndex") == poke_id:
                return jsonify(p)
    
    return jsonify({"error": f"未找到 #{poke_id}"}), 404


@app.route("/api/pokemon/name/<name>")
def get_pokemon_by_name(name):
    """按名字查询宝可梦"""
    name = unquote(name)
    pokedex = read_cache("pokedex", CACHE_TTL["pokedex"])
    
    if pokedex and "pokemon" in pokedex:
        for p in pokedex["pokemon"]:
            if p.get("name_zh") == name or p.get("name_en", "").lower() == name.lower():
                return jsonify(p)
    
    # 尝试从文件
    pokedex_path = CACHE_DIR / "pokedex.json"
    if pokedex_path.exists():
        with open(pokedex_path, "r", encoding="utf-8") as f:
            pokedex = json.load(f)
        for p in pokedex.get("pokemon", []):
            if p.get("name_zh") == name or p.get("name_en", "").lower() == name.lower():
                return jsonify(p)
    
    return jsonify({"error": f"未找到: {name}"}), 404


@app.route("/api/search")
def search():
    """搜索 52poke 页面"""
    q = request.args.get("q", "")
    if not q:
        return jsonify({"error": "需要 q 参数"}), 400
    
    if not SPIDER_AVAILABLE:
        return jsonify({"error": "爬虫模块不可用"}), 503
    
    results = spider.search_pages(q)
    return jsonify({"query": q, "results": results})


@app.route("/api/wiki/<path:page>")
def proxy_wiki(page):
    """按需代理 52poke 页面内容"""
    page = unquote(page)
    
    # 检查缓存
    cache_name = f"wiki_{page.replace('/', '_')}"
    cached = read_cache(cache_name, CACHE_TTL["proxy"])
    if cached:
        return jsonify(cached)
    
    if not SPIDER_AVAILABLE:
        return jsonify({"error": "爬虫模块不可用"}), 503
    
    content = spider.fetch_page_content(page)
    if content:
        write_cache(cache_name, content)
        return jsonify(content)
    
    return jsonify({"error": f"页面不存在: {page}"}), 404


@app.route("/api/generations")
def get_generations():
    """获取世代列表"""
    index = read_cache("pokedex_index")
    if not index:
        # 从文件加载
        index_path = CACHE_DIR / "pokedex_index.json"
        if index_path.exists():
            with open(index_path, "r", encoding="utf-8") as f:
                index = json.load(f)
    
    if index:
        return jsonify(index)
    
    return jsonify({"by_generation": {}})


@app.route("/api/stats")
def get_stats():
    """统计信息"""
    pokedex = read_cache("pokedex")
    count = len(pokedex.get("pokemon", [])) if pokedex else 0
    
    type_counts = {}
    if pokedex:
        for p in pokedex["pokemon"]:
            for t in [p.get("type", [None])[0], p.get("type2")]:
                if t:
                    type_counts[t] = type_counts.get(t, 0) + 1
    
    gen_counts = {}
    if pokedex:
        for p in pokedex["pokemon"]:
            ndex = p["ndex"]
            gen = 1
            if ndex <= 151: gen = 1
            elif ndex <= 251: gen = 2
            elif ndex <= 386: gen = 3
            elif ndex <= 493: gen = 4
            elif ndex <= 649: gen = 5
            elif ndex <= 721: gen = 6
            elif ndex <= 809: gen = 7
            elif ndex <= 898: gen = 8
            elif ndex <= 1025: gen = 9
            else: gen = 10
            gen_counts[f"第{gen}世代"] = gen_counts.get(f"第{gen}世代", 0) + 1
    
    return jsonify({
        "pokemon_count": count,
        "by_type": type_counts,
        "by_generation": gen_counts,
        "cache_dir": str(CACHE_DIR),
        "spider_available": SPIDER_AVAILABLE,
    })


@app.route("/api/build-pokedex", methods=["POST"])
def trigger_build():
    """触发图鉴重建（简单版 - 仅限30只测试）"""
    if not SPIDER_AVAILABLE:
        return jsonify({"error": "爬虫模块不可用"}), 503
    
    # 测试模式: 只抓前几只
    test_names = ["妙蛙种子", "妙蛙草", "妙蛙花", "小火龙", "火恐龙", "喷火龙",
                   "杰尼龟", "卡咪龟", "水箭龟", "绿毛虫", "铁甲蛹", "巴大蝶",
                   "独角虫", "铁壳蛹", "大针蜂", "波波", "比比鸟", "大比鸟",
                   "小拉达", "拉达", "烈雀", "大嘴雀", "阿柏蛇", "阿柏怪",
                   "皮卡丘", "雷丘", "穿山鼠", "穿山王", "尼多兰", "尼多娜",
                   "皮皮", "皮可西", "六尾", "九尾"]
    
    pokedex = spider.build_pokedex(test_names)
    path = spider.save_pokedex(pokedex)
    
    return jsonify({
        "status": "ok",
        "count": len(pokedex),
        "path": path
    })


@app.route("/api/build-full-pokedex", methods=["POST"])
def trigger_build_full():
    """触发全量图鉴构建（需要较长时间）"""
    if not SPIDER_AVAILABLE:
        return jsonify({"error": "爬虫模块不可用"}), 503
    
    # 异步启动
    import threading
    def build_task():
        names = spider.scrape_pokemon_list()
        pokedex = spider.build_pokedex(names)
        spider.save_pokedex(pokedex)
    
    thread = threading.Thread(target=build_task, daemon=True)
    thread.start()
    
    return jsonify({
        "status": "started",
        "message": "全量图鉴构建已启动，请稍后查看 /api/stats"
    })


# ─── 启动 ───────────────────────────────────────────────

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="宝可梦殿堂 API 服务器")
    parser.add_argument("--port", type=int, default=API_PORT, help=f"端口 (默认: {API_PORT})")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="监听地址")
    parser.add_argument("--debug", action="store_true", help="调试模式")
    
    args = parser.parse_args()
    
    print(f"🐉 宝可梦殿堂 API 启动")
    print(f"   端口: {args.port}")
    print(f"   缓存: {CACHE_DIR}")
    print(f"   爬虫: {'✅' if SPIDER_AVAILABLE else '❌ 未找到'}")
    
    app.run(host=args.host, port=args.port, debug=args.debug)
