#!/usr/bin/env python3
"""PSN 折扣全量抓取 — 使用 Playwright 模拟浏览器"""

import os
import json
import asyncio
import time
import re
import hashlib
from playwright.async_api import async_playwright

CATEGORIES = {
    "all_ps5_discounts": "PS5",
    "all_ps4_discounts": "PS4",
}

async def fetch_psn_deals(browser):
    """抓取全部 PSN 折扣"""
    all_games = []
    seen_ids = set()
    
    for category, platform in CATEGORIES.items():
        page_num = 0
        empty_pages = 0
        
        while True:
            page_num += 1
            url = (f"https://store.playstation.com/zh-hant-hk/pages/browse/1"
                   f"?category={category}&sort=discount_rate&page={page_num}")
            
            context = await browser.new_context(
                viewport={"width": 1920, "height": 1080},
                locale="zh-Hant-HK",
                user_agent=("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                           "AppleWebKit/537.36 (KHTML, like Gecko) "
                           "Chrome/125.0.0.0 Safari/537.36"),
            )
            page = await context.new_page()
            
            try:
                print(f"  [{platform}] 加载第 {page_num} 页 ...")
                await page.goto(url, wait_until="networkidle", timeout=30000)
                await page.wait_for_timeout(2000)  # 等 JS 渲染完成
                
                # 等待产品 tile 出现
                try:
                    await page.wait_for_selector('[data-qa*="product-name"]', timeout=10000)
                except:
                    print(f"    ⚠️ 未找到产品，可能已到最后一页")
                    await context.close()
                    break
                
                # 提取所有游戏数据
                games = await page.evaluate("""
                    () => {
                        const tiles = document.querySelectorAll('[class*="product-tile"]');
                        return Array.from(tiles).map(tile => {
                            const nameEl = tile.querySelector('[data-qa*="product-name"]');
                            const discEl = tile.querySelector('[data-qa*="discount-badge"]');
                            const priceEl = tile.querySelector('[data-qa*="display-price"]');
                            const origEl = tile.querySelector('[data-qa*="strikethrough"]');
                            const typeEl = tile.querySelector('[data-qa*="product-type"]');
                            const imgEl = tile.querySelector('img');
                            
                            return {
                                name: nameEl ? nameEl.innerText.trim() : '',
                                discount: discEl ? discEl.innerText.trim() : '',
                                price: priceEl ? priceEl.innerText.trim() : '',
                                original_price: origEl ? origEl.innerText.trim() : '',
                                type: typeEl ? typeEl.innerText.trim() : '',
                                img: imgEl ? (imgEl.getAttribute('src') || imgEl.getAttribute('data-src') || '') : '',
                            };
                        });
                    }
                """)
                
                print(f"    抓到 {len(games)} 条")
                
                if not games:
                    empty_pages += 1
                    if empty_pages >= 2:
                        break
                    await context.close()
                    continue
                
                empty_pages = 0
                new_count = 0
                for g in games:
                    # 跳过非游戏类型（DLC、Theme等）
                    if g['type'] in ['物品', '武器', '服裝', '追加內容', '章節', '季票', 'gameBundle']:
                        continue
                    if not g['name']:
                        continue
                    
                    # 去重：用 name + platform 做 key
                    gid = f"{g['name']}|{platform}"
                    if gid not in seen_ids:
                        seen_ids.add(gid)
                        # 精简图片
                        if g['img']:
                            g['img'] = g['img'].split('?')[0] + '?w=240'
                        g['platform'] = platform
                        all_games.append(g)
                        new_count += 1
                
                print(f"    新增 {new_count} 条（累计 {len(all_games)} 条）")
                
                # 检查是否有"下一页"按钮
                has_next = await page.evaluate("""
                    () => {
                        const nextBtn = document.querySelector('[class*="next"],[aria-label*="下一頁"],[data-qa*="next"]');
                        if (nextBtn) return !nextBtn.disabled && !nextBtn.classList.contains('disabled');
                        return false;
                    }
                """)
                
                if not has_next and len(games) < 5:
                    print(f"    ✅ 已到最后一页")
                    await context.close()
                    break
                
            except Exception as e:
                print(f"    ❌ 错误: {e}")
                empty_pages += 1
                if empty_pages >= 3:
                    break
            
            await context.close()
            time.sleep(1)  # 礼貌间隔
    
    return all_games


async def main():
    print("=" * 50)
    print("PSN 折扣全量抓取")
    print("=" * 50)
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True,
            args=[
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
                "--disable-dev-shm-usage",
            ]
        )
        
        games = await fetch_psn_deals(browser)
        await browser.close()
    
    print(f"\n📊 总计: {len(games)} 款打折游戏")
    
    # 统计平台分布
    ps5 = [g for g in games if g['platform'] == 'PS5']
    ps4 = [g for g in games if g['platform'] == 'PS4']
    print(f"  PS5: {len(ps5)}")
    print(f"  PS4: {len(ps4)}")
    
    # 保存到文件
    output = "psn_deals.json"
    with open(output, "w", encoding="utf-8") as f:
        json.dump(games, f, ensure_ascii=False, indent=2)
    print(f"\n💾 已保存到 {output}")
    
    return games


if __name__ == "__main__":
    t0 = time.time()
    games = asyncio.run(main())
    t = time.time() - t0
    print(f"\n⏱️  耗时: {t/60:.1f} 分钟")
    print(f"  平均: {t/len(games):.1f} 秒/条" if games else "")
